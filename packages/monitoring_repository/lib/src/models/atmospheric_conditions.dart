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
    double toDoubleSafe(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final normalized = value.trim().replaceAll(',', '.');
        final match = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(normalized);
        if (match != null) {
          return double.tryParse(match.group(0)!) ?? 0.0;
        }
        return double.tryParse(normalized) ?? 0.0;
      }
      return 0.0;
    }

    DateTime parseTimestamp(dynamic rawTimestamp) {
      if (rawTimestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
      }
      if (rawTimestamp is double) {
        return DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt());
      }
      if (rawTimestamp is String) {
        final trimmed = rawTimestamp.trim();
        final unixValue = int.tryParse(trimmed);
        if (unixValue != null) {
          if (unixValue < 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(unixValue * 1000);
          }
          return DateTime.fromMillisecondsSinceEpoch(unixValue);
        }
        final parsed = DateTime.tryParse(trimmed);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    final temperature = toDoubleSafe(
      json['temperature'] ?? json['temp'] ?? json['t'] ?? 0,
    );
    final humidity = toDoubleSafe(json['humidity'] ?? json['hum'] ?? 0);
    final pressure = toDoubleSafe(
      json['pressure'] ?? json['press'] ?? json['tekanan'] ?? 0,
    );
    final altitude = toDoubleSafe(
      json['altitude'] ?? json['alt'] ?? json['height'] ?? 0,
    );

    DateTime timestamp = DateTime.now();
    final rawTimestamp =
        json['timestamp'] ?? json['time'] ?? json['waktu'] ?? json['datetime'];
    if (rawTimestamp != null) {
      timestamp = parseTimestamp(rawTimestamp);
    }

    return AtmosphericConditions(
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      altitude: altitude,
      timestamp: timestamp,
    );
  }
}
