import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';

part 'evaporasi_settings_event.dart';
part 'evaporasi_settings_state.dart';

class EvaporasiSettingsBloc extends Bloc<EvaporasiSettingsEvent, EvaporasiSettingsState> {
  final DatabaseReference _ref;

  static const _path = 'Monitoring/settings/evaporasi';
  static const _rtdbResetPath = 'Monitoring/reset_dmax';
  static const _rtdbRealtimePath = 'Monitoring/realtime/dmax_saat_ini';

  EvaporasiSettingsBloc({DatabaseReference? ref})
      : _ref = ref ?? FirebaseDatabase.instance.ref(_path),
        super(const EvaporasiSettingsState()) {
    on<EvaporasiSettingsStarted>(_onStarted);
    on<EvaporasiThresholdRendahChanged>(_onThresholdRendahChanged);
    on<EvaporasiThresholdTinggiChanged>(_onThresholdTinggiChanged);
    on<EvaporasiRumusKalibrasiChanged>(_onRumusChanged);
    on<EvaporasiKoreksiOffsetChanged>(_onOffsetChanged);
    on<EvaporasiPumpStartChanged>(_onPumpStartChanged);
    on<EvaporasiPumpEndChanged>(_onPumpEndChanged);
    on<EvaporasiD0Changed>(_onD0Changed);
    on<EvaporasiDmaxManualChanged>(_onDmaxManualChanged);
    on<EvaporasiIntervalRealtimeChanged>(_onIntervalRealtimeChanged);
    on<EvaporasiIntervalHistoryChanged>(_onIntervalHistoryChanged);
    on<EvaporasiIntervalBacaChanged>(_onIntervalBacaChanged);
    on<EvaporasiDmaxResetRequested>(_onDmaxReset);
    on<EvaporasiSettingsSaved>(_onSaved);
  }

  Future<void> _onStarted(
    EvaporasiSettingsStarted event,
    Emitter<EvaporasiSettingsState> emit,
  ) async {
    emit(state.copyWith(status: EvaporasiSettingsStatus.loading));
    try {
      final snap = await _ref.get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        emit(state.copyWith(
          thresholdRendah: _toDouble(data['threshold_rendah'], 2.0),
          thresholdTinggi: _toDouble(data['threshold_tinggi'], 10.0),
          rumusKalibrasi: (data['rumus_kalibrasi'] as String?) ?? 'selisih_max',
          koreksiOffset: _toDouble(data['koreksi_offset'], 0.0),          pumpStartTime: (data['pump_start_time'] as String?) ?? '06:00',
          pumpEndTime: (data['pump_end_time'] as String?) ?? '18:00',
          d0: _toInt(data['d0'], 0),
          dmaxManual: _toInt(data['dmax_manual'], 0),          intervalRealtime_ms: _toInt(data['interval_realtime_ms'], 300000),
          intervalHistory_ms: _toInt(data['interval_history_ms'], 600000),
          intervalBaca_ms: _toInt(data['interval_baca_ms'], 10000),
          status: EvaporasiSettingsStatus.loaded,
        ));
      } else {
        emit(state.copyWith(status: EvaporasiSettingsStatus.loaded));
      }
    } catch (e) {
      emit(state.copyWith(
        status: EvaporasiSettingsStatus.error,
        errorMessage: e.toString(),
      ));
      return;
    }

    try {
      final rtRef = FirebaseDatabase.instance.ref('Monitoring/realtime');
      final rtSnap = await rtRef.get();
      if (rtSnap.exists && rtSnap.value != null) {
        final rt = Map<String, dynamic>.from(rtSnap.value as Map);
        final val = _toInt(rt['dmax_saat_ini'], 0);
        final firmware = (rt['firmware_version'] as String?) ?? '--';
        final wifi = rt['wifi_connected'] is bool ? (rt['wifi_connected'] as bool) : (rt['wifi_connected'] == 1);
        final firebase = rt['firebase_connected'] is bool ? (rt['firebase_connected'] as bool) : (rt['firebase_connected'] == 1);
        final activeD0 = _toInt(rt['d0_active'], state.d0);
        final activeDmax = _toInt(rt['dmax_active'], val);
        DateTime? lastUpd;
        try {
          final lu = rt['last_update'];
          if (lu != null) {
            final ms = (lu is num) ? lu.toInt() : int.tryParse(lu.toString()) ?? 0;
            if (ms > 0) lastUpd = DateTime.fromMillisecondsSinceEpoch(ms);
          }
        } catch (_) {}

        emit(state.copyWith(
          dmax: val,
          firmwareVersion: firmware,
          wifiConnected: wifi ?? false,
          firebaseConnected: firebase ?? false,
          activeD0: activeD0,
          activeDmax: activeDmax,
          lastUpdate: lastUpd,
        ));
      } else {
        // fallback: try single path
        final snap = await FirebaseDatabase.instance.ref(_rtdbRealtimePath).get();
        final val = snap.exists ? (snap.value as num?)?.toInt() ?? 0 : 0;
        emit(state.copyWith(dmax: val));
      }
    } catch (_) {
      // ignore: avoid_catching_errors
    }
  }

  void _onThresholdRendahChanged(
    EvaporasiThresholdRendahChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(thresholdRendah: event.value));

  void _onThresholdTinggiChanged(
    EvaporasiThresholdTinggiChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(thresholdTinggi: event.value));

  void _onRumusChanged(
    EvaporasiRumusKalibrasiChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(rumusKalibrasi: event.rumus));

  void _onOffsetChanged(
    EvaporasiKoreksiOffsetChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(koreksiOffset: event.value));

  void _onIntervalRealtimeChanged(
    EvaporasiIntervalRealtimeChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(intervalRealtime_ms: event.value));

  void _onIntervalHistoryChanged(
    EvaporasiIntervalHistoryChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(intervalHistory_ms: event.value));

  void _onIntervalBacaChanged(
    EvaporasiIntervalBacaChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(intervalBaca_ms: event.value));

  void _onPumpStartChanged(
    EvaporasiPumpStartChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(pumpStartTime: event.value));

  void _onPumpEndChanged(
    EvaporasiPumpEndChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(pumpEndTime: event.value));

  void _onD0Changed(
    EvaporasiD0Changed event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(d0: event.value));

  void _onDmaxManualChanged(
    EvaporasiDmaxManualChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(dmaxManual: event.value));

  Future<void> _onDmaxReset(
    EvaporasiDmaxResetRequested event,
    Emitter<EvaporasiSettingsState> emit,
  ) async {
    emit(state.copyWith(isResettingDmax: true));
    try {
      await FirebaseDatabase.instance.ref(_rtdbResetPath).set(true);
      await Future.delayed(const Duration(seconds: 6));
      final snap = await FirebaseDatabase.instance.ref(_rtdbRealtimePath).get();
      final newDmax = snap.exists ? (snap.value as num?)?.toInt() ?? 0 : 0;
      emit(state.copyWith(dmax: newDmax, isResettingDmax: false));
    } catch (e) {
      emit(state.copyWith(isResettingDmax: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSaved(
    EvaporasiSettingsSaved event,
    Emitter<EvaporasiSettingsState> emit,
  ) async {
    if (state.thresholdRendah >= state.thresholdTinggi) {
      emit(state.copyWith(
        status: EvaporasiSettingsStatus.error,
        errorMessage: 'Batas Rendah harus lebih kecil dari batas Tinggi.',
      ));
      return;
    }

    emit(state.copyWith(status: EvaporasiSettingsStatus.saving));
    try {
      await _ref.set({
        'threshold_rendah': state.thresholdRendah,
        'threshold_tinggi': state.thresholdTinggi,
        'rumus_kalibrasi': state.rumusKalibrasi,
        'koreksi_offset': state.koreksiOffset,
        'pump_start_time': state.pumpStartTime,
        'pump_end_time': state.pumpEndTime,
        'd0': state.d0,
        'dmax_manual': state.dmaxManual,
        'interval_realtime_ms': state.intervalRealtime_ms,
        'interval_history_ms': state.intervalHistory_ms,
        'interval_baca_ms': state.intervalBaca_ms,
        'updated_at': ServerValue.timestamp,
      });
      emit(state.copyWith(status: EvaporasiSettingsStatus.saved));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: EvaporasiSettingsStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: EvaporasiSettingsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  double _toDouble(dynamic v, double def) => v == null ? def : (v as num).toDouble();

  int _toInt(dynamic v, int def) => v == null ? def : (v as num).toInt();
}
