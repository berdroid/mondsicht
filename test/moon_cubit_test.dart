import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondsicht/application/location/location_cubit.dart';
import 'package:mondsicht/application/location/location_state.dart';
import 'package:mondsicht/application/moon/moon_cubit.dart';
import 'package:mondsicht/application/moon/moon_state.dart';
import 'package:mondsicht/data/location_repository.dart';
import 'package:mondsicht/domain/entities/location_data.dart';

/// A LocationCubit subclass that never touches the device's GPS.
/// Tests drive states via [push].
class _FakeLocationCubit extends LocationCubit {
  _FakeLocationCubit() : super(LocationRepository());

  /// Override start so no network / permission call is made.
  @override
  Future<void> start() async {}

  /// Push a state as if the real cubit had emitted it.
  void push(LocationState s) => emit(s);
}

void main() {
  group('MoonCubit', () {
    late _FakeLocationCubit locationCubit;

    setUp(() {
      locationCubit = _FakeLocationCubit();
    });

    tearDown(() async {
      await locationCubit.close();
    });

    test('starts in MoonInitial', () {
      final cubit = MoonCubit(locationCubit);
      expect(cubit.state, isA<MoonInitial>());
      cubit.close();
    });

    blocTest<MoonCubit, MoonState>(
      'emits MoonDataAvailable when a location becomes available',
      build: () => MoonCubit(locationCubit),
      act: (_) => locationCubit.push(
        LocationAvailable(
          const LocationData(latitude: 52.52, longitude: 13.41),
        ),
      ),
      expect: () => [isA<MoonDataAvailable>()],
    );

    blocTest<MoonCubit, MoonState>(
      'MoonData fields are within valid ranges',
      build: () => MoonCubit(locationCubit),
      act: (_) => locationCubit.push(
        LocationAvailable(
          const LocationData(latitude: 48.85, longitude: 2.35),
        ),
      ),
      verify: (cubit) {
        final data = (cubit.state as MoonDataAvailable).data;
        expect(data.illumination, inInclusiveRange(0.0, 1.0));
        expect(data.phase, inInclusiveRange(0.0, 1.0));
        expect(data.azimuth, inInclusiveRange(0.0, 360.0));
        // Next events should be in the future (or at most 1 day ago due to day rounding).
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(data.nextNewMoon.isAfter(yesterday), isTrue);
        expect(data.nextFullMoon.isAfter(yesterday), isTrue);
      },
    );

    blocTest<MoonCubit, MoonState>(
      'does not emit when location stays at initial state',
      build: () => MoonCubit(locationCubit),
      // No act — nothing triggers a recalculation.
      expect: () => <MoonState>[],
    );

  });
}
