// lib/screens/monitoring/evaporasi/blocs/evaporasi_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

import '../../../../blocs/notification_bloc/notification_bloc.dart';
import '../../../../core/utils/time_series_mapper.dart';

part 'evaporasi_event.dart';
part 'evaporasi_state.dart';

class EvaporasiBloc extends Bloc<EvaporasiEvent, EvaporasiState> {
  final MonitoringRepository _repository;
  final NotificationBloc _notificationBloc;
  StreamSubscription<Evaporasi>? _subscription;

  EvaporasiBloc({
    required MonitoringRepository repository,
    required NotificationBloc notificationBloc,
  })  : _repository = repository,
        _notificationBloc = notificationBloc,
        super(EvaporasiState()) {
    on<WatchEvaporasiStarted>(_onStarted);
    on<_EvaporasiRealtimeUpdated>(_onRealtimeUpdated);
    on<EvaporasiDateRangeChanged>(_onDateRangeChanged);
    on<EvaporasiDateFilterChanged>(_onDateFilterChanged);
  }

  // ════════════════════════════════════════════════════════════
  //  START
  // ════════════════════════════════════════════════════════════
  Future<void> _onStarted(
    WatchEvaporasiStarted event,
    Emitter<EvaporasiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final history = List<Evaporasi>.from(
      await _repository.getSensorHistory(
        'Monitoring/History',
        (json) => Evaporasi.fromJson(json),
      ),
    )..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final now = DateTime.now();

    // Default: tampilkan hari ini (per jam)
    final dailyEvap = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi,
    );
    final dailyTemp = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.suhu,
    );
    final labels = List.generate(
        24, (i) => '${i.toString().padLeft(2, '0')}:00');

    final lastValue = history.isNotEmpty ? history.last.evaporasi : 0.0;
    final lastWater = history.isNotEmpty ? history.last.tinggiAir : 0.0;
    final lastTemp  = history.isNotEmpty ? history.last.suhu : 0.0;

    final (status, willRain) = _computeStatus(lastValue);
    _emitAlert(status, willRain, lastValue);

    emit(state.copyWith(
      history: history,
      filteredHistory: history,
      currentValue: lastValue,
      waterLevel: lastWater,
      temperature: lastTemp,
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day),
      chartValues: dailyEvap,
      chartTemperatures: dailyTemp,
      chartLabels: labels,
      weatherStatus: status,
      willRain: willRain,
      currentData: history.isNotEmpty ? history.last : null,
      isLoading: false,
    ));

    await _subscription?.cancel();
    _subscription = _repository
        .getSensorStream(
          'Monitoring/realtime',
          (json) {
            return Evaporasi.fromJson(json);
          },
        )
        .listen((data) => add(_EvaporasiRealtimeUpdated(data)));
  }

  // ════════════════════════════════════════════════════════════
  //  REALTIME UPDATE
  // ════════════════════════════════════════════════════════════
  void _onRealtimeUpdated(
    _EvaporasiRealtimeUpdated event,
    Emitter<EvaporasiState> emit,
  ) {
    final updatedHistory = List<Evaporasi>.from(state.history);
    final dupIdx = updatedHistory.indexWhere(
      (e) => e.timestamp.toUtc() == event.data.timestamp.toUtc(),
    );
    if (dupIdx >= 0) {
      updatedHistory[dupIdx] = event.data;
    } else {
      updatedHistory.add(event.data);
    }
    updatedHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Regenerasikan data chart secara dinamis agar selalu sinkron dengan data real-time
    List<double> updatedChart;
    List<double> updatedTemp;
    List<String> updatedLabels = state.chartLabels;

    final isSingle = _isSameDay(state.startDate, state.endDate);

    if (isSingle) {
      updatedChart = TimeSeriesMapper.toSpecificDate(
        data: updatedHistory,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
        targetDate: state.startDate,
      );
      updatedTemp = TimeSeriesMapper.toSpecificDate(
        data: updatedHistory,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.suhu,
        targetDate: state.startDate,
      );
      updatedLabels = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
    } else {
      final evapResult = TimeSeriesMapper.toDateRange(
        data: updatedHistory,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
        startDate: state.startDate,
        endDate: state.endDate,
      );
      final tempResult = TimeSeriesMapper.toDateRange(
        data: updatedHistory,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.suhu,
        startDate: state.startDate,
        endDate: state.endDate,
      );
      updatedChart = evapResult.values;
      updatedTemp  = tempResult.values;
      updatedLabels = evapResult.labels;
    }

    final (status, willRain) = _computeStatus(event.data.evaporasi);
    _emitAlert(status, willRain, event.data.evaporasi);

    emit(state.copyWith(
      history: updatedHistory,
      filteredHistory: state.selectedDateFilter != null
          ? updatedHistory.where((e) =>
              e.timestamp.year == state.selectedDateFilter!.year &&
              e.timestamp.month == state.selectedDateFilter!.month &&
              e.timestamp.day == state.selectedDateFilter!.day).toList()
          : updatedHistory,
      currentValue: event.data.evaporasi,
      temperature: event.data.suhu,
      waterLevel: event.data.tinggiAir,
      chartValues: updatedChart,
      chartTemperatures: updatedTemp,
      chartLabels: updatedLabels,
      weatherStatus: status,
      willRain: willRain,
      currentData: event.data,
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  DATE RANGE CHANGED
  // ════════════════════════════════════════════════════════════
  Future<void> _onDateRangeChanged(
    EvaporasiDateRangeChanged event,
    Emitter<EvaporasiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final history = state.history;
    final start = event.startDate;
    final end   = event.endDate;

    final isSingle = _isSameDay(start, end);

    List<double> values;
    List<double> temps;
    List<String> labels;

    if (isSingle) {
      // 1 hari → per jam
      values = TimeSeriesMapper.toSpecificDate(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
        targetDate: start,
      );
      temps = TimeSeriesMapper.toSpecificDate(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.suhu,
        targetDate: start,
      );
      labels = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
    } else {
      // Range → per hari
      final evapResult = TimeSeriesMapper.toDateRange(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
        startDate: start,
        endDate: end,
      );
      final tempResult = TimeSeriesMapper.toDateRange(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.suhu,
        startDate: start,
        endDate: end,
      );
      values = evapResult.values;
      temps  = tempResult.values;
      labels = evapResult.labels;
    }

    emit(state.copyWith(
      startDate: start,
      endDate: end,
      chartValues: values,
      chartTemperatures: temps,
      chartLabels: labels,
      isLoading: false,
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  DATE FILTER (LIST)
  // ════════════════════════════════════════════════════════════
  void _onDateFilterChanged(
    EvaporasiDateFilterChanged event,
    Emitter<EvaporasiState> emit,
  ) {
    final date = event.date;
    if (date == null) {
      emit(state.copyWith(
        filteredHistory: state.history,
        clearSelectedDateFilter: true,
      ));
      return;
    }
    final filtered = state.history.where((item) =>
        item.timestamp.year == date.year &&
        item.timestamp.month == date.month &&
        item.timestamp.day == date.day).toList();

    emit(state.copyWith(
      filteredHistory: filtered,
      selectedDateFilter: date,
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static (String, bool) _computeStatus(double v) {
    if (v > 10.0) return ('Tinggi', true);
    if (v >= 2.0) return ('Normal', false);
    return ('Rendah', false);
  }

  void _emitAlert(String status, bool willRain, double value) {
    final AlertSeverity severity;
    final String message;
    if (status == 'Tinggi') {
      severity = AlertSeverity.danger;
      message = 'Evaporasi ${value.toStringAsFixed(1)} mm — TINGGI';
    } else if (status == 'Normal') {
      severity = AlertSeverity.warning;
      message = 'Evaporasi ${value.toStringAsFixed(1)} mm — Normal';
    } else {
      severity = AlertSeverity.info;
      message = '';
    }
    _notificationBloc.add(SensorAlertAdded(SensorAlert(
      sensorId: 'evaporasi',
      sensorName: 'Evaporasi',
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
    )));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _EvaporasiRealtimeUpdated extends EvaporasiEvent {
  final Evaporasi data;
  const _EvaporasiRealtimeUpdated(this.data);

  @override
  List<Object?> get props => [data];
}