part of 'device_setup_bloc.dart';

enum DeviceSetupStatus {
  idle, // belum ada aksi
  checkingConn, // sedang cek koneksi ke ESP
  notConnected, // HP belum konek ke hotspot ESP
  connected, // HP sudah konek ke hotspot ESP, siap kirim
  sending, // sedang kirim SSID+password ke ESP
  success, // ESP berhasil terima & akan restart
  failure, // gagal (timeout, ESP tidak respond, dll)
}

class DeviceSetupState {
  final DeviceSetupStatus status;
  final String? errorMessage;
  final String? successMessage;
  final String espIp;

  const DeviceSetupState({
    this.status = DeviceSetupStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.espIp = '192.168.4.1', // default IP ESP saat AP mode
  });

  DeviceSetupState copyWith({
    DeviceSetupStatus? status,
    String? errorMessage,
    String? successMessage,
    String? espIp,
  }) {
    return DeviceSetupState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      espIp: espIp ?? this.espIp,
    );
  }
}
