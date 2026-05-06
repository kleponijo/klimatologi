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
      'Monitoring/History',
      (json) => Evaporasi.fromJson(json),
      orderByChild: null, // waktu = string, tidak bisa orderByChild
      limit: 500,
    );

    final dailyGraph =
        TimeSeriesMapper.dailyFrom<Evaporasi>(history, (e) => e.evaporasi);
    final dailyTempGraph =
        TimeSeriesMapper.dailyFrom<Evaporasi>(history, (e) => e.suhu);
    final weeklyGraph =
        TimeSeriesMapper.weeklyFrom<Evaporasi>(history, (e) => e.evaporasi);
    final monthlyGraph =
        TimeSeriesMapper.monthlyFrom<Evaporasi>(history, (e) => e.evaporasi);
    final weeklyTemp =
        TimeSeriesMapper.weeklyFrom<Evaporasi>(history, (e) => e.suhu);
    final monthlyTemp =
        TimeSeriesMapper.monthlyFrom<Evaporasi>(history, (e) => e.suhu);

    // Hitung status dari data terakhir history jika ada
    final lastValue = history.isNotEmpty ? history.last.evaporasi : 0.0;
    final (status, rain) = _computeWeatherStatus(lastValue);
    _emitEvaporasiAlert(status, lastValue);

    emit(state.copyWith(
      history: history,
      dailyValues: dailyGraph,
      dailyTemperatures: dailyTempGraph,
      weatherStatus: status,
      willRain: rain,
      isLoading: false,
      weeklyValues: weeklyGraph,
      monthlyValues: monthlyGraph,
      weeklyTemperatures: weeklyTemp,
      monthlyTemperatures: monthlyTemp,
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
    _emitEvaporasiAlert(status, event.data.evaporasi);

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
  void _onPeriodChanged(
    EvaporasiPeriodChanged event,
    Emitter<EvaporasiState> emit,
  ) {
    emit(state.copyWith(selectedPeriod: event.period));
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

  void _emitEvaporasiAlert(String status, double value) {
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
