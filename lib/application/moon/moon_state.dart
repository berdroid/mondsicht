import 'package:mondsicht/domain/entities/moon_data.dart';

sealed class MoonState {}

class MoonInitial extends MoonState {}

class MoonDataAvailable extends MoonState {
  final MoonData data;
  MoonDataAvailable(this.data);
}
