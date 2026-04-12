import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';

part 'monitoring_event.dart';
part 'monitoring_state.dart';

class MonitoringBloc extends Bloc<MonitoringEvent, MonitoringState> {
  final DatabaseReference _realtimeRef =
      FirebaseDatabase.instance.ref('anemometer/realtime');
  StreamSubscription<DatabaseEvent>? _realtimeSub;

  MonitoringBloc() : super(const MonitoringState.initial()) {
    on<LoadMonitoringData>(_onLoadMonitoringData);
    on<MonitoringDataUpdated>(_onMonitoringDataUpdated);
  }

  void _onLoadMonitoringData(
      LoadMonitoringData event, Emitter<MonitoringState> emit) {
    emit(const MonitoringState.loading());

    // Start listening to realtime data
    _realtimeSub = _realtimeRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final speed = (data['kecepatan'] ?? 0).toDouble();
        final timestamp = data['timestamp'] ?? 0;
        final waktu = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

        add(MonitoringDataUpdated(speed: speed, timestamp: waktu));
      }
    });
  }

  void _onMonitoringDataUpdated(
      MonitoringDataUpdated event, Emitter<MonitoringState> emit) {
    emit(MonitoringState.loaded(
      currentSpeed: event.speed,
      lastUpdateTime: event.timestamp,
    ));
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
