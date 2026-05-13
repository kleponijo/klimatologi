import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

import '../../../../core/utils/time_series_mapper.dart';
import '../../../../blocs/notification_bloc/notification_bloc.dart';

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
        super(const EvaporasiState()) {
    on<WatchEvaporasiStarted>(_onStarted);
    on<_EvaporasiRealtimeUpdated>(_onRealtimeUpdated);
    on<EvaporasiPeriodChanged>(_onPeriodChanged);
    on<EvaporasiDateSelected>(_onDateSelected);
    on<EvaporasiViewModeChanged>(_onViewModeChanged);
  }

  Future<void> _onStarted(
    WatchEvaporasiStarted event,
    Emitter<EvaporasiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Ambil history yang akan dipakai untuk list + agregasi grafik.
    final history = await _repository.getSensorHistory(
      'Monitoring/History',
      (json) => Evaporasi.fromJson(json),
    );

    final listData = List<Evaporasi>.from(history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final dailyGraph = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi, // ⚠️ sesuaikan nama field
    );

    final dailyTempGraph = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.suhu,
    );

    final weeklyGraph = TimeSeriesMapper.toWeekly(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi,
    );

    final monthlyGraph = TimeSeriesMapper.toMonthly(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi,
    );

    final weeklyTemp = TimeSeriesMapper.toWeekly(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.suhu,
    );

    final monthlyTemp = TimeSeriesMapper.toMonthly(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.suhu,
    );

    final lastValue = history.isNotEmpty ? history.last.evaporasi : 0.0;
    final lastWaterLevel = history.isNotEmpty ? history.last.tinggiAir : 0.0;
    final lastTemperature = history.isNotEmpty ? history.last.suhu : 0.0;
    final (status, rain) = _computeWeatherStatus(lastValue);
    _emitEvaporasiAlert(status, rain, lastValue);

    emit(state.copyWith(
      history: history,
      currentValue: lastValue,
      waterLevel: lastWaterLevel,
      temperature: lastTemperature,
      dailyValues: dailyGraph,
      dailyTemperatures: dailyTempGraph,
      weeklyValues: weeklyGraph,
      monthlyValues: monthlyGraph,
      weeklyTemperatures: weeklyTemp,
      monthlyTemperatures: monthlyTemp,
      chartLabels: _buildChartLabels(period: 'Hari Ini'),
      weatherStatus: status,
      willRain: rain,
      listData: listData,
      currentData: history.isNotEmpty ? history.last : null,
      isLoading: false,
    ));

    await _subscription?.cancel();
    _subscription = _repository
        .getSensorStream('Monitoring/History', _latestHistoryEntry)
        .listen((data) => add(_EvaporasiRealtimeUpdated(data)));
  }

  Evaporasi _latestHistoryEntry(Map<dynamic, dynamic> json) {
    if (json.isEmpty) return Evaporasi.empty;

    final entries = json.values
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => Evaporasi.fromJson(item))
        .toList();

    if (entries.isEmpty) return Evaporasi.empty;

    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return entries.last;
  }

  void _onRealtimeUpdated(
    _EvaporasiRealtimeUpdated event,
    Emitter<EvaporasiState> emit,
  ) {
    final updatedHistory = List<Evaporasi>.from(state.history);
    final duplicateIndex = updatedHistory.indexWhere(
      (item) => item.timestamp.toUtc() == event.data.timestamp.toUtc(),
    );

    if (duplicateIndex >= 0) {
      updatedHistory[duplicateIndex] = event.data;
    } else {
      updatedHistory.add(event.data);
    }
    updatedHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Update bucket berdasarkan timestamp event (bukan jam lokal sekarang).
    final updated = List<double>.from(state.dailyValues);
    final updatedTemp = List<double>.from(state.dailyTemperatures);

    final eventTime = event.data.timestamp;
    final now = DateTime.now();

    final isSameDayUtc = eventTime.toUtc().year == now.toUtc().year &&
        eventTime.toUtc().month == now.toUtc().month &&
        eventTime.toUtc().day == now.toUtc().day;

    if (isSameDayUtc) {
      final index = eventTime.hour;
      if (index >= 0 && index < updated.length) {
        updated[index] = event.data.evaporasi;
        updatedTemp[index] = event.data.suhu;
      }
    }

    final (status, rain) = _computeWeatherStatus(event.data.evaporasi);
    _emitEvaporasiAlert(status, rain, event.data.evaporasi);

    emit(state.copyWith(
      history: updatedHistory,
      listData: updatedHistory,
      currentValue: event.data.evaporasi,
      temperature: event.data.suhu,
      waterLevel: event.data.tinggiAir,
      dailyValues: updated,
      dailyTemperatures: updatedTemp,
      weatherStatus: status,
      willRain: rain,
      currentData: event.data,
    ));
  }

  Future<void> _onPeriodChanged(
    EvaporasiPeriodChanged event,
    Emitter<EvaporasiState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, selectedPeriod: event.period));

    final history = state.history;

    List<double> updated;
    List<double> updatedTemp;

    if (event.period == 'Minggu Ini') {
      updated = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
      );
      updatedTemp = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.suhu,
      );
    } else if (event.period == 'Bulan Ini') {
      updated = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
      );
      updatedTemp = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.suhu,
      );
    } else {
      updated = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.evaporasi,
      );
      updatedTemp = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.suhu,
      );
    }

    emit(state.copyWith(
      dailyValues: updated,
      dailyTemperatures: updatedTemp,
      chartLabels: _buildChartLabels(period: event.period),
      viewMode: EvaporasiViewMode.period,
      isLoading: false,
      listData: state.listData,
      history: state.history,
    ));
  }

  Future<void> _onDateSelected(
    EvaporasiDateSelected event,
    Emitter<EvaporasiState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      selectedDate: event.date,
      viewMode: EvaporasiViewMode.customDate,
    ));

    final history = state.history;

    final updated = TimeSeriesMapper.toSpecificDate(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi,
      targetDate: event.date,
    );

    final updatedTemp = TimeSeriesMapper.toSpecificDate(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.suhu,
      targetDate: event.date,
    );

    emit(state.copyWith(
      dailyValues: updated,
      dailyTemperatures: updatedTemp,
      isLoading: false,
      // jangan hilangkan list
      listData: state.listData,
      history: state.history,
    ));
  }

  Future<void> _onViewModeChanged(
    EvaporasiViewModeChanged event,
    Emitter<EvaporasiState> emit,
  ) async {
    if (event.mode == EvaporasiViewMode.period) {
      add(EvaporasiPeriodChanged(state.selectedPeriod));
    } else {
      emit(state.copyWith(viewMode: event.mode));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  static (String status, bool willRain) _computeWeatherStatus(double value) {
    if (value <= 5.0) return ('Baik', false);
    if (value <= 10.0) return ('Sedang', true);
    return ('Buruk', true);
  }

  void _emitEvaporasiAlert(String status, bool willRain, double value) {
    final AlertSeverity severity;
    final String message;

    if (status == 'Buruk') {
      severity = AlertSeverity.danger;
      message =
          'Evaporasi ${value.toStringAsFixed(1)} mm — status BURUK, potensi hujan tinggi';
    } else if (status == 'Sedang') {
      severity = AlertSeverity.warning;
      message =
          'Evaporasi ${value.toStringAsFixed(1)} mm — status sedang, potensi hujan';
    } else {
      severity = AlertSeverity.info;
      message = '';
    }

    _notificationBloc.add(SensorAlertAdded(
      SensorAlert(
        sensorId: 'evaporasi',
        sensorName: 'Evaporasi',
        message: message,
        severity: severity,
        timestamp: DateTime.now(),
      ),
    ));
  }

  List<String> _buildChartLabels({required String period}) {
    if (period == 'Minggu Ini') {
      return const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    }

    final now = DateTime.now();
    if (period == 'Bulan Ini') {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      return List.generate(daysInMonth, (i) => '${i + 1}');
    }

    // Hari Ini / Tanggal Khusus => 24 jam
    return List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
  }
}

class _EvaporasiRealtimeUpdated extends EvaporasiEvent {
  final Evaporasi data;

  const _EvaporasiRealtimeUpdated(this.data);

  @override
  List<Object> get props => [data];
}
