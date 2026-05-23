import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
const _kDeviceIdKey = 'selected_device_id';
const _kDefaultDeviceId = 'esp_lapangan';

class WindSpeedBloc extends Bloc<WindSpeedEvent, WindSpeedState> {
  final MonitoringRepository _repository;
  final NotificationBloc _notificationBloc;
  StreamSubscription<MyWindSpeed>? _subscription;

  WindSpeedBloc({
    required MonitoringRepository repository,
    required NotificationBloc notificationBloc,
  })  : _repository = repository,
        _notificationBloc = notificationBloc,
        super(const WindSpeedState()) {
    on<WatchWindSpeedStarted>(_onStarted, transformer: restartable());
    on<_WindSpeedRealtimeUpdated>(_onRealtimeUpdated);
    on<WindSpeedPeriodChanged>(_onPeriodChanged);
    on<WindSpeedDateFilterChanged>(_onDateFilterChanged); // ← baru
  }

  // ── Baca device ID dari SharedPreferences ─────────────────
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDeviceIdKey) ?? _kDefaultDeviceId;
  }

  // ════════════════════════════════════════════════════════════
  //  START
  // ════════════════════════════════════════════════════════════
  Future<void> _onStarted(
    WatchWindSpeedStarted event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Baca device ID aktif (dari SharedPreferences, diset di DeviceSetupBloc)
    final deviceId = await _getDeviceId();

    final history = await _repository.getSensorHistory(
      'anemometer/$deviceId/history',
      (json) => MyWindSpeed.fromJson(json),
    );

    final dailyGraph = TimeSeriesMapper.smooth(
      TimeSeriesMapper.toDaily(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      ),
    );
    final weekly = TimeSeriesMapper.smooth(
      TimeSeriesMapper.toWeekly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      ),
    );
    final monthly = TimeSeriesMapper.smooth(
      TimeSeriesMapper.toMonthly(
        data: history,
        getTime: (e) => e.timestamp,
        getValue: (e) => e.speed,
      ),
    );

    if (history.isNotEmpty) {
      _emitWindAlert(history.last.speed);
    }

    emit(state.copyWith(
      history: history,
      filteredHistory: history, // awal = semua data
      dailySpeeds: dailyGraph,
      weeklySpeeds: weekly,
      monthlySpeeds: monthly,
      isLoading: false,
      alertLevel:
          history.isNotEmpty ? _getAlertLevel(history.last.speed) : 'Normal',
    ));

    // Subscribe realtime dari path device aktif
    await _subscription?.cancel();
    _subscription = _repository
        .getSensorStream(
          'anemometer/$deviceId/realtime',
          (json) => MyWindSpeed.fromJson(json),
        )
        .listen((data) => add(_WindSpeedRealtimeUpdated(data)));
  }

  // ════════════════════════════════════════════════════════════
  //  REALTIME UPDATE
  // ════════════════════════════════════════════════════════════
  void _onRealtimeUpdated(
    _WindSpeedRealtimeUpdated event,
    Emitter<WindSpeedState> emit,
  ) {
    final updated = List<double>.from(state.dailySpeeds);
    final index = DateTime.now().hour;
    double newValue = event.data.speed;

    if (index < updated.length) {
      final lastValue = updated[index];
      if (lastValue != 0) {
        if ((newValue - lastValue).abs() > 15) {
          newValue = lastValue;
        } else {
          newValue = (lastValue + newValue) / 2;
        }
      }
      updated[index] = newValue.clamp(0, 100);
    }

    _emitWindAlert(newValue);

    emit(state.copyWith(
      currentSpeed: newValue,
      dailySpeeds: updated,
      alertLevel: _getAlertLevel(newValue),
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  PERIOD CHANGED
  // ════════════════════════════════════════════════════════════
  Future<void> _onPeriodChanged(
    WindSpeedPeriodChanged event,
    Emitter<WindSpeedState> emit,
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

    final updatedGraph = TimeSeriesMapper.smooth(raw);

    emit(state.copyWith(
      dailySpeeds:
          event.period == 'Hari Ini' ? updatedGraph : state.dailySpeeds,
      weeklySpeeds:
          event.period == 'Minggu Ini' ? updatedGraph : state.weeklySpeeds,
      monthlySpeeds:
          event.period == 'Bulan Ini' ? updatedGraph : state.monthlySpeeds,
      isLoading: false,
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  DATE FILTER CHANGED  ← baru
  // ════════════════════════════════════════════════════════════
  void _onDateFilterChanged(
    WindSpeedDateFilterChanged event,
    Emitter<WindSpeedState> emit,
  ) {
    final date = event.date;
    final allHistory = state.history;

    if (date == null) {
      // Reset: tampilkan semua
      emit(state.copyWith(
        filteredHistory: allHistory,
        clearSelectedDate: true,
      ));
      return;
    }

    // Filter data yang tanggalnya sama dengan [date]
    final filtered = allHistory.where((item) {
      return item.timestamp.year == date.year &&
          item.timestamp.month == date.month &&
          item.timestamp.day == date.day;
    }).toList();

    emit(state.copyWith(
      filteredHistory: filtered,
      selectedDate: date,
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════
  String _getAlertLevel(double speed) {
    if (speed >= _kWindDanger) return 'Bahaya';
    if (speed >= _kWindWarning) return 'Waspada';
    return 'Normal';
  }

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
      severity = AlertSeverity.info;
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

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

/// Internal event — tidak diekspos ke luar
class _WindSpeedRealtimeUpdated extends WindSpeedEvent {
  final MyWindSpeed data;
  const _WindSpeedRealtimeUpdated(this.data);

  @override
  List<Object?> get props => [data];
}
