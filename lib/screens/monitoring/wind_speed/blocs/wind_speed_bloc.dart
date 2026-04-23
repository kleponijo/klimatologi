import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../../../core/utils/time_series_mapper.dart';

part 'wind_speed_event.dart';
part 'wind_speed_state.dart';

class WindSpeedBloc extends Bloc<WindSpeedEvent, WindSpeedState> {
  final MonitoringRepository _repository;
  StreamSubscription<MyWindSpeed>? _subscription;

  WindSpeedBloc({required MonitoringRepository repository})
      : _repository = repository,
        super(const WindSpeedState()) {
    /// 🔥 START MONITORING
    on<WatchWindSpeedStarted>(_onStarted, transformer: restartable());

    /// 🔥 REALTIME UPDATE
    on<_WindSpeedRealtimeUpdated>(_onRealtimeUpdated);

    /// 🔥 CHANGE PERIOD
    on<WindSpeedPeriodChanged>(_onPeriodChanged);
  }

  /// =========================
  /// 🚀 START
  /// =========================
  Future<void> _onStarted(
    WatchWindSpeedStarted event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    /// 1. Ambil history SEKALI
    final history = await _repository.getSensorHistory(
      'anemometer/history',
      (json) => MyWindSpeed.fromJson(json),
    );

    /// 2. Mapping default (harian)
    final raw = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.speed,
    );
    final dailyGraph = TimeSeriesMapper.smooth(raw);

    emit(state.copyWith(
      history: history,
      dailySpeeds: dailyGraph,
      isLoading: false,
    ));

    /// 3. Start realtime stream (manual subscription)
    await _subscription?.cancel();

    _subscription = _repository
        .getSensorStream(
      'anemometer/realtime',
      (json) => MyWindSpeed.fromJson(json),
    )
        .listen((data) {
      add(_WindSpeedRealtimeUpdated(data));
    });
  }

  /// =========================
  /// ⚡ REALTIME UPDATE
  /// =========================
  void _onRealtimeUpdated(
    _WindSpeedRealtimeUpdated event,
    Emitter<WindSpeedState> emit,
  ) {
    final updated = List<double>.from(state.dailySpeeds);

    final index = DateTime.now().hour;
    double newValue = event.data.speed;

    if (index < updated.length) {
      final lastValue = updated[index];

      /// 🔥 ANTI SPIKE + SMOOTHING
      if (lastValue != 0) {
        if ((newValue - lastValue).abs() > 15) {
          newValue = lastValue; // buang spike
        } else {
          newValue = (lastValue + newValue) / 2; // smoothing
        }
      }

      updated[index] = newValue;
    }

    emit(state.copyWith(
      currentSpeed: newValue,
      dailySpeeds: updated,
    ));
  }

  /// =========================
  /// 📊 CHANGE PERIOD
  /// =========================
  Future<void> _onPeriodChanged(
    WindSpeedPeriodChanged event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, selectedPeriod: event.period));

    final history = state.history;

    List<double> raw;

    if (event.period == "Minggu Ini") {
      raw = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
    } else if (event.period == "Bulan Ini") {
      raw = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
    } else {
      raw = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
    }

    /// 🔥 baru di-smooth
    final updatedGraph = TimeSeriesMapper.smooth(raw);

    emit(state.copyWith(
      dailySpeeds: updatedGraph,
      isLoading: false,
    ));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

/// =========================
/// 🔒 INTERNAL EVENT (PRIVATE)
/// =========================
class _WindSpeedRealtimeUpdated extends WindSpeedEvent {
  final MyWindSpeed data;

  const _WindSpeedRealtimeUpdated(this.data);

  @override
  List<Object> get props => [data];
}
