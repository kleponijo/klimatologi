part of 'device_setup_bloc.dart';

abstract class DeviceSetupEvent {}

/// Cek apakah HP sedang terhubung ke hotspot ESP
class CheckEspConnectionEvent extends DeviceSetupEvent {}

/// Kirim SSID + password baru ke ESP via HTTP
class SendWifiCredentialsEvent extends DeviceSetupEvent {
  final String ssid;
  final String password;

  SendWifiCredentialsEvent({required this.ssid, required this.password});
}

/// Reset state ke awal (misalnya saat user keluar screen)
class ResetDeviceSetupEvent extends DeviceSetupEvent {}

// ── Sensor Settings events (new) ─────────────────────────────

/// Load device ID dari SharedPreferences + settings dari Firebase
class DeviceSettingsStarted extends DeviceSetupEvent {}

/// User pilih/ubah device ID (misal: esp_percobaan → esp_lapangan)
class DeviceIdChanged extends DeviceSetupEvent {
  final String deviceId;
  DeviceIdChanged(this.deviceId);
}

/// User ubah k_faktor di form
class KFaktorChanged extends DeviceSetupEvent {
  final double value;
  KFaktorChanged(this.value);
}

/// User ubah radius_m di form
class RadiusChanged extends DeviceSetupEvent {
  final double value;
  RadiusChanged(this.value);
}

/// User ubah interval realtime (ms)
class IntervalRealtimeChanged extends DeviceSetupEvent {
  final int ms;
  IntervalRealtimeChanged(this.ms);
}

/// User ubah interval history (ms)
class IntervalHistoryChanged extends DeviceSetupEvent {
  final int ms;
  IntervalHistoryChanged(this.ms);
}

/// Simpan settings ke Firebase
class DeviceSettingsSaved extends DeviceSetupEvent {}

/// Refresh logs dari Firebase
class DeviceLogsRefreshed extends DeviceSetupEvent {}
