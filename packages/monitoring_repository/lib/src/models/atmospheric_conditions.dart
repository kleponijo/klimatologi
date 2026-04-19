class AtmosphericConditions {
  final double temperature;
  final double humidity;
  final double pressure;
  final double altitude;
  final DateTime timestamp;

  AtmosphericConditions({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.altitude,
    required this.timestamp,
  });

  factory AtmosphericConditions.fromJson(Map<dynamic, dynamic> json) {
    return AtmosphericConditions(
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      pressure: (json['pressure'] ?? 0).toDouble(),
      altitude: (json['altitude'] ?? 0).toDouble(),
      timestamp: DateTime.now(), // karena kamu pakai latest
    );
  }
}
