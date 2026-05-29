part of 'device_setup_bloc.dart';

abstract class DeviceSetupEvent {}

class CheckEspConnectionEvent extends DeviceSetupEvent {}

class SendWifiCredentialsEvent extends DeviceSetupEvent {
  final String ssid;
  final String password;
  SendWifiCredentialsEvent({required this.ssid, required this.password});
}

class ResetDeviceSetupEvent extends DeviceSetupEvent {}

class DeviceSettingsStarted extends DeviceSetupEvent {}

class DeviceIdChanged extends DeviceSetupEvent {
  final String deviceId;
  DeviceIdChanged(this.deviceId);
}

class KFaktorChanged extends DeviceSetupEvent {
  final double value;
  KFaktorChanged(this.value);
}

class RadiusChanged extends DeviceSetupEvent {
  final double value;
  RadiusChanged(this.value);
}

class IntervalRealtimeChanged extends DeviceSetupEvent {
  final int ms;
  IntervalRealtimeChanged(this.ms);
}

class IntervalHistoryChanged extends DeviceSetupEvent {
  final int ms;
  IntervalHistoryChanged(this.ms);
}

/// User ubah jumlah magnet (1 atau 3)
class MagnetCountChanged extends DeviceSetupEvent {
  final int count;
  MagnetCountChanged(this.count);
}

class DeviceSettingsSaved extends DeviceSetupEvent {}

class DeviceLogsRefreshed extends DeviceSetupEvent {}

class DeviceRestartRequested extends DeviceSetupEvent {}

class LogSelectModeToggled extends DeviceSetupEvent {}

class LogItemToggled extends DeviceSetupEvent {
  final String key;
  LogItemToggled(this.key);
}

class LogSelectAllToggled extends DeviceSetupEvent {}

class LogsDeleteRequested extends DeviceSetupEvent {}
