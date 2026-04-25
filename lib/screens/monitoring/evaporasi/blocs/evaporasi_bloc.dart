import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

import '../../../../core/utils/time_series_mapper.dart';

part 'evaporasi_event.dart';
part 'evaporasi_state.dart';

class EvaporasiBloc extends Bloc<EvaporasiEvent, EvaporasiState> {
  final MonitoringRepository _repository;
  StreamSubscription<Evaporasi>? _subscription;

  EvaporasiBloc({required MonitoringRepository repository})
      : _repository = repository,
        super(const EvaporasiState()) {
    on<WatchEvaporasiStarted>(_onStarted);
    on<_EvaporasiRealtimeUpdated>(_onRealtimeUpdated);
    on<EvaporasiPeriodChanged>(_onPeriodChanged);
  }

  /// =========================
  /// 🚀 START
  /// =========================
  Future<void> _onStarted(
    WatchEvaporasiStarted event,
    Emitter<EvaporasiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final history = await _repository.getSensorHistory(
      'evaporasi/history',
      (json) => Evaporasi.fromJson(json),
    );

    final dailyGraph = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi, // ⚠️ sesuaikan nama field
    );

    emit(state.copyWith(
      history: history,
      dailyValues: dailyGraph,
      isLoading: false,
    ));

    await _subscription?.cancel();

    _subscription = _repository
        .getSensorStream(
      'Monitoring',
      (json) => Evaporasi.fromJson(json),
    )
        .listen((data) {
      add(_EvaporasiRealtimeUpdated(data));
    });
  }

  /// =========================
  /// ⚡ REALTIME
  /// =========================
  void _onRealtimeUpdated(
    _EvaporasiRealtimeUpdated event,
    Emitter<EvaporasiState> emit,
  ) {
    final updated = List<double>.from(state.dailyValues);

    final index = DateTime.now().hour;

    if (index < updated.length) {
      updated[index] = event.data.evaporasi; // ⚠️ sesuaikan field
    }

    emit(state.copyWith(
      currentValue: event.data.evaporasi,
      temperature: event.data.suhu,
      waterLevel: event.data.tinggiAir,
      dailyValues: updated,
    ));
  }

  /// =========================
  /// 📊 PERIOD
  /// =========================
  Future<void> _onPeriodChanged(
    EvaporasiPeriodChanged event,
    Emitter<EvaporasiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, selectedPeriod: event.period));

    final history = state.history;

    List<double> updated;

    if (event.period == "Minggu Ini") {
      updated = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
      );
    } else if (event.period == "Bulan Ini") {
      updated = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
      );
    } else {
      updated = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
      );
    }

    emit(state.copyWith(
      dailyValues: updated,
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
class _EvaporasiRealtimeUpdated extends EvaporasiEvent {
  final Evaporasi data;

  const _EvaporasiRealtimeUpdated(this.data);

  @override
  List<Object> get props => [data];
}
