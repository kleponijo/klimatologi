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

const double _kWindWarning = 25.0;
const double _kWindDanger = 45.5;
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
    on<WindSpeedDateFilterChanged>(_onDateFilterChanged);
    // Delete handlers
    on<WindSpeedDeleteAllRequested>(_onDeleteAll);
    on<WindSpeedDeleteByDateRequested>(_onDeleteByDate);
    on<WindSpeedDeleteByDateRangeRequested>(_onDeleteByDateRange);
    on<WindSpeedDeleteByHourRangeRequested>(_onDeleteByHourRange);
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDeviceIdKey) ?? _kDefaultDeviceId;
  }

  // ════════════════════════════════════════════════════════════
  //  START — sekarang fetch dengan keys untuk delete support
  // ════════════════════════════════════════════════════════════
  Future<void> _onStarted(
    WatchWindSpeedStarted event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final deviceId = await _getDeviceId();

    final historyMap = await _repository.getSensorHistoryWithKeys(
      'anemometer/$deviceId/history',
      (json) => MyWindSpeed.fromJson(json),
    );

    final history = _sortedList(historyMap);
    final graphs = _buildGraphs(history);

    if (history.isNotEmpty) _emitWindAlert(history.last.speed);

    emit(state.copyWith(
      historyMap: historyMap,
      history: history,
      filteredHistory: history,
      dailySpeeds: graphs['daily']!,
      weeklySpeeds: graphs['weekly']!,
      monthlySpeeds: graphs['monthly']!,
      isLoading: false,
      alertLevel:
          history.isNotEmpty ? _getAlertLevel(history.last.speed) : 'Normal',
    ));

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
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  DATE FILTER
  // ════════════════════════════════════════════════════════════
  void _onDateFilterChanged(
    WindSpeedDateFilterChanged event,
    Emitter<WindSpeedState> emit,
  ) {
    final date = event.date;
    if (date == null) {
      emit(state.copyWith(
        filteredHistory: state.history,
        clearSelectedDate: true,
      ));
      return;
    }

    final filtered =
        state.history.where((e) => _isSameDate(e.timestamp, date)).toList();

    emit(state.copyWith(filteredHistory: filtered, selectedDate: date));
  }

  // ════════════════════════════════════════════════════════════
  //  DELETE ALL
  // ════════════════════════════════════════════════════════════
  Future<void> _onDeleteAll(
    WindSpeedDeleteAllRequested event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearDeleteError: true));
    try {
      final deviceId = await _getDeviceId();
      await _repository.deleteAllHistory('anemometer/$deviceId/history');
      final emptyGraphs = _buildGraphs(const []);
      emit(state.copyWith(
        isDeleting: false,
        historyMap: const {},
        history: const [],
        filteredHistory: const [],
        clearSelectedDate: true,
        dailySpeeds: emptyGraphs['daily'],
        weeklySpeeds: emptyGraphs['weekly'],
        monthlySpeeds: emptyGraphs['monthly'],
      ));
    } catch (e) {
      emit(state.copyWith(isDeleting: false, deleteError: e.toString()));
    }
  }

  // ════════════════════════════════════════════════════════════
  //  DELETE BY DATE
  // ════════════════════════════════════════════════════════════
  Future<void> _onDeleteByDate(
    WindSpeedDeleteByDateRequested event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearDeleteError: true));
    try {
      final deviceId = await _getDeviceId();

      final keys = state.historyMap.entries
          .where((e) => _isSameDate(e.value.timestamp, event.date))
          .map((e) => e.key)
          .toList();

      if (keys.isNotEmpty) {
        await _repository.deleteHistoryByKeys(
            'anemometer/$deviceId/history', keys);
      }

      _emitAfterDelete(emit, _removeKeys(state.historyMap, keys));
    } catch (e) {
      emit(state.copyWith(isDeleting: false, deleteError: e.toString()));
    }
  }

  // ════════════════════════════════════════════════════════════
  //  DELETE BY DATE RANGE
  // ════════════════════════════════════════════════════════════
  Future<void> _onDeleteByDateRange(
    WindSpeedDeleteByDateRangeRequested event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearDeleteError: true));
    try {
      final deviceId = await _getDeviceId();

      final startDay =
          DateTime(event.start.year, event.start.month, event.start.day);
      final endInclusive =
          DateTime(event.end.year, event.end.month, event.end.day, 23, 59, 59);

      final keys = state.historyMap.entries
          .where((e) {
            final t = e.value.timestamp;
            return !t.isBefore(startDay) && !t.isAfter(endInclusive);
          })
          .map((e) => e.key)
          .toList();

      if (keys.isNotEmpty) {
        await _repository.deleteHistoryByKeys(
            'anemometer/$deviceId/history', keys);
      }

      _emitAfterDelete(emit, _removeKeys(state.historyMap, keys));
    } catch (e) {
      emit(state.copyWith(isDeleting: false, deleteError: e.toString()));
    }
  }

  // ════════════════════════════════════════════════════════════
  //  DELETE BY HOUR RANGE
  // ════════════════════════════════════════════════════════════
  Future<void> _onDeleteByHourRange(
    WindSpeedDeleteByHourRangeRequested event,
    Emitter<WindSpeedState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearDeleteError: true));
    try {
      final deviceId = await _getDeviceId();

      final keys = state.historyMap.entries
          .where((e) {
            final t = e.value.timestamp;
            return _isSameDate(t, event.date) &&
                t.hour >= event.startHour &&
                t.hour <= event.endHour;
          })
          .map((e) => e.key)
          .toList();

      if (keys.isNotEmpty) {
        await _repository.deleteHistoryByKeys(
            'anemometer/$deviceId/history', keys);
      }

      // Re-apply filter aktif jika ada
      final newMap = _removeKeys(state.historyMap, keys);
      final newHistory = _sortedList(newMap);
      final newFiltered = state.selectedDate != null
          ? newHistory
              .where((e) => _isSameDate(e.timestamp, state.selectedDate!))
              .toList()
          : newHistory;
      final graphs = _buildGraphs(newHistory);

      emit(state.copyWith(
        isDeleting: false,
        historyMap: newMap,
        history: newHistory,
        filteredHistory: newFiltered,
        dailySpeeds: graphs['daily'],
        weeklySpeeds: graphs['weekly'],
        monthlySpeeds: graphs['monthly'],
      ));
    } catch (e) {
      emit(state.copyWith(isDeleting: false, deleteError: e.toString()));
    }
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════

  /// Emit state setelah delete all/date/range (selalu reset filter)
  void _emitAfterDelete(
    Emitter<WindSpeedState> emit,
    Map<String, MyWindSpeed> newMap,
  ) {
    final newHistory = _sortedList(newMap);
    final graphs = _buildGraphs(newHistory);
    emit(state.copyWith(
      isDeleting: false,
      historyMap: newMap,
      history: newHistory,
      filteredHistory: newHistory,
      clearSelectedDate: true,
      dailySpeeds: graphs['daily'],
      weeklySpeeds: graphs['weekly'],
      monthlySpeeds: graphs['monthly'],
    ));
  }

  Map<String, List<double>> _buildGraphs(List<MyWindSpeed> history) {
    return {
      'daily': TimeSeriesMapper.smooth(
        TimeSeriesMapper.toDaily(
          data: history,
          getTime: (e) => e.timestamp,
          getValue: (e) => e.speed,
        ),
      ),
      'weekly': TimeSeriesMapper.smooth(
        TimeSeriesMapper.toWeekly(
          data: history,
          getTime: (e) => e.timestamp,
          getValue: (e) => e.speed,
        ),
      ),
      'monthly': TimeSeriesMapper.smooth(
        TimeSeriesMapper.toMonthly(
          data: history,
          getTime: (e) => e.timestamp,
          getValue: (e) => e.speed,
        ),
      ),
    };
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, MyWindSpeed> _removeKeys(
    Map<String, MyWindSpeed> map,
    List<String> keys,
  ) {
    final newMap = Map<String, MyWindSpeed>.from(map);
    for (final k in keys) newMap.remove(k);
    return newMap;
  }

  List<MyWindSpeed> _sortedList(Map<String, MyWindSpeed> map) {
    return map.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

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

    _notificationBloc.add(SensorAlertAdded(SensorAlert(
      sensorId: 'wind_speed',
      sensorName: 'Anemometer',
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

class _WindSpeedRealtimeUpdated extends WindSpeedEvent {
  final MyWindSpeed data;
  const _WindSpeedRealtimeUpdated(this.data);

  @override
  List<Object?> get props => [data];
}
