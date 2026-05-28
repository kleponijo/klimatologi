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
          koreksiOffset: _toDouble(data['koreksi_offset'], 0.0),
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
      final rtSnap = await FirebaseDatabase.instance.ref(_rtdbRealtimePath).get();
      final val = rtSnap.exists ? (rtSnap.value as num?)?.toInt() ?? 0 : 0;
      emit(state.copyWith(dmax: val));
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
