// lib/screens/monitoring/evaporasi/blocs/evaporasi_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
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
  StreamSubscription<Evaporasi>? _subscription;
  double _thresholdRendah = 2.0;
  double _thresholdTinggi = 10.0;

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
      // Range → per hari (tapi evaporasi dikalibrasi dengan rumus:
      // E(hari ke-2) = max(evap hari ke-1) - max(evap hari ke-2))
      final days = _buildDayList(start, end);


      final dailyMaxEvap = List<double>.filled(days.length, 0.0);
      final dailyMaxTemp = List<double>.filled(days.length, 0.0);
      final dailyHasValue = List<bool>.filled(days.length, false);


      for (final item in history) {
        final d = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
        final idx = days.indexWhere((x) => x == d);
        if (idx < 0) continue;

        final evap = item.evaporasi;
        final temp = item.suhu;

        if (!dailyHasValue[idx]) {
          dailyHasValue[idx] = true;
          dailyMaxEvap[idx] = evap;
          dailyMaxTemp[idx] = temp;
        } else {
          if (evap > dailyMaxEvap[idx]) dailyMaxEvap[idx] = evap;
          if (temp > dailyMaxTemp[idx]) dailyMaxTemp[idx] = temp;
        }
      }

      // Hitung E berbasis pasangan H1 (maks hari sebelumnya) - H2 (maks hari ini).
      // Definisi sesuai permintaan: E untuk hari i = maxEvap(hari i-1) - maxEvap(hari i)
      // Mulai tanggal 21 Mei s/d sekarang: untuk hari pertama di rentang, nilainya 0
      final calibrated = List<double>.filled(days.length, 0.0);
      for (int i = 1; i < days.length; i++) {
        final e = dailyMaxEvap[i - 1] - dailyMaxEvap[i];
        calibrated[i] = e < 0 ? 0.0 : e;
      }

      values = calibrated;
      temps = dailyMaxTemp;
      labels = _buildLabels(days);

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