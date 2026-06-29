part of 'device_setup_wind_speed_bloc.dart';

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
  final int intervalRealtimeMs;
  final int intervalAverageMs;
  final int intervalHistoryMs;
  final int magnetCount;
  final List<Map<String, dynamic>> logs;
  final bool logsLoading;
  final Set<String> selectedLogKeys;
  final bool isSelecting;

  const DeviceSetupState({
    this.status = DeviceSetupStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.espIp = '192.168.4.1',
    this.deviceId = 'esp_lapangan',
    this.intervalRealtimeMs = 1000,
    this.intervalAverageMs = 60000,
    this.intervalHistoryMs = 3600000,
    this.magnetCount = 1, // ← default 1 magnet
    this.logs = const [],
    this.logsLoading = false,
    this.selectedLogKeys = const {},
    this.isSelecting = false,
  });

  bool get allSelected =>
      logs.isNotEmpty && selectedLogKeys.length == logs.length;

  DeviceSetupState copyWith({
    DeviceSetupStatus? status,
    String? errorMessage,
    String? successMessage,
    String? espIp,
    String? deviceId,
    int? intervalRealtimeMs,
    int? intervalAverageMs,
    int? intervalHistoryMs,
    int? magnetCount,
    List<Map<String, dynamic>>? logs,
    bool? logsLoading,
    Set<String>? selectedLogKeys,
    bool? isSelecting,
  }) {
    return DeviceSetupState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      espIp: espIp ?? this.espIp,
      deviceId: deviceId ?? this.deviceId,
      intervalRealtimeMs: intervalRealtimeMs ?? this.intervalRealtimeMs,
      intervalAverageMs: intervalAverageMs ?? this.intervalAverageMs,
      intervalHistoryMs: intervalHistoryMs ?? this.intervalHistoryMs,
      magnetCount: magnetCount ?? this.magnetCount,
      logs: logs ?? this.logs,
      logsLoading: logsLoading ?? this.logsLoading,
      selectedLogKeys: selectedLogKeys ?? this.selectedLogKeys,
      isSelecting: isSelecting ?? this.isSelecting,
    );
  }
}
