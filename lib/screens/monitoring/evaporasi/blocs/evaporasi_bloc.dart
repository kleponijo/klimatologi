// lib/screens/monitoring/evaporasi/blocs/evaporasi_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

import '../../../../blocs/notification_bloc/notification_bloc.dart';
import '../../../../core/utils/time_series_mapper.dart';

part 'evaporasi_event.dart';
part 'evaporasi_state.dart';

class EvaporasiBloc extends Bloc<EvaporasiEvent, EvaporasiState> {
  static List<DateTime> _buildDayList(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final days = <DateTime>[];
    DateTime cur = s;
    while (!cur.isAfter(e)) {
      days.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return days;
  }

  static List<String> _buildLabels(List<DateTime> days) {
    return days.map((d) {
      if (days.length <= 14) {
        return '${d.day} ${_bulan(d.month)}';
      }
      return '${d.day}/${d.month}';
    }).toList();
  }

  static String _bulan(int m) {
    const b = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return b[m];
  }

  final MonitoringRepository _repository;
  final NotificationBloc _notificationBloc;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<Evaporasi>? _subscription;
  double _thresholdRendah = 2.0;
  double _thresholdTinggi = 10.0;

  EvaporasiBloc({
    required MonitoringRepository repository,
    required NotificationBloc notificationBloc,
  })  : _repository = repository,
        _notificationBloc = notificationBloc,
        super(EvaporasiState()) {
    _initLocalNotifications();
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

    await _loadThresholdSettings();

    final lastValue = history.isNotEmpty ? history.last.evaporasi : 0.0;
    final lastWater = history.isNotEmpty ? history.last.tinggiAir : 0.0;
    final lastTemp  = history.isNotEmpty ? history.last.suhu : 0.0;

    final (status, willRain) = computeStatus(
      lastValue,
      thresholdRendah: _thresholdRendah,
      thresholdTinggi: _thresholdTinggi,
    );
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
  Future<void> _onRealtimeUpdated(
    _EvaporasiRealtimeUpdated event,
    Emitter<EvaporasiState> emit,
  ) async {
    await _loadThresholdSettings();

    final (status, willRain) = computeStatus(
      event.data.evaporasi,
      thresholdRendah: _thresholdRendah,
      thresholdTinggi: _thresholdTinggi,
    );

    final bool hasFallenBelowCritical =
        event.data.tinggiAir < state.batasKritisCm &&
        state.waterLevel >= state.batasKritisCm;
    final bool statusBecameHigh =
        state.weatherStatus != 'Tinggi' && status == 'Tinggi';

    if (hasFallenBelowCritical || statusBecameHigh) {
      await _showCriticalNotification();
    }

    _emitAlert(status, willRain, event.data.evaporasi);

    emit(state.copyWith(
      currentValue: event.data.evaporasi,
      temperature: event.data.suhu,
      waterLevel: event.data.tinggiAir,
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
    final selectedDate = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );

    final values = TimeSeriesMapper.toSpecificDate(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.evaporasi,
      targetDate: selectedDate,
    );
    final temps = TimeSeriesMapper.toSpecificDate(
      data: history,
      getTime: (e) => e.timestamp,
      getValue: (e) => e.suhu,
      targetDate: selectedDate,
    );
    final labels = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');

    emit(state.copyWith(
      startDate: selectedDate,
      endDate: selectedDate,
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

  static (String, bool) computeStatus(
    double value, {
      double thresholdRendah = 2.0,
      double thresholdTinggi = 10.0,
    }) {
    if (value >= thresholdTinggi) return ('Tinggi', true);
    if (value >= thresholdRendah) return ('Normal', false);
    return ('Rendah', false);
  }

  Future<void> _loadThresholdSettings() async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('Monitoring/settings/evaporasi')
          .get();
      if (!snap.exists || snap.value == null) return;

      final data = Map<String, dynamic>.from(snap.value as Map);
      _thresholdRendah = _toDouble(data['threshold_rendah'], _thresholdRendah);
      _thresholdTinggi = _toDouble(data['threshold_tinggi'], _thresholdTinggi);
    } catch (_) {
      // Tetap pakai nilai default jika pembacaan gagal.
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    try {
      await _localNotificationsPlugin.initialize(settings: initSettings);
    } catch (_) {
      // Jika gagal, lanjutkan tanpa notifikasi lokal.
    }
  }

  Future<void> _showCriticalNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'evaporasi_alerts',
      'Evaporasi Alerts',
      channelDescription: 'Peringatan Evaporasi dan level air kritis',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Peringatan Darurat',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    try {
      await _localNotificationsPlugin.show(
        id: 0,
        title: 'Peringatan Darurat',
        body: 'Peringatan Darurat: Batas Air Kritis tercapai, periksa pompa segera!',
        notificationDetails: notificationDetails,
      );
    } catch (_) {
      // Ignore local notification failure.
    }
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
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