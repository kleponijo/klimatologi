part of 'device_setup_bloc.dart';

enum DeviceSetupStatus {
  idle, // belum ada aksi
  checkingConn, // sedang cek koneksi ke ESP
  notConnected, // HP belum konek ke hotspot ESP
  connected, // HP sudah konek ke hotspot ESP, siap kirim
  sending, // sedang kirim SSID+password ke ESP
  success, // ESP berhasil terima & akan restart
  failure, // gagal (timeout, ESP tidak respond, dll)
  // Settings
  settingsLoading,
  settingsLoaded,
  settingsSaving,
  settingsSaved,
  settingsError,
}

class DeviceSetupState {
  final DeviceSetupStatus status;
  final String? errorMessage;
  final String? successMessage;
  final String espIp;
  // ── Sensor settings ──────────────────────────────────────────
  /// ID device aktif — menentukan path Firebase yang dibaca app.
  /// Default 'esp_lapangan' (ESP utama di lapangan).
  /// Disimpan lokal di SharedPreferences.
  final String deviceId;

  /// Konstanta kalibrasi. Default 50.0 (hasil estimasi vs AWS).
  final double kFaktor;

  /// Jari-jari lengan anemometer dalam meter. Default 0.08 (8 cm).
  final double radiusM;

  /// Interval pengiriman realtime ke Firebase (ms). Default 1000 = 1 detik.
  final int intervalRealtimeMs;

  /// Interval push history ke Firebase (ms). Default 3600000 = 1 jam.
  final int intervalHistoryMs;

  // ── Logs ─────────────────────────────────────────────────────
  final List<Map<String, dynamic>> logs;
  final bool logsLoading;

  const DeviceSetupState({
    this.status = DeviceSetupStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.espIp = '192.168.4.1', // default IP ESP saat AP mode
    // Settings — default sama dengan cfg_config.h di ESP
    this.deviceId = 'esp_lapangan',
    this.kFaktor = 50.0,
    this.radiusM = 0.08,
    this.intervalRealtimeMs = 1000,
    this.intervalHistoryMs = 3600000,
    // Logs
    this.logs = const [],
    this.logsLoading = false,
  });

  DeviceSetupState copyWith({
    DeviceSetupStatus? status,
    String? errorMessage,
    String? successMessage,
    String? espIp,
    String? deviceId,
    double? kFaktor,
    double? radiusM,
    int? intervalRealtimeMs,
    int? intervalHistoryMs,
    List<Map<String, dynamic>>? logs,
    bool? logsLoading,
  }) {
    return DeviceSetupState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      espIp: espIp ?? this.espIp,
      deviceId: deviceId ?? this.deviceId,
      kFaktor: kFaktor ?? this.kFaktor,
      radiusM: radiusM ?? this.radiusM,
      intervalRealtimeMs: intervalRealtimeMs ?? this.intervalRealtimeMs,
      intervalHistoryMs: intervalHistoryMs ?? this.intervalHistoryMs,
      logs: logs ?? this.logs,
      logsLoading: logsLoading ?? this.logsLoading,
    );
  }
}
