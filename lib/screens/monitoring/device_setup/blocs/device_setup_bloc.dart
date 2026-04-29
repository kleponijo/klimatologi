import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';

part 'device_setup_event.dart';
part 'device_setup_state.dart';

class DeviceSetupBloc extends Bloc<DeviceSetupEvent, DeviceSetupState> {
  DeviceSetupBloc() : super(const DeviceSetupState()) {
    on<CheckEspConnectionEvent>(_onCheckConnection);
    on<SendWifiCredentialsEvent>(_onSendCredentials);
    on<ResetDeviceSetupEvent>(_onReset);
  }

  // ── Dio instance khusus untuk komunikasi ke ESP ──────────────
  // Timeout pendek karena ESP di jaringan lokal, harusnya cepat.
  // Kalau timeout → berarti HP belum konek ke hotspot ESP.
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
    ),
  );

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
          e.type == DioExceptionType.connectionError) {
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

  // ── Reset state ───────────────────────────────────────────────
  void _onReset(
    ResetDeviceSetupEvent event,
    Emitter<DeviceSetupState> emit,
  ) {
    emit(const DeviceSetupState());
  }
}
