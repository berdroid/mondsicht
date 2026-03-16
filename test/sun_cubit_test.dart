import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondsicht/application/location/location_cubit.dart';
import 'package:mondsicht/application/location/location_state.dart';
import 'package:mondsicht/application/sun/sun_cubit.dart';
import 'package:mondsicht/application/sun/sun_state.dart';
import 'package:mondsicht/data/location_repository.dart';
import 'package:mondsicht/domain/entities/location_data.dart';

/// A LocationCubit subclass that never touches the device's GPS.
/// Tests drive states via [push].
class _FakeLocationCubit extends LocationCubit {
  _FakeLocationCubit() : super(LocationRepository());

  @override
  Future<void> start() async {}

  void push(LocationState s) => emit(s);
}

void main() {
  group('SunCubit', () {
    late _FakeLocationCubit locationCubit;

    setUp(() {
      locationCubit = _FakeLocationCubit();
    });

    tearDown(() async {
      await locationCubit.close();
    });

    test('starts in SunInitial', () {
      final cubit = SunCubit(locationCubit);
      expect(cubit.state, isA<SunInitial>());
      cubit.close();
    });

    blocTest<SunCubit, SunState>(
      'emits SunDataAvailable when a location becomes available',
      build: () => SunCubit(locationCubit),
      act: (_) => locationCubit.push(
        LocationAvailable(
          const LocationData(latitude: 52.52, longitude: 13.41),
        ),
      ),
      expect: () => [isA<SunDataAvailable>()],
    );

    blocTest<SunCubit, SunState>(
      'SunData fields are within valid ranges',
      build: () => SunCubit(locationCubit),
      act: (_) => locationCubit.push(
        LocationAvailable(
          const LocationData(latitude: 48.85, longitude: 2.35),
        ),
      ),
      verify: (cubit) {
        final data = (cubit.state as SunDataAvailable).data;
        expect(data.azimuth, inInclusiveRange(0.0, 360.0));
        expect(data.elevation, inInclusiveRange(-90.0, 90.0));
        expect(data.culminationAzimuth, inInclusiveRange(0.0, 360.0));
        expect(data.culminationElevation, inInclusiveRange(-90.0, 90.0));
        expect(data.dayLength.inSeconds, greaterThanOrEqualTo(0));
      },
    );

    blocTest<SunCubit, SunState>(
      'does not emit when location stays at initial state',
      build: () => SunCubit(locationCubit),
      // No act — nothing triggers a recalculation.
      expect: () => <SunState>[],
    );
  });
}
