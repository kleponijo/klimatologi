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

  /// =========================
  /// 🚀 START
  /// =========================
  Future<void> _onStarted(
    WatchEvaporasiStarted event,
    Emitter<EvaporasiState> emit,
  ) async {
    // chartLabels & listData untuk list/label di UI

    emit(state.copyWith(isLoading: true));

    final history = await _repository.getSensorHistory(
      'evaporasi/history',
      (json) => Evaporasi.fromJson(json),
    );

    // listData dipakai untuk tab/list di UI (default: ambil data yang sudah ada di Firebase)
    final listData = List<Evaporasi>.from(history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));


    final dailyGraph = TimeSeriesMapper.toDaily(

      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi,
    );

    final dailyTempGraph = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.suhu,
    );

    // Hitung status dari data terakhir history jika ada
    final lastValue = history.isNotEmpty ? history.last.evaporasi : 0.0;
    final (status, rain) = _computeWeatherStatus(lastValue);
    _emitEvaporasiAlert(status, rain, lastValue);

    emit(state.copyWith(
      history: history,
      listData: listData,
      dailyValues: dailyGraph,
      dailyTemperatures: dailyTempGraph,
      chartLabels: _buildChartLabels(
        period: 'Hari Ini',
      ),
      weatherStatus: status,
      willRain: rain,
      isLoading: false,
    ));

    await _subscription?.cancel();
    _subscription = _repository
        .getSensorStream('Monitoring', (json) => Evaporasi.fromJson(json))
        .listen((data) => add(_EvaporasiRealtimeUpdated(data)));
  }

  /// =========================
  /// ⚡ REALTIME
  /// =========================
  void _onRealtimeUpdated(
    _EvaporasiRealtimeUpdated event,
    Emitter<EvaporasiState> emit,
  ) {
    final updated = List<double>.from(state.dailyValues);
    final updatedTemp = List<double>.from(state.dailyTemperatures);
    final index = DateTime.now().hour;

    if (index < updated.length) {
      updated[index] = event.data.evaporasi;
      updatedTemp[index] = event.data.suhu;
    }

    final (status, rain) = _computeWeatherStatus(event.data.evaporasi);
    _emitEvaporasiAlert(status, rain, event.data.evaporasi);

    emit(state.copyWith(
      currentValue: event.data.evaporasi,
      temperature: event.data.suhu,
      waterLevel: event.data.tinggiAir,
      dailyValues: updated,
      dailyTemperatures: updatedTemp,
      weatherStatus: status,
      willRain: rain,
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
    List<double> updatedTemp;

    if (event.period == "Minggu Ini") {
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
    } else if (event.period == "Bulan Ini") {
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

// Pertahankan status cuaca saat ini (tidak berubah karena hanya ganti periode)
    emit(state.copyWith(
      dailyValues: updated,
      dailyTemperatures: updatedTemp,
      chartLabels: _buildChartLabels(period: event.period),
      isLoading: false,
    ));
  }

  /// =========================
  /// 📅 DATE SELECTED (Custom Date)
  /// =========================
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
      chartLabels: _buildChartLabels(period: 'Tanggal Khusus'),
      isLoading: false,
    ));
  }

  /// =========================
  /// 🔄 VIEW MODE CHANGED
  /// =========================
  Future<void> _onViewModeChanged(
    EvaporasiViewModeChanged event,
    Emitter<EvaporasiState> emit,
  ) async {
    if (event.mode == EvaporasiViewMode.period) {
      // Kembali ke mode period - trigger period change
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

  /// =========================
  /// 🌤️ HELPER: Status Cuaca
  /// =========================
  static (String status, bool willRain) _computeWeatherStatus(double value) {
    if (value <= 5.0) return ('Baik', false);
    if (value <= 10.0) return ('Sedang', true);
    return ('Buruk', true);
  }

  List<String> _buildChartLabels({required String period}) {
    if (period == 'Minggu Ini') {
      return const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    }

    // Untuk Bulan Ini & Tanggal Khusus/ Hari Ini, biarkan chart pakai 0..23 / 0..days
    final now = DateTime.now();
    if (period == 'Bulan Ini') {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      return List.generate(daysInMonth, (i) => '${i + 1}');
    }

    // Hari Ini / Tanggal Khusus => 24 jam
    return List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
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
      severity = AlertSeverity.info; // normal → bersihkan alert
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
}

/// INTERNAL EVENT
class _EvaporasiRealtimeUpdated extends EvaporasiEvent {
  final Evaporasi data;

  const _EvaporasiRealtimeUpdated(this.data);

  @override
  List<Object> get props => [data];
}
