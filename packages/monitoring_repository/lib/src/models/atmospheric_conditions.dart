class AtmosphericConditions {
  final double temperature;
  final double humidity;
  final double pressure;
  final double altitude;
  final int timeMs;
  final DateTime timestamp;

  AtmosphericConditions({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.altitude,
    required this.timeMs,
    required this.timestamp,
  });

  factory AtmosphericConditions.fromJson(Map<dynamic, dynamic> json) {
    final now = DateTime.now();
    final int? rawTimeMs = _toInt(json['time_ms']);
    final int? rawUnixMs = _toInt(json['time_unix_ms']);

    final DateTime parsedTime = _parseTimestamp(
      unixMs: rawUnixMs,
      uptimeMs: rawTimeMs,
      fallback: now,
    );

    return AtmosphericConditions(
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      pressure: _toDouble(json['pressure']),
      altitude: _toDouble(json['altitude']),
      timeMs: rawTimeMs ?? 0,
      timestamp: parsedTime,
    );
  }

  static DateTime _parseTimestamp({
    required int? unixMs,
    required int? uptimeMs,
    required DateTime fallback,
  }) {
    // Preferred source: explicit unix time from firmware
    if (unixMs != null && unixMs > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(unixMs).toLocal();
    }

    // Backward compatibility: older payload may put unix-like value in time_ms
    if (uptimeMs != null && uptimeMs > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(uptimeMs).toLocal();
    }

    // Uptime does not map to absolute date, so use now for UI grouping by day
    return fallback;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
