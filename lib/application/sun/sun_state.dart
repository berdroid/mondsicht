import 'package:mondsicht/domain/entities/sun_data.dart';

sealed class SunState {}

class SunInitial extends SunState {}

class SunDataAvailable extends SunState {
  final SunData data;
  SunDataAvailable(this.data);
}
