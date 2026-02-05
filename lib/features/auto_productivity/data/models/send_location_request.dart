class SendLocationRequest {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  SendLocationRequest({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };
}
