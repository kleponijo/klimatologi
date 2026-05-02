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
