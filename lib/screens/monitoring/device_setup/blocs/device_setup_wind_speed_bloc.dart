// device_setup_wind_speed_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

part 'device_setup_event.dart';
part 'device_setup_state.dart';

const _kDeviceIdKey = 'selected_device_id';

class DeviceSetupBloc extends Bloc<DeviceSetupEvent, DeviceSetupState> {
  final MonitoringRepository _repository;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 5),
  ));

  DeviceSetupBloc({required MonitoringRepository repository})
      : _repository = repository,
        super(const DeviceSetupState()) {
    on<CheckEspConnectionEvent>(_onCheckConnection);
    on<SendWifiCredentialsEvent>(_onSendCredentials);
    on<ResetDeviceSetupEvent>(_onReset);
    // Settings
    on<DeviceSettingsStarted>(_onSettingsStarted);
    on<DeviceIdChanged>(_onDeviceIdChanged);
    on<IntervalRealtimeChanged>(
        (e, emit) => emit(state.copyWith(intervalRealtimeMs: e.ms)));
    on<IntervalAverageChanged>(
        (e, emit) => emit(state.copyWith(intervalAverageMs: e.ms)));
    on<IntervalHistoryChanged>(
        (e, emit) => emit(state.copyWith(intervalHistoryMs: e.ms)));
    on<MagnetCountChanged>(
        (e, emit) => emit(state.copyWith(magnetCount: e.count)));
    on<DeviceSettingsSaved>(_onSettingsSaved);
    on<DeviceLogsRefreshed>(_onLogsRefreshed);
    on<DeviceRestartRequested>(_onRestartRequested);
    on<LogSelectModeToggled>(_onSelectModeToggled);
    on<LogItemToggled>(_onLogItemToggled);
    on<LogSelectAllToggled>(_onLogSelectAllToggled);
    on<LogsDeleteRequested>(_onLogsDeleteRequested);
  }

  // ════════════════════════════════════════════════════════════
  //  Settings
  // ════════════════════════════════════════════════════════════

  Future<void> _onSettingsStarted(
    DeviceSettingsStarted event,
    Emitter<DeviceSetupState> emit,
  ) async {
    emit(state.copyWith(status: DeviceSetupStatus.settingsLoading));
    try {
      // Baca device ID tersimpan lokal
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kDeviceIdKey) ?? state.deviceId;
      final s = await _repository.getAnemometerSettings();
      final logs = await _repository.getDeviceLogs(savedId);

      emit(state.copyWith(
        status: DeviceSetupStatus.settingsLoaded,
        deviceId: savedId,
        intervalRealtimeMs: s['interval_realtime_ms'] as int,
        intervalAverageMs: s['interval_average_ms'] as int,
        intervalHistoryMs: s['interval_history_ms'] as int,
        magnetCount: (s['magnet_count'] as int?) ?? 1,
        logs: logs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DeviceSetupStatus.settingsError,
        errorMessage: 'Gagal memuat settings: $e',
      ));
    }
  }

  Future<void> _onDeviceIdChanged(
    DeviceIdChanged event,
    Emitter<DeviceSetupState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceIdKey, event.deviceId);

    // Muat log device baru
    emit(state.copyWith(
      deviceId: event.deviceId,
      logsLoading: true,
    ));
    final logs = await _repository.getDeviceLogs(event.deviceId);
    emit(state.copyWith(logs: logs, logsLoading: false));
  }

  Future<void> _onSettingsSaved(
    DeviceSettingsSaved event,
    Emitter<DeviceSetupState> emit,
  ) async {
    emit(state.copyWith(status: DeviceSetupStatus.settingsSaving));
    try {
      await _repository.updateAnemometerSettings(
        intervalRealtimeMs: state.intervalRealtimeMs,
        intervalAverageMs: state.intervalAverageMs,
        intervalHistoryMs: state.intervalHistoryMs,
        magnetCount: state.magnetCount,
      );
      emit(state.copyWith(status: DeviceSetupStatus.settingsSaved));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: DeviceSetupStatus.settingsLoaded));
    } catch (e) {
      emit(state.copyWith(
        status: DeviceSetupStatus.settingsError,
        errorMessage: 'Gagal menyimpan: $e',
      ));
    }
  }

  Future<void> _onLogsRefreshed(
    DeviceLogsRefreshed event,
    Emitter<DeviceSetupState> emit,
  ) async {
    emit(state.copyWith(logsLoading: true));
    final logs = await _repository.getDeviceLogs(state.deviceId);
    emit(state.copyWith(logs: logs, logsLoading: false));
  }

  // ════════════════════════════════════════════════════════════
  //  WiFi Setup (existing logic, tidak berubah)
  // ════════════════════════════════════════════════════════════

  // ── Cek koneksi ke ESP ────────────────────────────────────────
  Future<void> _onCheckConnection(
    CheckEspConnectionEvent event,
    Emitter<DeviceSetupState> emit,
  ) async {
    emit(state.copyWith(status: DeviceSetupStatus.checkingConn));

    try {
      // Ping endpoint root ESP — kalau respond berarti HP sudah
      // terhubung ke hotspot ESP (192.168.4.1)
      final response = await _dio.get(
        'http://${state.espIp}/',
        options: Options(
          // Terima semua status code, yang penting server respond
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode != null) {
        emit(state.copyWith(status: DeviceSetupStatus.connected));
      } else {
        emit(state.copyWith(
          status: DeviceSetupStatus.notConnected,
          errorMessage:
              'ESP tidak merespons. Pastikan HP sudah terhubung ke hotspot "Anemometer-Setup".',
        ));
      }
    } on DioException catch (e) {
      String msg = 'Tidak bisa terhubung ke ESP.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        msg =
            'Koneksi timeout. Pastikan HP terhubung ke hotspot "Anemometer-Setup" dan coba lagi.';
      } else if (e.type == DioExceptionType.connectionError) {
        msg =
            'Tidak ada koneksi ke ESP. Sambungkan HP ke hotspot "Anemometer-Setup" terlebih dahulu.';
      }
      emit(state.copyWith(
        status: DeviceSetupStatus.notConnected,
        errorMessage: msg,
      ));
    }
  }

  // ── Kirim SSID + Password ke ESP ─────────────────────────────
  Future<void> _onSendCredentials(
    SendWifiCredentialsEvent event,
    Emitter<DeviceSetupState> emit,
  ) async {
    if (event.ssid.trim().isEmpty) {
      emit(state.copyWith(
        status: DeviceSetupStatus.failure,
        errorMessage: 'SSID tidak boleh kosong.',
      ));
      return;
    }

    emit(state.copyWith(status: DeviceSetupStatus.sending));

    try {
      // Kirim sebagai form-urlencoded — sama persis dengan
      // yang diterima WebServer ESP di route POST /save
      final response = await _dio.post(
        'http://${state.espIp}/save',
        data: {
          'ssid': event.ssid.trim(),
          'pass': event.password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        emit(state.copyWith(
          status: DeviceSetupStatus.success,
          successMessage:
              'Berhasil! ESP menyimpan WiFi "${event.ssid}" dan akan restart otomatis.\n\n'
              'Tunggu beberapa detik, lalu sambungkan HP kembali ke WiFi normal.',
        ));
      } else {
        emit(state.copyWith(
          status: DeviceSetupStatus.failure,
          errorMessage:
              'ESP menolak permintaan (${response.statusCode}): ${response.data}',
        ));
      }
    } on DioException catch (e) {
      // ESP restart setelah terima kredensial → koneksi putus → itu normal!
      // DioException di sini kemungkinan besar karena ESP sudah restart.
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout) {
        emit(state.copyWith(
          status: DeviceSetupStatus.success,
          successMessage:
              'ESP menerima konfigurasi WiFi dan sedang restart.\n\n'
              'Sambungkan HP kembali ke WiFi normal dalam beberapa detik.',
        ));
      } else {
        emit(state.copyWith(
          status: DeviceSetupStatus.failure,
          errorMessage: 'Gagal mengirim ke ESP: ${e.message}',
        ));
      }
    }
  }

  Future<void> _onRestartRequested(
    DeviceRestartRequested event,
    Emitter<DeviceSetupState> emit,
  ) async {
    try {
      await _repository.sendRemoteRestart(state.deviceId);
      emit(state.copyWith(status: DeviceSetupStatus.settingsSaved));
      // Reuse status settingsSaved untuk snackbar — atau bisa buat status baru
    } catch (e) {
      emit(state.copyWith(
        status: DeviceSetupStatus.settingsError,
        errorMessage: 'Gagal kirim restart: $e',
      ));
    }
  }

  void _onSelectModeToggled(
    LogSelectModeToggled event,
    Emitter<DeviceSetupState> emit,
  ) {
    emit(state.copyWith(
      isSelecting: !state.isSelecting,
      selectedLogKeys: {}, // reset pilihan saat toggle mode
    ));
  }

  void _onLogItemToggled(
    LogItemToggled event,
    Emitter<DeviceSetupState> emit,
  ) {
    final current = Set<String>.from(state.selectedLogKeys);
    if (current.contains(event.key)) {
      current.remove(event.key);
    } else {
      current.add(event.key);
    }
    emit(state.copyWith(selectedLogKeys: current));
  }

  void _onLogSelectAllToggled(
    LogSelectAllToggled event,
    Emitter<DeviceSetupState> emit,
  ) {
    if (state.allSelected) {
      // Sudah semua terpilih → batalkan semua
      emit(state.copyWith(selectedLogKeys: {}));
    } else {
      // Pilih semua — ambil semua '_key' dari logs
      final allKeys = state.logs.map((e) => e['_key'] as String).toSet();
      emit(state.copyWith(selectedLogKeys: allKeys));
    }
  }

  Future<void> _onLogsDeleteRequested(
    LogsDeleteRequested event,
    Emitter<DeviceSetupState> emit,
  ) async {
    if (state.selectedLogKeys.isEmpty) return;

    emit(state.copyWith(logsLoading: true));

    try {
      await _repository.deleteDeviceLogs(
        state.deviceId,
        state.selectedLogKeys.toList(),
      );

      // Refresh logs setelah delete
      final logs = await _repository.getDeviceLogs(state.deviceId);
      emit(state.copyWith(
        logs: logs,
        logsLoading: false,
        selectedLogKeys: {},
        isSelecting: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        logsLoading: false,
        status: DeviceSetupStatus.settingsError,
        errorMessage: 'Gagal hapus log: $e',
      ));
    }
  }

  // ── Reset state ───────────────────────────────────────────────
  void _onReset(
    ResetDeviceSetupEvent event,
    Emitter<DeviceSetupState> emit,
  ) {
    emit(DeviceSetupState(
      deviceId: state.deviceId,
      intervalRealtimeMs: state.intervalRealtimeMs,
      intervalAverageMs: state.intervalAverageMs,
      intervalHistoryMs: state.intervalHistoryMs,
    ));
  }
}
