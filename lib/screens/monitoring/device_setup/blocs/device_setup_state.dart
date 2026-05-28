part of 'device_setup_bloc.dart';

enum DeviceSetupStatus {
  idle,
  checkingConn,
  notConnected,
  connected,
  sending,
  success,
  failure,
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

  final String deviceId;
  final double kFaktor;
  final double radiusM;
  final int intervalRealtimeMs;
  final int intervalHistoryMs;

  /// Jumlah magnet pada anemometer. 1 = default, 3 = resolusi lebih tinggi.
  /// Disimpan di Firebase: /anemometer/settings/magnet_count
  final int magnetCount;

  final List<Map<String, dynamic>> logs;
  final bool logsLoading;

  const DeviceSetupState({
    this.status = DeviceSetupStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.espIp = '192.168.4.1',
    this.deviceId = 'esp_lapangan',
    this.kFaktor = 50.0,
    this.radiusM = 0.08,
    this.intervalRealtimeMs = 1000,
    this.intervalHistoryMs = 3600000,
    this.magnetCount = 1, // ← default 1 magnet
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
    int? magnetCount,
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
      magnetCount: magnetCount ?? this.magnetCount,
      logs: logs ?? this.logs,
      logsLoading: logsLoading ?? this.logsLoading,
    );
  }
}
