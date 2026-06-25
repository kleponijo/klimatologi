import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../../../core/utils/time_series_mapper.dart';
import '../../../../blocs/notification_bloc/notification_bloc.dart';

part 'wind_speed_event.dart';
part 'wind_speed_state.dart';

/// Threshold kecepatan angin (satuan m/s)
/// Referensi: Beaufort scale & BMKG
const double _kWindWarning = 8.0; // Waspada: 8–12.5 m/s (~29–45 km/h)
const double _kWindDanger = 12.5; // Bahaya:  > 12.5 m/s (> 45 km/h)

class WindSpeedBloc extends Bloc<WindSpeedEvent, WindSpeedState> {
  final MonitoringRepository _repository;
  final NotificationBloc _notificationBloc;
  StreamSubscription<MyWindSpeed>? _subscription;

  WindSpeedBloc(
      {required MonitoringRepository repository,
      required NotificationBloc notificationBloc})
      : _repository = repository,
        _notificationBloc = notificationBloc,
        super(const WindSpeedState()) {
    /// 🔥 START MONITORING
    on<WatchWindSpeedStarted>(_onStarted, transformer: restartable());

    /// 🔥 REALTIME UPDATE
    on<_WindSpeedRealtimeUpdated>(_onRealtimeUpdated);

    /// 🔥 CHANGE PERIOD
    on<WindSpeedPeriodChanged>(_onPeriodChanged);
<<<<<<< Updated upstream
=======
    on<WindSpeedDateFilterChanged>(_onDateFilterChanged);
    on<WindSpeedHistoryDeleteAll>(_onDeleteAll);
    on<WindSpeedHistoryDeleteByDate>(_onDeleteByDate);
    on<WindSpeedHistoryDeleteByDateRange>(_onDeleteByDateRange);
    on<WindSpeedHistoryDeleteByHourRange>(_onDeleteByHourRange);
>>>>>>> Stashed changes
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
      orderByChild: 'timestamp',
      limit: 500,
    );

<<<<<<< Updated upstream
    final dailyGraph =
        TimeSeriesMapper.dailyFrom<MyWindSpeed>(history, (e) => e.speed);
    final weekly =
        TimeSeriesMapper.weeklyFrom<MyWindSpeed>(history, (e) => e.speed);
    final monthly =
        TimeSeriesMapper.monthlyFrom<MyWindSpeed>(history, (e) => e.speed);
=======
    // Aggregate data by period (no filtering/interpolation, trust Firebase data)
    final dailyGraph = TimeSeriesMapper.toDaily(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.speed,
    );
    final weekly = TimeSeriesMapper.toWeekly(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.speed,
    );
    final monthly = TimeSeriesMapper.toMonthly(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.speed,
    );
>>>>>>> Stashed changes

    // Cek kondisi awal dari history
    if (history.isNotEmpty) {
      _emitWindAlert(history.last.speed);
    }

    emit(state.copyWith(
      history: history,
      dailySpeeds: dailyGraph,
      weeklySpeeds: weekly,
      monthlySpeeds: monthly,
      isLoading: false,
      alertLevel: history.isNotEmpty // ← tambah ini
          ? _getAlertLevel(history.last.speed)
          : "Normal",
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

<<<<<<< Updated upstream
  /// =========================
  /// ⚡ REALTIME UPDATE
  /// =========================
=======
  // ════════════════════════════════════════════════════════════
  //  REALTIME UPDATE - Trust Firebase data, display as-is
  // ════════════════════════════════════════════════════════════
>>>>>>> Stashed changes
  void _onRealtimeUpdated(
    _WindSpeedRealtimeUpdated event,
    Emitter<WindSpeedState> emit,
  ) {
<<<<<<< Updated upstream
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
      updated[index] = newValue.clamp(0, 100);
    }
=======
    final newValue = event.data.speed;
>>>>>>> Stashed changes

    // Update current speed display and alert status
    _emitWindAlert(newValue);

    emit(state.copyWith(
      currentSpeed: newValue,
      alertLevel: _getAlertLevel(newValue),
    ));
  }

  /// =========================
  /// 📊 CHANGE PERIOD
  /// =========================
  void _onPeriodChanged(
    WindSpeedPeriodChanged event,
    Emitter<WindSpeedState> emit,
<<<<<<< Updated upstream
=======
  ) async {
    emit(state.copyWith(selectedPeriod: event.period));
    final history = state.history;

    List<double> raw;
    if (event.period == 'Minggu Ini') {
      raw = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
    } else if (event.period == 'Bulan Ini') {
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

    emit(state.copyWith(
      dailySpeeds: event.period == 'Hari Ini' ? raw : state.dailySpeeds,
      weeklySpeeds: event.period == 'Minggu Ini' ? raw : state.weeklySpeeds,
      monthlySpeeds: event.period == 'Bulan Ini' ? raw : state.monthlySpeeds,
      isLoading: false,
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  DATE FILTER CHANGED  ← baru
  // ════════════════════════════════════════════════════════════
  void _onDateFilterChanged(
    WindSpeedDateFilterChanged event,
    Emitter<WindSpeedState> emit,
>>>>>>> Stashed changes
  ) {
    emit(state.copyWith(selectedPeriod: event.period));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

<<<<<<< Updated upstream
=======
  // ════════════════════════════════════════════════════════════
  //  DELETE HISTORY HANDLERS
  // ════════════════════════════════════════════════════════════
  Future<void> _onDeleteAll(
    WindSpeedHistoryDeleteAll event,
    Emitter<WindSpeedState> emit,
  ) async {
    try {
      final deviceId = await _getDeviceId();
      await _repository.deleteSensorHistoryAll(
        'anemometer/$deviceId/history',
      );

      // Refresh data
      final history = await _repository.getSensorHistory(
        'anemometer/$deviceId/history',
        (json) => MyWindSpeed.fromJson(json),
      );

      final daily = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final weekly = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final monthly = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );

      emit(state.copyWith(
        history: history,
        filteredHistory: history,
        dailySpeeds: daily,
        weeklySpeeds: weekly,
        monthlySpeeds: monthly,
        deleteMessage: '✅ Semua history berhasil dihapus',
      ));
    } catch (e) {
      emit(state.copyWith(
        deleteMessage: '❌ Gagal hapus history: $e',
      ));
    }
  }

  Future<void> _onDeleteByDate(
    WindSpeedHistoryDeleteByDate event,
    Emitter<WindSpeedState> emit,
  ) async {
    try {
      final deviceId = await _getDeviceId();
      await _repository.deleteSensorHistoryByDate(
        'anemometer/$deviceId/history',
        event.date,
      );

      // Refresh data
      final history = await _repository.getSensorHistory(
        'anemometer/$deviceId/history',
        (json) => MyWindSpeed.fromJson(json),
      );

      final daily = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final weekly = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final monthly = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );

      emit(state.copyWith(
        history: history,
        filteredHistory: history,
        dailySpeeds: daily,
        weeklySpeeds: weekly,
        monthlySpeeds: monthly,
        deleteMessage:
            '✅ History ${event.date.day}/${event.date.month}/${event.date.year} berhasil dihapus',
      ));
    } catch (e) {
      emit(state.copyWith(
        deleteMessage: '❌ Gagal hapus history: $e',
      ));
    }
  }

  Future<void> _onDeleteByDateRange(
    WindSpeedHistoryDeleteByDateRange event,
    Emitter<WindSpeedState> emit,
  ) async {
    try {
      final deviceId = await _getDeviceId();
      await _repository.deleteSensorHistoryByDateRange(
        'anemometer/$deviceId/history',
        event.startDate,
        event.endDate,
      );

      // Refresh data
      final history = await _repository.getSensorHistory(
        'anemometer/$deviceId/history',
        (json) => MyWindSpeed.fromJson(json),
      );

      final daily = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final weekly = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final monthly = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );

      emit(state.copyWith(
        history: history,
        filteredHistory: history,
        dailySpeeds: daily,
        weeklySpeeds: weekly,
        monthlySpeeds: monthly,
        deleteMessage:
            '✅ History ${event.startDate.day}/${event.startDate.month} - ${event.endDate.day}/${event.endDate.month} berhasil dihapus',
      ));
    } catch (e) {
      emit(state.copyWith(
        deleteMessage: '❌ Gagal hapus history: $e',
      ));
    }
  }

  Future<void> _onDeleteByHourRange(
    WindSpeedHistoryDeleteByHourRange event,
    Emitter<WindSpeedState> emit,
  ) async {
    try {
      final deviceId = await _getDeviceId();
      await _repository.deleteSensorHistoryByHourRange(
        'anemometer/$deviceId/history',
        event.date,
        event.hourFrom,
        event.hourTo,
      );

      // Refresh data
      final history = await _repository.getSensorHistory(
        'anemometer/$deviceId/history',
        (json) => MyWindSpeed.fromJson(json),
      );

      final daily = TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final weekly = TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );
      final monthly = TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      );

      emit(state.copyWith(
        history: history,
        filteredHistory: history,
        dailySpeeds: daily,
        weeklySpeeds: weekly,
        monthlySpeeds: monthly,
        deleteMessage:
            '✅ History jam ${event.hourFrom}:00 - ${event.hourTo}:00 pada ${event.date.day}/${event.date.month}/${event.date.year} berhasil dihapus',
      ));
    } catch (e) {
      emit(state.copyWith(
        deleteMessage: '❌ Gagal hapus history: $e',
      ));
    }
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════
>>>>>>> Stashed changes
  String _getAlertLevel(double speed) {
    if (speed >= _kWindDanger) return "Bahaya";
    if (speed >= _kWindWarning) return "Waspada";
    return "Normal";
  }

// =========================
  // HELPER: kirim alert ke NotificationBloc
  // =========================
  void _emitWindAlert(double speed) {
    final AlertSeverity severity;
    final String message;

    if (speed >= _kWindDanger) {
      severity = AlertSeverity.danger;
      message = 'Kecepatan angin ${speed.toStringAsFixed(1)} m/s — BAHAYA';
    } else if (speed >= _kWindWarning) {
      severity = AlertSeverity.warning;
      message = 'Kecepatan angin ${speed.toStringAsFixed(1)} m/s — waspada';
    } else {
      severity = AlertSeverity.info; // normal → bersihkan alert
      message = '';
    }

    _notificationBloc.add(SensorAlertAdded(
      SensorAlert(
        sensorId: 'wind_speed',
        sensorName: 'Anemometer',
        message: message,
        severity: severity,
        timestamp: DateTime.now(),
      ),
    ));
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
