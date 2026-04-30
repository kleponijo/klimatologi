import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(const NotificationState()) {
    on<SensorAlertAdded>(_onAlertAdded);
    on<NotificationsMarkedAsRead>(_onMarkedAsRead);
    on<NotificationDismissed>(_onDismissed);
  }

  void _onAlertAdded(
    SensorAlertAdded event,
    Emitter<NotificationState> emit,
  ) {
    final updated = Map<String, SensorAlert>.from(state._alertsBySensor);

    if (event.alert.severity == AlertSeverity.info) {
      // Sensor kembali normal → hapus alert-nya
      updated.remove(event.alert.sensorId);
    } else {
      // Ada peringatan → tambah atau update entry
      updated[event.alert.sensorId] = event.alert;
    }

    emit(state.copyWith(alertsBySensor: updated));
  }

  void _onMarkedAsRead(
    NotificationsMarkedAsRead event,
    Emitter<NotificationState> emit,
  ) {
    final updated = state._alertsBySensor.map(
      (key, alert) => MapEntry(key, alert.copyWith(isRead: true)),
    );
    emit(state.copyWith(alertsBySensor: updated));
  }

  void _onDismissed(
    NotificationDismissed event,
    Emitter<NotificationState> emit,
  ) {
    final updated = Map<String, SensorAlert>.from(state._alertsBySensor)
      ..remove(event.sensorId);
    emit(state.copyWith(alertsBySensor: updated));
  }
}
