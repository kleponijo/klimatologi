import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';

part 'evaporasi_settings_event.dart';
part 'evaporasi_settings_state.dart';

class EvaporasiSettingsBloc extends Bloc<EvaporasiSettingsEvent, EvaporasiSettingsState> {
  final DatabaseReference _ref;

  static const _path = 'Monitoring/settings/evaporasi';
  static const _rtdbResetPath = 'Monitoring/reset_evaporasi';
  static const _rtdbRealtimePath = 'Monitoring/realtime/dmax_saat_ini';

  EvaporasiSettingsBloc({DatabaseReference? ref})
      : _ref = ref ?? FirebaseDatabase.instance.ref(_path),
        super(const EvaporasiSettingsState()) {
    on<EvaporasiSettingsStarted>(_onStarted);
    on<EvaporasiThresholdRendahChanged>(_onThresholdRendahChanged);
    on<EvaporasiThresholdTinggiChanged>(_onThresholdTinggiChanged);
    // rumusKalibrasi removed: calculation is handled on ESP32 hardware
    on<EvaporasiKoreksiOffsetChanged>(_onOffsetChanged);
    on<EvaporasiPumpStartChanged>(_onPumpStartChanged);
    on<EvaporasiPumpEndChanged>(_onPumpEndChanged);
    on<EvaporasiStandarTinggiChanged>(_onStandarTinggiChanged);
    on<EvaporasiBatasKritisChanged>(_onBatasKritisChanged);
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
          koreksiOffset: _toDouble(data['koreksi_offset'], 0.0),
          pumpStartTime: (data['pump_start_time'] as String?) ??
              (data['jam_pompa_mulai'] != null ? '${_toInt(data['jam_pompa_mulai'], 6).toString().padLeft(2, '0')}:00' : '06:00'),
          pumpEndTime: (data['pump_end_time'] as String?) ??
              (data['jam_pompa_selesai'] != null ? '${_toInt(data['jam_pompa_selesai'], 18).toString().padLeft(2, '0')}:00' : '18:00'),
          d0: _toInt(data['d0'], 0),
          dmaxManual: _toInt(data['dmax_manual'], 0),
          standarTinggiCm: _toDouble(data['standar_tinggi_cm'] ?? data['standar_tinggi'], 18.0),
          batasKritisCm: _toDouble(data['batas_kritis_cm'] ?? data['batas_kritis'], 15.0),
          intervalRealtime_ms: _toInt(data['interval_realtime_ms'], 300000),
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
          sensorError: _toBool(rt['sensor_error'], state.sensorError),
          ntpSync: _toBool(rt['ntp_sync'], state.ntpSync),
          snapshotCm: _toDouble(rt['snapshot_cm'] ?? rt['snapshot'], state.snapshotCm),
          standarTinggiCm: _toDouble(rt['standar_tinggi'] ?? rt['standar_tinggi_cm'], state.standarTinggiCm),
          batasKritisCm: _toDouble(rt['batas_kritis'] ?? rt['batas_kritis_cm'], state.batasKritisCm),
          tempCompActive: _toBool(rt['temp_comp_aktif'], state.tempCompActive),
          tempCompCoef: _toDouble(rt['temp_comp_koef'] ?? rt['tempCompKoef'] ?? 0.0, state.tempCompCoef),
          tempRefC: _toDouble(rt['temp_ref_c'] ?? rt['temp_ref'] ?? 0.0, state.tempRefC),
          otaTrigger: _toBool(rt['ota_trigger'], state.otaTrigger),
          relayAktif: _toBool(rt['selenoid'], state.relayAktif),
          historyCount: _toInt(rt['history_count'], state.historyCount),
          lastRealtime: _parseDateTime(rt['datetime']) ?? lastUpd,
          otaStatus: (rt['ota_status'] as String?) ?? state.otaStatus,
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

  // rumusKalibrasi handling removed — device firmware defines the formula

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

  void _onStandarTinggiChanged(
    EvaporasiStandarTinggiChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(standarTinggiCm: event.value));

  void _onBatasKritisChanged(
    EvaporasiBatasKritisChanged event,
    Emitter<EvaporasiSettingsState> emit,
  ) => emit(state.copyWith(batasKritisCm: event.value));

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
      final pumpStartHour = int.tryParse(state.pumpStartTime.split(':').first) ?? 0;
      final pumpEndHour = int.tryParse(state.pumpEndTime.split(':').first) ?? 0;
      await FirebaseDatabase.instance
          .ref('Monitoring/settings/kalibrasi')
          .update({
        'd0': state.d0,
        'dmax': state.dmaxManual,
      });
      await _ref.update({
        'threshold_rendah': state.thresholdRendah,
        'threshold_tinggi': state.thresholdTinggi,
        'koreksi_offset': state.koreksiOffset,
        'pump_start_time': state.pumpStartTime,
        'pump_end_time': state.pumpEndTime,
        'jam_pompa_mulai': pumpStartHour,
        'jam_pompa_selesai': pumpEndHour,
        'standar_tinggi_cm': state.standarTinggiCm,
        'batas_kritis_cm': state.batasKritisCm,
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

  double _toDouble(dynamic v, double def) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ?? def;
    }
    return def;
  }

  int _toInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? def;
    }
    return def;
  }

  bool _toBool(dynamic v, bool def) {
    if (v == null) return def;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final lower = v.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'aktif';
    }
    return def;
  }

  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt()).toLocal();
    if (raw is String) {
      final normalized = raw.replaceAll(' ', 'T');
      return DateTime.tryParse(normalized)?.toLocal();
    }
    return null;
  }
}
