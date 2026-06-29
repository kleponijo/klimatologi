part of 'device_setup_wind_speed_bloc.dart';

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

class IntervalRealtimeChanged extends DeviceSetupEvent {
  final int ms;
  IntervalRealtimeChanged(this.ms);
}

class IntervalAverageChanged extends DeviceSetupEvent {
  final int ms;
  IntervalAverageChanged(this.ms);
}

class IntervalHistoryChanged extends DeviceSetupEvent {
  final int ms;
  IntervalHistoryChanged(this.ms);
}

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
