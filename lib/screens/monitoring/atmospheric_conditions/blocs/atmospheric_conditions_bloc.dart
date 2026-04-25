import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

part 'atmospheric_conditions_event.dart';
part 'atmospheric_conditions_state.dart';

class AtmosphericConditionsBloc
    extends Bloc<AtmosphericConditionsEvent, AtmosphericConditionsState> {
  final MonitoringRepository _repository;
  StreamSubscription<AtmosphericConditions>? _subscription;

  AtmosphericConditionsBloc({required MonitoringRepository repository})
      : _repository = repository,
        super(const AtmosphericConditionsState()) {
    on<WatchAtmosphericConditionsStarted>(_onStarted);
    on<_AtmosphericConditionsUpdated>(_onUpdated);
  }

  /// 🚀 START
  Future<void> _onStarted(
    WatchAtmosphericConditionsStarted event,
    Emitter<AtmosphericConditionsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    await _subscription?.cancel();

    _subscription = _repository
        .getSensorStream(
      'sensor/latest',
      (json) => AtmosphericConditions.fromJson(json),
    )
        .listen((data) {
      add(_AtmosphericConditionsUpdated(data));
    });
  }

  /// ⚡ REALTIME UPDATE
  void _onUpdated(
    _AtmosphericConditionsUpdated event,
    Emitter<AtmosphericConditionsState> emit,
  ) {
    emit(state.copyWith(
      temperature: event.data.temperature,
      humidity: event.data.humidity,
      pressure: event.data.pressure,
      altitude: event.data.altitude,
      isLoading: false,
    ));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

/// INTERNAL EVENT
class _AtmosphericConditionsUpdated extends AtmosphericConditionsEvent {
  final AtmosphericConditions data;

  const _AtmosphericConditionsUpdated(this.data);

  @override
  List<Object> get props => [data];
}
