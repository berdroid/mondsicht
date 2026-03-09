import 'dart:async';
import 'dart:math';

import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:flutter/material.dart';
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
    // Handle current state immediately if already available.
    _onLocationState(_locationCubit.state);
  }

  void _onLocationState(LocationState state) {
    if (state is LocationAvailable) {
      _calculate(state.location.latitude, state.location.longitude);
    }
  }

  void _calculate(double lat, double lng) {
    final now = DateTime.now();

    final moonPos = SunCalc.getMoonPosition(now, lat, lng);
    final moonIllum = SunCalc.getMoonIllumination(now);
    // inUtc: false → search window is the local civil day (00:00–24:00 local)
    // and the returned DateTimes are already in local time.
    final moonTimes = SunCalc.getMoonTimes(now, lat, lng, false);

    // Convert azimuth from suncalc convention (0=south, west positive)
    // to compass bearing (0=north, clockwise).
    final azimuthRad = (moonPos['azimuth'] as num).toDouble();
    final azimuthDeg = (azimuthRad * 180 / pi + 180) % 360;

    final elevation = (moonPos['altitude'] as num).toDouble() * 180 / pi;
    final illumination = (moonIllum['fraction'] as num).toDouble();
    final phase = (moonIllum['phase'] as num).toDouble();
    final parallacticAngle = (moonPos['parallacticAngle'] as num).toDouble();

    // Results are already local DateTimes (inUtc: false).
    DateTime? moonRise = moonTimes['rise'] as DateTime?;
    DateTime? moonSet = moonTimes['set'] as DateTime?;

    // If rise or set already passed today, fetch tomorrow's times.
    if ((moonRise != null && moonRise.isBefore(now)) || (moonSet != null && moonSet.isBefore(now))) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = SunCalc.getMoonTimes(tomorrow, lat, lng, false);
      if (moonRise != null && moonRise.isBefore(now)) {
        moonRise = tomorrowTimes['rise'] as DateTime?;
      }
      if (moonSet != null && moonSet.isBefore(now)) {
        moonSet = tomorrowTimes['set'] as DateTime?;
      }
    }

    emit(
      MoonDataAvailable(
        MoonData(
          azimuth: azimuthDeg,
          elevation: elevation,
          illumination: illumination,
          phase: phase,
          parallacticAngle: parallacticAngle,
          moonRise: moonRise, // already local
          moonSet: moonSet, // already local
          nextNewMoon: _nextNewMoon(now, phase),
          nextFullMoon: _nextFullMoon(now, phase),
        ),
      ),
    );
  }

  // Mean synodic period of the Moon in days.
  static const double _synodicPeriod = 29.53059;

  /// Next new moon: phase must travel from [phase] to 1.0.
  DateTime _nextNewMoon(DateTime now, double phase) {
    final days = (1.0 - phase) * _synodicPeriod;
    return now.add(Duration(microseconds: (days * Duration.microsecondsPerDay).round()));
  }

  /// Next full moon: phase must travel from [phase] to 0.5 (mod 1).
  DateTime _nextFullMoon(DateTime now, double phase) {
    final days = ((0.5 - phase) % 1.0) * _synodicPeriod;
    return now.add(Duration(microseconds: (days * Duration.microsecondsPerDay).round()));
  }

  @override
  Future<void> close() {
    _locationSub.cancel();
    return super.close();
  }
}
