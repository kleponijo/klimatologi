part of 'monitoring_bloc.dart';

sealed class MonitoringEvent extends Equatable {
  const MonitoringEvent();

  @override
  List<Object> get props => [];
}

class LoadMonitoringData extends MonitoringEvent {
  const LoadMonitoringData();
}

class MonitoringDataUpdated extends MonitoringEvent {
  final double speed;
  final DateTime timestamp;

  const MonitoringDataUpdated({
    required this.speed,
    required this.timestamp,
  });

  @override
  List<Object> get props => [speed, timestamp];
}
