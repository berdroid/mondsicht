import 'package:mondsicht/domain/entities/location_data.dart';

sealed class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationAvailable extends LocationState {
  final LocationData location;
  LocationAvailable(this.location);
}

class LocationPermissionDenied extends LocationState {}
