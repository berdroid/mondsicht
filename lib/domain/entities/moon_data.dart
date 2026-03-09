class MoonData {
  /// Compass bearing in degrees (0 = north, 90 = east, 180 = south, 270 = west).
  final double azimuth;

  /// Altitude above the horizon in degrees.
  final double elevation;

  /// Illuminated fraction 0–1 (0 = new moon, 1 = full moon).
  final double illumination;

  /// Moon phase 0–1 (0 = new moon, 0.5 = full moon, 1 = new moon).
  final double phase;

  /// Parallactic angle in radians — used to rotate the moon image.
  final double parallacticAngle;

  final DateTime? moonRise;
  final DateTime? moonSet;
  final DateTime nextNewMoon;
  final DateTime nextFullMoon;

  const MoonData({
    required this.azimuth,
    required this.elevation,
    required this.illumination,
    required this.phase,
    required this.parallacticAngle,
    required this.moonRise,
    required this.moonSet,
    required this.nextNewMoon,
    required this.nextFullMoon,
  });
}
