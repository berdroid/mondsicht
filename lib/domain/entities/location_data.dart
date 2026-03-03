class LocationData {
  final double latitude;
  final double longitude;

  /// Horizontal accuracy radius in metres (0 = unknown).
  final double accuracy;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
  });
}
