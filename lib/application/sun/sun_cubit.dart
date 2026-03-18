import 'dart:async';
import 'dart:math';

import 'package:astronomia/astronomia.dart';
import 'package:astronomia/rise.dart' as rise;
import 'package:astronomia/solar.dart' as solar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mondsicht/application/location/location_cubit.dart';
import 'package:mondsicht/application/location/location_state.dart';
import 'package:mondsicht/domain/entities/sun_data.dart';

import 'sun_state.dart';

class SunCubit extends Cubit<SunState> {
  final LocationCubit _locationCubit;
  late final StreamSubscription<LocationState> _locationSub;

  SunCubit(this._locationCubit) : super(SunInitial()) {
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

    // Observer coords: lat N positive; lon positive WEST (Meeus/astronomia convention).
    final phi = toRad(lat);
    final psiWest = toRad(-lng); // flip sign: east → west-positive

    // --- Greenwich apparent sidereal time at midnight ---
    final jdMidnight = calendarGregorianToJD(nowUtc.year, nowUtc.month, nowUtc.day.toDouble());
    final th0Secs = apparent0UT(jdMidnight);
    final utSecs = (jde - jdMidnight) * 86400.0;

    // --- Current sun position ---
    final eqNow = solar.apparentEquatorial(jde);
    // Sidereal rate = 360.985647°/360° per solar second.
    final gstRad = (th0Secs + utSecs * 360.985647 / 360.0) * 2 * pi / 86400.0;
    final hzNow = eqToHz(eqNow.ra, eqNow.dec, phi, psiWest, gstRad);
    // az: westward from south → compass bearing (0 = N, clockwise).
    final azimuthDeg = (toDeg(hzNow.az) + 180.0) % 360.0;
    final elevationDeg = toDeg(hzNow.alt);

    // --- 3-day RA/Dec for rise/set interpolation (day−1, day0, day+1) ---
    final eqM1 = solar.apparentEquatorial(jdMidnight - 1);
    final eq0 = solar.apparentEquatorial(jdMidnight);
    final eqP1 = solar.apparentEquatorial(jdMidnight + 1);

    // Normalize RA to remove 0/2π wrap-around (occurs at vernal equinox ~Mar 20).
    double ra0 = eqM1.ra, ra1 = eq0.ra, ra2 = eqP1.ra;
    if (ra1 < ra0) ra1 += 2 * pi;
    if (ra2 < ra1) ra2 += 2 * pi;

    // --- Sun rise / transit / set (Meeus Ch. 15) ---
    final riseSet = rise.times(
      phi,
      psiWest,
      _deltaT,
      rise.stdh0Solar,
      th0Secs,
      [ra0, ra1, ra2],
      [eqM1.dec, eq0.dec, eqP1.dec],
    );

    DateTime? sunrise, sunset;
    DateTime culminationTime = now;
    double culminationAzimuth = 180.0;
    double culminationElevation = 0.0;
    Duration dayLength = Duration.zero;

    if (riseSet != null) {
      final sr = _utcSecsToLocal(jdMidnight, riseSet.rise);
      final ss = _utcSecsToLocal(jdMidnight, riseSet.set);
      culminationTime = _utcSecsToLocal(jdMidnight, riseSet.transit);

      // Day length from today's raw rise/set (before roll-forward).
      dayLength = ss.difference(sr).abs();

      // --- Culmination position ---
      final jdTransit = jdMidnight + riseSet.transit / 86400.0;
      final eqTransit = solar.apparentEquatorial(jdTransit);
      final gstTransitRad = (th0Secs + riseSet.transit * 360.985647 / 360.0) * 2 * pi / 86400.0;
      final hzTransit = eqToHz(eqTransit.ra, eqTransit.dec, phi, psiWest, gstTransitRad);
      culminationAzimuth = (toDeg(hzTransit.az) + 180.0) % 360.0;
      culminationElevation = toDeg(hzTransit.alt);

      sunrise = sr;
      sunset = ss;

      // Replace any already-past event with tomorrow's equivalent.
      if (sr.isBefore(now) || ss.isBefore(now) || culminationTime.isBefore(now)) {
        final jdTomorrow = jdMidnight + 1;
        final th0Tomorrow = apparent0UT(jdTomorrow);
        final eqTM1 = solar.apparentEquatorial(jdTomorrow - 1);
        final eqT0 = solar.apparentEquatorial(jdTomorrow);
        final eqTP1 = solar.apparentEquatorial(jdTomorrow + 1);
        double tra0 = eqTM1.ra, tra1 = eqT0.ra, tra2 = eqTP1.ra;
        if (tra1 < tra0) tra1 += 2 * pi;
        if (tra2 < tra1) tra2 += 2 * pi;
        final tomorrow = rise.times(
          phi,
          psiWest,
          _deltaT,
          rise.stdh0Solar,
          th0Tomorrow,
          [tra0, tra1, tra2],
          [eqTM1.dec, eqT0.dec, eqTP1.dec],
        );
        if (tomorrow != null) {
          if (sr.isBefore(now)) {
            sunrise = _utcSecsToLocal(jdTomorrow, tomorrow.rise);
          }
          if (ss.isBefore(now)) {
            sunset = _utcSecsToLocal(jdTomorrow, tomorrow.set);
          }
          if (culminationTime.isBefore(now)) {
            culminationTime = _utcSecsToLocal(jdTomorrow, tomorrow.transit);
            final jdTransitTomorrow = jdTomorrow + tomorrow.transit / 86400.0;
            final eqTT = solar.apparentEquatorial(jdTransitTomorrow);
            final gstTT = (th0Tomorrow + tomorrow.transit * 360.985647 / 360.0) * 2 * pi / 86400.0;
            final hzTT = eqToHz(eqTT.ra, eqTT.dec, phi, psiWest, gstTT);
            culminationAzimuth = (toDeg(hzTT.az) + 180.0) % 360.0;
            culminationElevation = toDeg(hzTT.alt);
          }
        }
      }
    }

    emit(
      SunDataAvailable(
        SunData(
          azimuth: azimuthDeg,
          elevation: elevationDeg,
          culminationTime: culminationTime,
          culminationAzimuth: culminationAzimuth,
          culminationElevation: culminationElevation,
          dayLength: dayLength,
          sunrise: sunrise,
          sunset: sunset,
        ),
      ),
    );
  }

  // --- Helpers (mirrored from MoonCubit) ---

  double _toJD(DateTime dt) {
    final u = dt.toUtc();
    final d = u.day + (u.hour + u.minute / 60.0 + u.second / 3600.0) / 24.0;
    return calendarGregorianToJD(u.year, u.month, d);
  }

  DateTime _fromJD(double jd) {
    final cal = jdToCalendar(jd);
    final dayInt = cal.day.floor();
    final secs = ((cal.day - dayInt) * 86400).round();
    return DateTime.utc(cal.year, cal.month, dayInt, secs ~/ 3600, (secs % 3600) ~/ 60, secs % 60).toLocal();
  }

  DateTime _utcSecsToLocal(double jdMidnight, double secs) => _fromJD(jdMidnight + secs / 86400.0);

  @override
  Future<void> close() {
    _locationSub.cancel();
    return super.close();
  }
}
