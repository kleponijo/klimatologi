import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

import '../../../../core/utils/time_series_mapper.dart';
import '../../../../core/notification_notifier.dart';

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
    _updateGlobalNotifier(status, rain);

    emit(state.copyWith(
      history: history,
      dailyValues: dailyGraph,
      dailyTemperatures: dailyTempGraph,
      weatherStatus: status,
      willRain: rain,
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
    final updatedTemp = List<double>.from(state.dailyTemperatures);

    final index = DateTime.now().hour;

    if (index < updated.length) {
      updated[index] = event.data.evaporasi;
      updatedTemp[index] = event.data.suhu;
    }

    final (status, rain) = _computeWeatherStatus(event.data.evaporasi);
    _updateGlobalNotifier(status, rain);

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
      isLoading: false,
    ));
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
    if (value <= 5.0) {
      return ("Baik", false);
    } else if (value > 5.0 && value <= 10.0) {
      return ("Sedang", true);
    } else {
      return ("Buruk", true);
    }
  }

  static void _updateGlobalNotifier(String status, bool willRain) {
    hasWeatherAlert.value = willRain;
    if (willRain) {
      weatherAlertMessage.value =
          'Status evaporasi $status — potensi hujan tinggi';
    } else {
      weatherAlertMessage.value = '';
    }
  }
}

/// INTERNAL EVENT
class _EvaporasiRealtimeUpdated extends EvaporasiEvent {
  final Evaporasi data;

  const _EvaporasiRealtimeUpdated(this.data);

  @override
  List<Object> get props => [data];
}
