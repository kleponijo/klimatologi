part of 'monitoring_bloc.dart';

class MonitoringState extends Equatable {
  final MonitoringStatus status;
  final double? currentSpeed;
  final DateTime? lastUpdateTime;

  const MonitoringState._({
    this.status = MonitoringStatus.initial,
    this.currentSpeed,
    this.lastUpdateTime,
  });

  const MonitoringState.initial() : this._();

  const MonitoringState.loading() : this._(status: MonitoringStatus.loading);

  const MonitoringState.loaded({
    required double currentSpeed,
    required DateTime lastUpdateTime,
  }) : this._(
          status: MonitoringStatus.loaded,
          currentSpeed: currentSpeed,
          lastUpdateTime: lastUpdateTime,
        );

  const MonitoringState.error(String message)
      : this._(status: MonitoringStatus.error);

  @override
  List<Object?> get props => [status, currentSpeed, lastUpdateTime];
}

enum MonitoringStatus { initial, loading, loaded, error }
