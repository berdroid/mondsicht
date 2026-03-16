class SunData {
  /// Compass bearing in degrees (0 = north, 90 = east, 180 = south, 270 = west).
  final double azimuth;

  /// Altitude above the horizon in degrees.
  final double elevation;

  /// Local time of solar transit (solar noon).
  final DateTime culminationTime;

  /// Compass bearing at solar transit (≈ 180° south or 0° north).
  final double culminationAzimuth;

  /// Altitude at solar transit in degrees.
  final double culminationElevation;

  /// Duration sun is above the horizon today.
  final Duration dayLength;

  /// Next sunrise (null if sun never rises).
  final DateTime? sunrise;

  /// Next sunset (null if sun never sets).
  final DateTime? sunset;

  const SunData({
    required this.azimuth,
    required this.elevation,
    required this.culminationTime,
    required this.culminationAzimuth,
    required this.culminationElevation,
    required this.dayLength,
    required this.sunrise,
    required this.sunset,
  });
}
