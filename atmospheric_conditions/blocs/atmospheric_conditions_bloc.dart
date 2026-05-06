import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

part 'atmospheric_conditions_event.dart';
part 'atmospheric_conditions_state.dart';

class AtmosphericConditionsBloc extends Bloc<AtmosphericConditionsEvent, AtmosphericConditionsState> {
  final MonitoringRepository _repository;
  StreamSubscription<AtmosphericConditions>? _subscription;
  static const int _maxHistoryItems = 1500;

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

    // Preload today's history from Firebase history table.
    final now = DateTime.now();
    final historyFromFirebase = await _repository.getSensorHistory(
      '/sensor/history',
      (json) => AtmosphericConditions.fromJson(json),
    );

    final todayHistory = historyFromFirebase.where((item) => _isSameDay(item.timestamp, now)).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final trimmedHistory = todayHistory.length > _maxHistoryItems ? todayHistory.sublist(todayHistory.length - _maxHistoryItems) : todayHistory;

    final latestFromHistory = trimmedHistory.isNotEmpty ? trimmedHistory.last : null;

    emit(state.copyWith(
      temperature: latestFromHistory?.temperature ?? state.temperature,
      humidity: latestFromHistory?.humidity ?? state.humidity,
      pressure: latestFromHistory?.pressure ?? state.pressure,
      altitude: latestFromHistory?.altitude ?? state.altitude,
      timeMs: latestFromHistory?.timeMs ?? state.timeMs,
      history: trimmedHistory,
      isLoading: false,
    ));

    _subscription = _repository
        .getSensorStream(
      '/sensor/latest',
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
    final now = DateTime.now();
    final updatedHistory = state.history.where((item) => _isSameDay(item.timestamp, now)).toList();

    final shouldAppend = updatedHistory.isEmpty || updatedHistory.last.timeMs != event.data.timeMs || updatedHistory.last.pressure != event.data.pressure || updatedHistory.last.timestamp != event.data.timestamp;

    if (shouldAppend) {
      updatedHistory.add(event.data);

      if (updatedHistory.length > _maxHistoryItems) {
        updatedHistory.removeAt(0);
      }
    }

    emit(state.copyWith(
      temperature: event.data.temperature,
      humidity: event.data.humidity,
      pressure: event.data.pressure,
      altitude: event.data.altitude,
      timeMs: event.data.timeMs,
      history: updatedHistory,
      isLoading: false,
    ));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
  List<Object> get props => [
        data
      ];
}
