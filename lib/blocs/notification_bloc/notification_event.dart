part of 'notification_bloc.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

/// Tambah atau update alert dari sebuah sensor
final class SensorAlertAdded extends NotificationEvent {
  final SensorAlert alert;

  const SensorAlertAdded(this.alert);

  @override
  List<Object> get props => [alert];
}

/// Tandai semua notifikasi sebagai sudah dibaca
final class NotificationsMarkedAsRead extends NotificationEvent {
  const NotificationsMarkedAsRead();
}

/// Hapus alert spesifik (opsional, jika ingin dismiss satu per satu)
final class NotificationDismissed extends NotificationEvent {
  final String sensorId;

  const NotificationDismissed(this.sensorId);

  @override
  List<Object> get props => [sensorId];
}
