part of 'notification_bloc.dart';

/// Tingkat keparahan alert
enum AlertSeverity { info, warning, danger }

/// Model satu alert dari satu sensor
final class SensorAlert extends Equatable {
  final String sensorId; // unik per alat, misal 'wind_speed'
  final String sensorName; // nama tampilan, misal 'Anemometer'
  final String message; // pesan singkat
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isRead;

  const SensorAlert({
    required this.sensorId,
    required this.sensorName,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
  });

  SensorAlert copyWith({
    String? sensorId,
    String? sensorName,
    String? message,
    AlertSeverity? severity,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return SensorAlert(
      sensorId: sensorId ?? this.sensorId,
      sensorName: sensorName ?? this.sensorName,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object> get props => [sensorId, message, severity, timestamp, isRead];
}

/// State utama NotificationBloc
final class NotificationState extends Equatable {
  /// Hanya menyimpan SATU alert per sensor (key = sensorId).
  /// Kalau sensor normal, entry-nya dihapus dari map.
  final Map<String, SensorAlert> _alertsBySensor;

  const NotificationState({
    Map<String, SensorAlert> alertsBySensor = const {},
  }) : _alertsBySensor = alertsBySensor;

  /// Semua alert aktif, diurutkan: danger dulu, lalu warning, lalu info
  List<SensorAlert> get activeAlerts {
    final list = _alertsBySensor.values.toList();
    list.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return list;
  }

  int get unreadCount => _alertsBySensor.values.where((a) => !a.isRead).length;

  bool get hasActiveAlerts => _alertsBySensor.isNotEmpty;

  NotificationState copyWith({
    Map<String, SensorAlert>? alertsBySensor,
  }) {
    return NotificationState(
      alertsBySensor: alertsBySensor ?? _alertsBySensor,
    );
  }

  @override
  List<Object> get props => [_alertsBySensor];
}
