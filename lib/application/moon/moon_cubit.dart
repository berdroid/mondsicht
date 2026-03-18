import 'dart:async';
import 'dart:math';

import 'package:astronomia/astronomia.dart';
import 'package:astronomia/moonillum.dart' as moonillum;
import 'package:astronomia/moonphase.dart' as moonphase;
import 'package:astronomia/moonposition.dart' as moonpos;
import 'package:astronomia/rise.dart' as rise;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mondsicht/application/location/location_cubit.dart';
import 'package:mondsicht/application/location/location_state.dart';
import 'package:mondsicht/domain/entities/moon_data.dart';

import 'moon_state.dart';

class MoonCubit extends Cubit<MoonState> {
  final LocationCubit _locationCubit;
  late final StreamSubscription<LocationState> _locationSub;

  MoonCubit(this._locationCubit) : super(MoonInitial()) {
    _locationSub = _locationCubit.stream.listen(_onLocationState);
    _onLocationState(_locationCubit.state);
  }

  void _onLocationState(LocationState state) {
    if (state is LocationAvailable) {
      _calculate(state.location.latitude, state.location.longitude);
    }
  }

  // ΔT ≈ 69 s for 2026 (TT − UT1).
  static const double _deltaT = 69.0;

  void _calculate(double lat, double lng) {
    final now = DateTime.now();
    final nowUtc = now.toUtc();
    final jde = _toJD(now);

    // Obliquity (computed once; negligible change over the 3-day rise window).
    final eps = _meanObliquity(jde);
    final sEps = sin(eps);
    final cEps = cos(eps);

    // --- Moon ecliptic position (Meeus Ch. 47) ---
    final pos = moonpos.position(jde);

    // --- Ecliptic → equatorial ---
    final eq = eclToEq(pos.lon, pos.lat, sEps, cEps);

    // --- Greenwich apparent sidereal time ---
    // apparent0UT gives seconds at 0h UT; advance to the current UT instant.
    final jdMidnight = calendarGregorianToJD(
        nowUtc.year, nowUtc.month, nowUtc.day.toDouble());
    final th0Secs = apparent0UT(jdMidnight);
    final utSecs = (jde - jdMidnight) * 86400.0;
    // Sidereal rate = 360.985647°/360° per solar second.
    final gstRad = (th0Secs + utSecs * 360.985647 / 360.0) * 2 * pi / 86400.0;

    // Observer coords: lat N positive; lon positive WEST (Meeus/astronomia convention).
    final phi = toRad(lat);
    final psiWest = toRad(-lng); // flip sign: east → west-positive

    // --- Horizontal coordinates ---
    final hz = eqToHz(eq.ra, eq.dec, phi, psiWest, gstRad);
    // az: westward from south → compass bearing (0 = N, clockwise).
    final azimuthDeg = (toDeg(hz.az) + 180.0) % 360.0;
    final elevationDeg = toDeg(hz.alt);

    // --- Parallactic angle (used to orient the moon image) ---
    // H = GST + lon_east − RA  (local hour angle)
    final lha = gstRad + toRad(lng) - eq.ra;
    final parallacticAngle = atan2(
      sin(lha),
      tan(phi) * cos(eq.dec) - sin(eq.dec) * cos(lha),
    );

    // --- Illumination (Meeus Ch. 48) ---
    final phaseAngle = moonillum.phaseAngle3(jde);
    final illumination = moonillum.illuminated(phaseAngle);

    // --- Phase 0–1 cycle (0 = new moon, 0.5 = full moon) ---
    // Derived from the true elongation (Moon lon − Sun lon).
    final phase = mod2pi(pos.lon - _sunEclipticLon(jde)) / (2 * pi);

    // --- 3-day RA/Dec for rise/set interpolation (day−1, day0, day+1) ---
    ({double ra, double dec}) moonEqAt(double jd2) {
      final p = moonpos.position(jd2);
      final e = eclToEq(p.lon, p.lat, sEps, cEps);
      return (ra: e.ra, dec: e.dec);
    }
    final eqM1 = moonEqAt(jdMidnight - 1);
    final eq0  = moonEqAt(jdMidnight);
    final eqP1 = moonEqAt(jdMidnight + 1);

    // Normalize RA to remove 0/2π wrap-around: moon always moves east so RA
    // must be monotonically increasing across the three-day window.
    double ra0 = eqM1.ra, ra1 = eq0.ra, ra2 = eqP1.ra;
    if (ra1 < ra0) ra1 += 2 * pi;
    if (ra2 < ra1) ra2 += 2 * pi;

    // Standard altitude for the moon: h0 = 0.7275·π − 34' (Meeus Ch. 15).
    final h0Moon = 0.7275 * moonpos.parallax(pos.delta) - toRad(34.0 / 60.0);

    // --- Moon rise / transit / set (Meeus Ch. 15, same algorithm as sun) ---
    DateTime? moonRise, moonSet;
    DateTime culminationTime = now;
    double culminationAzimuth = 180.0;
    double culminationElevation = 0.0;
    final riseSet = rise.times(
      phi, psiWest, _deltaT, h0Moon, th0Secs,
      [ra0, ra1, ra2],
      [eqM1.dec, eq0.dec, eqP1.dec],
    );
    if (riseSet != null) {
      moonRise = _utcSecsToLocal(jdMidnight, riseSet.rise);
      moonSet  = _utcSecsToLocal(jdMidnight, riseSet.set);
      culminationTime = _utcSecsToLocal(jdMidnight, riseSet.transit);

      // --- Culmination position ---
      // At upper transit H=0: alt = arcsin(sin(φ)sin(δ) + cos(φ)cos(δ)).
      final jdTransit = jdMidnight + riseSet.transit / 86400.0;
      final pTransit = moonpos.position(jdTransit);
      final eqTransit = eclToEq(pTransit.lon, pTransit.lat, sEps, cEps);
      culminationElevation = toDeg(asin(
          sin(phi) * sin(eqTransit.dec) + cos(phi) * cos(eqTransit.dec)));
      culminationAzimuth = eqTransit.dec < phi ? 180.0 : 0.0;

      // Replace any already-past event with tomorrow's equivalent.
      if (moonRise.isBefore(now) || moonSet.isBefore(now) || culminationTime.isBefore(now)) {
        final jdTomorrow = jdMidnight + 1;
        final th0Tomorrow = apparent0UT(jdTomorrow);
        final eqTM1 = moonEqAt(jdTomorrow - 1);
        final eqT0  = moonEqAt(jdTomorrow);
        final eqTP1 = moonEqAt(jdTomorrow + 1);
        double tra0 = eqTM1.ra, tra1 = eqT0.ra, tra2 = eqTP1.ra;
        if (tra1 < tra0) tra1 += 2 * pi;
        if (tra2 < tra1) tra2 += 2 * pi;
        final tomorrow = rise.times(
          phi, psiWest, _deltaT, h0Moon, th0Tomorrow,
          [tra0, tra1, tra2],
          [eqTM1.dec, eqT0.dec, eqTP1.dec],
        );
        if (tomorrow != null) {
          if (moonRise.isBefore(now)) {
            moonRise = _utcSecsToLocal(jdTomorrow, tomorrow.rise);
          }
          if (moonSet.isBefore(now)) {
            moonSet = _utcSecsToLocal(jdTomorrow, tomorrow.set);
          }
          if (culminationTime.isBefore(now)) {
            culminationTime = _utcSecsToLocal(jdTomorrow, tomorrow.transit);
            final jdTransitT = jdTomorrow + tomorrow.transit / 86400.0;
            final pTransitT = moonpos.position(jdTransitT);
            final eqTransitT = eclToEq(pTransitT.lon, pTransitT.lat, sEps, cEps);
            culminationElevation = toDeg(asin(
                sin(phi) * sin(eqTransitT.dec) + cos(phi) * cos(eqTransitT.dec)));
            culminationAzimuth = eqTransitT.dec < phi ? 180.0 : 0.0;
          }
        }
      }
    }

    // --- Next new / full moon (Meeus Ch. 49) ---
    final decYear = jdeToJulianYear(jde);
    DateTime nextNewMoon = _fromJD(moonphase.newMoon(decYear));
    if (!nextNewMoon.isAfter(now)) {
      nextNewMoon = _fromJD(moonphase.newMoon(decYear + 29.53 / 365.25));
    }
    DateTime nextFullMoon = _fromJD(moonphase.full(decYear));
    if (!nextFullMoon.isAfter(now)) {
      nextFullMoon = _fromJD(moonphase.full(decYear + 29.53 / 365.25));
    }

    emit(MoonDataAvailable(MoonData(
      azimuth: azimuthDeg,
      elevation: elevationDeg,
      illumination: illumination,
      phase: phase,
      parallacticAngle: parallacticAngle,
      culminationTime: culminationTime,
      culminationAzimuth: culminationAzimuth,
      culminationElevation: culminationElevation,
      moonRise: moonRise,
      moonSet: moonSet,
      nextNewMoon: nextNewMoon,
      nextFullMoon: nextFullMoon,
    )));
  }

  // --- Helpers ---

  /// Converts a [DateTime] to a Julian Ephemeris Day number.
  double _toJD(DateTime dt) {
    final u = dt.toUtc();
    final d = u.day + (u.hour + u.minute / 60.0 + u.second / 3600.0) / 24.0;
    return calendarGregorianToJD(u.year, u.month, d);
  }

  /// Converts a Julian Day number to a local [DateTime].
  DateTime _fromJD(double jd) {
    final cal = jdToCalendar(jd);
    final dayInt = cal.day.floor();
    final secs = ((cal.day - dayInt) * 86400).round();
    return DateTime.utc(
      cal.year, cal.month, dayInt,
      secs ~/ 3600, (secs % 3600) ~/ 60, secs % 60,
    ).toLocal();
  }

  /// Converts a JD midnight + seconds-of-day (UT) to a local [DateTime].
  DateTime _utcSecsToLocal(double jdMidnight, double secs) =>
      _fromJD(jdMidnight + secs / 86400.0);

  /// Mean obliquity of the ecliptic in radians (IAU, Meeus eq. 22.2).
  double _meanObliquity(double jde) {
    final t = (jde - 2451545.0) / 36525.0;
    return toRad(23.439291111 -
        0.013004167 * t -
        0.0000001639 * t * t +
        0.0000005036 * t * t * t);
  }

  /// Sun's apparent ecliptic longitude in radians.
  /// Low-precision Meeus Ch. 25 (≈ 0.01°), sufficient for phase computation.
  double _sunEclipticLon(double jde) {
    final t = (jde - 2451545.0) / 36525.0;
    final l0 = toRad(280.46646 + 36000.76983 * t + 0.0003032 * t * t);
    final m = toRad(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
    final c = toRad(
      (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(m) +
          (0.019993 - 0.000101 * t) * sin(2 * m) +
          0.000289 * sin(3 * m),
    );
    return mod2pi(l0 + c);
  }

  @override
  Future<void> close() {
    _locationSub.cancel();
    return super.close();
  }
}
