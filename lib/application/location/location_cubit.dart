import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mondsicht/data/location_repository.dart';
import 'package:mondsicht/domain/entities/location_data.dart';

import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationRepository _repo;
  Timer? _timer;

  LocationCubit(this._repo) : super(LocationInitial());

  Future<void> start() async {
    emit(LocationLoading());

    var permission = await _repo.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _repo.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      emit(LocationPermissionDenied());
      return;
    }

    await _fetchPosition();
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchPosition(),
    );
  }

  Future<void> _fetchPosition() async {
    try {
      final position = await _repo.getCurrentPosition();
      emit(LocationAvailable(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
      )));
    } catch (_) {
      // Keep existing state if fetch fails.
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
