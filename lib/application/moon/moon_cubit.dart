import 'dart:async';
import 'dart:math';

import 'package:apsl_sun_calc/apsl_sun_calc.dart';
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
    final moonTimes = SunCalc.getMoonTimes(now, lat, lng);

    // Convert azimuth from suncalc convention (0=south, west positive)
    // to compass bearing (0=north, clockwise).
    final azimuthRad = (moonPos['azimuth'] as num).toDouble();
    final azimuthDeg = (azimuthRad * 180 / pi + 180) % 360;

    final elevation = (moonPos['altitude'] as num).toDouble() * 180 / pi;
    final illumination = (moonIllum['fraction'] as num).toDouble();
    final phase = (moonIllum['phase'] as num).toDouble();
    final parallacticAngle = (moonPos['parallacticAngle'] as num).toDouble();

    final DateTime? moonRise = moonTimes['rise'] as DateTime?;
    final DateTime? moonSet = moonTimes['set'] as DateTime?;

    emit(MoonDataAvailable(MoonData(
      azimuth: azimuthDeg,
      elevation: elevation,
      illumination: illumination,
      phase: phase,
      parallacticAngle: parallacticAngle,
      phaseName: _phaseName(phase),
      moonRise: moonRise?.toLocal(),
      moonSet: moonSet?.toLocal(),
      nextNewMoon: _findNextLunarEvent(now, findNewMoon: true),
      nextFullMoon: _findNextLunarEvent(now, findNewMoon: false),
    )));
  }

  String _phaseName(double phase) {
    if (phase < 0.0625 || phase >= 0.9375) return 'New Moon';
    if (phase < 0.1875) return 'Waxing Crescent';
    if (phase < 0.3125) return 'First Quarter';
    if (phase < 0.4375) return 'Waxing Gibbous';
    if (phase < 0.5625) return 'Full Moon';
    if (phase < 0.6875) return 'Waning Gibbous';
    if (phase < 0.8125) return 'Last Quarter';
    return 'Waning Crescent';
  }

  /// Iterates day-by-day to find the next new moon (fraction minimum)
  /// or full moon (fraction maximum).
  DateTime _findNextLunarEvent(DateTime from, {required bool findNewMoon}) {
    double? bestFraction;
    DateTime? bestDate;

    for (int i = 1; i <= 35; i++) {
      final date = from.add(Duration(days: i));
      final frac =
          (SunCalc.getMoonIllumination(date)['fraction'] as num).toDouble();

      if (findNewMoon) {
        if (bestFraction == null || frac < bestFraction) {
          bestFraction = frac;
          bestDate = date;
        } else if (bestFraction < 0.1 && frac > bestFraction + 0.05) {
          break;
        }
      } else {
        if (bestFraction == null || frac > bestFraction) {
          bestFraction = frac;
          bestDate = date;
        } else if (bestFraction > 0.9 && frac < bestFraction - 0.05) {
          break;
        }
      }
    }

    return bestDate ?? from.add(const Duration(days: 15));
  }

  @override
  Future<void> close() {
    _locationSub.cancel();
    return super.close();
  }
}
