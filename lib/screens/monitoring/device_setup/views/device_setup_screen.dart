import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import 'package:app_settings/app_settings.dart';
import '../blocs/device_setup_bloc.dart';

// ── Opsi device yang tersedia ─────────────────────────────────
const _kDeviceOptions = ['esp_lapangan', 'esp_percobaan'];

// ── Opsi interval realtime ────────────────────────────────────
const _kRealtimeOptions = <String, int>{
  '1 detik': 1000,
  '5 detik': 5000,
  '30 detik': 30000,
  '1 menit': 60000,
  '1 jam': 3600000,
};

// ── Opsi interval history ─────────────────────────────────────
const _kHistoryOptions = <String, int>{
  '10 menit': 600000,
  '30 menit': 1800000,
  '1 jam': 3600000,
  '6 jam': 21600000,
  '24 jam': 86400000,
};

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // WiFi form controllers
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Settings form controllers
  final _kFaktorController = TextEditingController();
  final _radiusController = TextEditingController();
  String? _customDeviceId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _kFaktorController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  // ── Sync text controllers dengan state saat settings loaded ──
  void _syncControllers(DeviceSetupState state) {
    if (_kFaktorController.text != state.kFaktor.toString()) {
      _kFaktorController.text = state.kFaktor.toStringAsFixed(2);
    }
    if (_radiusController.text != state.radiusM.toString()) {
      _radiusController.text = state.radiusM.toStringAsFixed(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeviceSetupBloc(
        repository: context.read<MonitoringRepository>(),
      )..add(DeviceSettingsStarted()),
      child: BlocConsumer<DeviceSetupBloc, DeviceSetupState>(
        listener: (context, state) {
          // WiFi success/failure dialog
          if (state.status == DeviceSetupStatus.success &&
              state.successMessage != null) {
            _showResultDialog(context,
                success: true, message: state.successMessage!);
          }
          if (state.status == DeviceSetupStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ));
          }
          // Settings saved snackbar
          if (state.status == DeviceSetupStatus.settingsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Settings disimpan! ESP akan baca dalam ~5 menit.'),
              ]),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
          // Sync controllers saat data loaded
          if (state.status == DeviceSetupStatus.settingsLoaded) {
            _syncControllers(state);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text('Pengaturan Perangkat',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              elevation: 0,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: Colors.blue.shade700,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.tune_rounded), text: 'Sensor'),
                  Tab(icon: Icon(Icons.wifi_rounded), text: 'WiFi ESP'),
                  Tab(icon: Icon(Icons.terminal_rounded), text: 'Log'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _SensorSettingsTab(
                  state: state,
                  kFaktorController: _kFaktorController,
                  radiusController: _radiusController,
                  customDeviceId: _customDeviceId,
                  onCustomDeviceIdChanged: (v) =>
                      setState(() => _customDeviceId = v),
                ),
                _WifiSetupTab(
                  state: state,
                  ssidController: _ssidController,
                  passwordController: _passwordController,
                  formKey: _formKey,
                  obscurePassword: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onShowResultDialog: (success, msg) => _showResultDialog(
                      context,
                      success: success,
                      message: msg),
                ),
                _LogsTab(state: state),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showResultDialog(BuildContext context,
      {required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(success ? 'Berhasil!' : 'Gagal'),
        ]),
        content: Text(message),
        actions: [
          if (!success)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<DeviceSetupBloc>().add(ResetDeviceSetupEvent());
              },
              child: const Text('Coba Lagi'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (success) Navigator.pop(context);
            },
            child: Text(success ? 'Selesai' : 'Tutup'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 1 — Sensor Settings
// ═══════════════════════════════════════════════════════════════
class _SensorSettingsTab extends StatelessWidget {
  final DeviceSetupState state;
  final TextEditingController kFaktorController;
  final TextEditingController radiusController;
  final String? customDeviceId;
  final ValueChanged<String?> onCustomDeviceIdChanged;

  const _SensorSettingsTab({
    required this.state,
    required this.kFaktorController,
    required this.radiusController,
    required this.customDeviceId,
    required this.onCustomDeviceIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DeviceSetupBloc>();
    final isSaving = state.status == DeviceSetupStatus.settingsSaving;
    final isLoading = state.status == DeviceSetupStatus.settingsLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info card ────────────────────────────────────────
          _infoCard(
            'Settings disimpan ke Firebase. ESP membaca ulang setiap 5 menit. '
            'Tidak perlu upload ulang firmware.',
          ),
          const SizedBox(height: 24),

          // ── Device ID ────────────────────────────────────────
          _sectionTitle('Perangkat Aktif'),
          const SizedBox(height: 10),
          _DeviceIdSelector(
            currentId: state.deviceId,
            onChanged: (id) => bloc.add(DeviceIdChanged(id)),
          ),
          const SizedBox(height: 24),

          // ── Kalibrasi ────────────────────────────────────────
          _sectionTitle('Kalibrasi'),
          const SizedBox(height: 10),
          _SettingsCard(children: [
            _NumericField(
              controller: kFaktorController,
              label: 'K-Faktor',
              hint: 'Contoh: 50.0',
              suffix: '×',
              helper: 'Konstanta kalibrasi vs AWS. Awal: 50.0',
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null && d > 0) bloc.add(KFaktorChanged(d));
              },
            ),
            const Divider(height: 24),
            _NumericField(
              controller: radiusController,
              label: 'Jari-jari Lengan',
              hint: 'Contoh: 0.08',
              suffix: 'm',
              helper: 'Jarak pusat ke ujung cup anemometer. Default: 0.08 m',
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null && d > 0) bloc.add(RadiusChanged(d));
              },
            ),
          ]),
          const SizedBox(height: 24),

          // ── Jumlah Magnet ─────────────────────────────────────
          _sectionTitle('Jumlah Magnet'),
          const SizedBox(height: 4),
          Text(
            'Sesuaikan dengan jumlah magnet yang terpasang di lengan anemometer. '
            'Lebih banyak magnet = resolusi lebih tinggi.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          _MagnetCountSelector(
            selected: state.magnetCount,
            onSelected: (count) => bloc.add(MagnetCountChanged(count)),
          ),
          const SizedBox(height: 24),

          // ── Interval Realtime ─────────────────────────────────
          _sectionTitle('Interval Pengiriman Realtime'),
          const SizedBox(height: 4),
          Text(
            'Seberapa sering data rata-rata dikirim ke Firebase. '
            'Lebih pendek = lebih akurat, lebih boros data.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          _ChipSelector(
            options: _kRealtimeOptions,
            selectedMs: state.intervalRealtimeMs,
            onSelected: (ms) => bloc.add(IntervalRealtimeChanged(ms)),
          ),
          const SizedBox(height: 24),

          // ── Interval History ──────────────────────────────────
          _sectionTitle('Interval History (Rata-rata Jangka Panjang)'),
          const SizedBox(height: 4),
          Text(
            'Seberapa sering rata-rata data di-push ke history Firebase. '
            'Ideal: 1 jam untuk rekaman harian.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          _ChipSelector(
            options: _kHistoryOptions,
            selectedMs: state.intervalHistoryMs,
            onSelected: (ms) => bloc.add(IntervalHistoryChanged(ms)),
          ),
          const SizedBox(height: 32),

          // ── Rumus preview ─────────────────────────────────────
          _FormulaPreview(
            kFaktor: state.kFaktor,
            radiusM: state.radiusM,
            magnetCount: state.magnetCount,
          ),
          const SizedBox(height: 32),

          // ── Tombol Simpan ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  isSaving ? null : () => bloc.add(DeviceSettingsSaved()),
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(isSaving ? 'Menyimpan...' : 'Simpan ke Firebase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );

  Widget _infoCard(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: Colors.blue.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  Tab 2 — WiFi Setup (existing, wrapped)
// ═══════════════════════════════════════════════════════════════
class _WifiSetupTab extends StatelessWidget {
  final DeviceSetupState state;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final void Function(bool, String) onShowResultDialog;

  const _WifiSetupTab({
    required this.state,
    required this.ssidController,
    required this.passwordController,
    required this.formKey,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onShowResultDialog,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DeviceSetupBloc>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _InfoBanner(status: state.status),
          const SizedBox(height: 20),
          _StepCard(
            step: 1,
            title: 'Nyalakan Anemometer',
            description:
                'Pastikan ESP32 sudah menyala dan dalam mode AP (hotspot). '
                'LED berkedip menandakan mode hotspot aktif.',
            isDone: _isConnectedOrBeyond(state.status),
          ),
          const SizedBox(height: 12),
          _StepCard(
            step: 2,
            title: 'Sambungkan HP ke Hotspot ESP',
            description: 'Buka Pengaturan WiFi → sambungkan ke:\n\n'
                '📶  Anemometer-Setup\n\n'
                'Tidak ada password. Kembali ke app setelah tersambung.',
            isDone: _isConnectedOrBeyond(state.status),
            trailing: _isConnectedOrBeyond(state.status)
                ? null
                : TextButton.icon(
                    onPressed: () =>
                        AppSettings.openAppSettings(type: AppSettingsType.wifi),
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text('Buka Setting'),
                  ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            step: 3,
            title: 'Verifikasi Koneksi ke ESP',
            description: _step3Description(state),
            isDone: _isConnectedOrBeyond(state.status),
            trailing: _isConnectedOrBeyond(state.status)
                ? null
                : ElevatedButton.icon(
                    onPressed: state.status == DeviceSetupStatus.checkingConn
                        ? null
                        : () => bloc.add(CheckEspConnectionEvent()),
                    icon: state.status == DeviceSetupStatus.checkingConn
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_find_rounded, size: 16),
                    label: Text(
                      state.status == DeviceSetupStatus.checkingConn
                          ? 'Mengecek...'
                          : 'Cek Koneksi',
                    ),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13)),
                  ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            step: 4,
            title: 'Masukkan Kredensial WiFi',
            description: 'Isi SSID dan password WiFi untuk anemometer.',
            isDone: state.status == DeviceSetupStatus.success,
            child: _isConnectedOrBeyond(state.status) &&
                    state.status != DeviceSetupStatus.success
                ? _WifiForm(
                    ssidController: ssidController,
                    passwordController: passwordController,
                    formKey: formKey,
                    obscurePassword: obscurePassword,
                    onToggleObscure: onToggleObscure,
                    isLoading: state.status == DeviceSetupStatus.sending,
                    onSubmit: state.status == DeviceSetupStatus.sending
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              bloc.add(SendWifiCredentialsEvent(
                                ssid: ssidController.text,
                                password: passwordController.text,
                              ));
                            }
                          },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool _isConnectedOrBeyond(DeviceSetupStatus s) =>
      s == DeviceSetupStatus.connected ||
      s == DeviceSetupStatus.sending ||
      s == DeviceSetupStatus.success;

  String _step3Description(DeviceSetupState state) {
    if (state.status == DeviceSetupStatus.notConnected) {
      return state.errorMessage ?? 'Belum terhubung ke ESP.';
    }
    if (_isConnectedOrBeyond(state.status)) {
      return '✅ HP sudah terhubung ke ESP.';
    }
    return 'Tekan tombol untuk memverifikasi koneksi ke ESP.';
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 3 — Logs
// ═══════════════════════════════════════════════════════════════
class _LogsTab extends StatelessWidget {
  final DeviceSetupState state;
  const _LogsTab({required this.state});

  void _showRestartDialog(
      BuildContext context, DeviceSetupBloc bloc, String deviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.restart_alt_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Remote Restart'),
        ]),
        content: Text(
          'ESP "$deviceId" akan restart dalam ~5 detik.\n\n'
          'Data realtime akan berhenti sebentar lalu kembali normal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(DeviceRestartRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DeviceSetupBloc bloc) {
    final count = state.selectedLogKeys.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.delete_outline_rounded, color: Colors.red.shade600),
          const SizedBox(width: 8),
          const Text('Hapus Log'),
        ]),
        content: Text(
          'Hapus $count log yang dipilih?\n\n'
          'Data akan dihapus permanen dari Firebase dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(LogsDeleteRequested());
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DeviceSetupBloc>();
    final fmt = DateFormat('dd MMM HH:mm:ss', 'id_ID');
    final isSelecting = state.isSelecting;
    final selectedCount = state.selectedLogKeys.length;

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSelecting ? '$selectedCount dipilih' : 'Log Device',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelecting ? Colors.blue.shade700 : Colors.black87,
                      ),
                    ),
                    Text(
                      state.deviceId,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              if (isSelecting) ...[
                // Pilih semua
                TextButton(
                  onPressed: () => bloc.add(LogSelectAllToggled()),
                  child: Text(
                    state.allSelected ? 'Batal semua' : 'Pilih semua',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
                // Hapus terpilih
                IconButton.filledTonal(
                  onPressed: selectedCount == 0
                      ? null
                      : () => _showDeleteConfirmDialog(context, bloc),
                  icon: const Icon(Icons.delete_rounded),
                  tooltip: 'Hapus yang dipilih',
                  style: IconButton.styleFrom(
                    backgroundColor: selectedCount > 0
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    foregroundColor: selectedCount > 0
                        ? Colors.red.shade700
                        : Colors.grey.shade400,
                  ),
                ),
                // Batalkan mode pilih
                IconButton(
                  onPressed: () => bloc.add(LogSelectModeToggled()),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Batalkan',
                ),
              ] else ...[
                // Tombol pilih / select mode
                IconButton.filledTonal(
                  onPressed: state.logs.isEmpty
                      ? null
                      : () => bloc.add(LogSelectModeToggled()),
                  icon: const Icon(Icons.checklist_rounded),
                  tooltip: 'Pilih log',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // restart esp
              IconButton.filledTonal(
                onPressed: () =>
                    _showRestartDialog(context, bloc, state.deviceId),
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Remote Restart ESP',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 8),

              // refresh log serial
              IconButton.filledTonal(
                onPressed: state.logsLoading
                    ? null
                    : () => bloc.add(DeviceLogsRefreshed()),
                icon: state.logsLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh logs',
              ),
            ],
          ),
        ),

        // ── List ───────────────────────────────────────────────
        Expanded(
          child: state.logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terminal_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('Belum ada log',
                          style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(height: 4),
                      Text('Boot ESP untuk melihat log pertama',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: state.logs.length,
                  itemBuilder: (ctx, i) {
                    final log = state.logs[i];
                    final key = log['_key'] as String;
                    final msg = log['msg'] as String;
                    final ts = log['timestamp'] as DateTime;
                    final isSelected = state.selectedLogKeys.contains(key);

                    // Warna berdasarkan konten pesan
                    final isOta = msg.contains('OTA') || msg.contains('FW=');
                    final isError = msg.contains('GAGAL') ||
                        msg.contains('error') ||
                        msg.contains('Error');

                    final color = isError
                        ? Colors.red.shade600
                        : isOta
                            ? Colors.blue.shade600
                            : Colors.green.shade600;
                    final bg = isError
                        ? Colors.red.shade50
                        : isOta
                            ? Colors.blue.shade50
                            : Colors.green.shade50;

                    return GestureDetector(
                      // Long press → masuk mode pilih sekaligus pilih item ini
                      onLongPress: isSelecting
                          ? null
                          : () {
                              bloc.add(LogSelectModeToggled());
                              bloc.add(LogItemToggled(key));
                            },
                      onTap: isSelecting
                          ? () => bloc.add(LogItemToggled(key))
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade100 : bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade400
                                : color.withValues(alpha: 0.25),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Checkbox atau ikon
                            if (isSelecting)
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 10, top: 1),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: isSelected
                                      ? Icon(Icons.check_circle_rounded,
                                          key: const ValueKey('checked'),
                                          size: 20,
                                          color: Colors.blue.shade700)
                                      : Icon(
                                          Icons.radio_button_unchecked_rounded,
                                          key: const ValueKey('unchecked'),
                                          size: 20,
                                          color: Colors.grey.shade400),
                                ),
                              )
                            else
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 10, top: 1),
                                child: Icon(
                                  isError
                                      ? Icons.error_outline_rounded
                                      : isOta
                                          ? Icons.system_update_rounded
                                          : Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: color,
                                ),
                              ),

                            // Konten
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.blue.shade900
                                          : color,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fmt.format(ts),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _DeviceIdSelector extends StatelessWidget {
  final String currentId;
  final ValueChanged<String> onChanged;
  const _DeviceIdSelector({required this.currentId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          ..._kDeviceOptions.map((id) {
            final selected = id == currentId;
            return RadioListTile<String>(
              value: id,
              groupValue: currentId,
              title: Text(id,
                  style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace')),
              subtitle: Text(
                id == 'esp_lapangan'
                    ? 'ESP utama di lapangan (outdoor)'
                    : 'ESP untuk percobaan (indoor/lab)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              activeColor: Colors.blue.shade700,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            );
          }),
          // Custom ID
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Custom Device ID',
                hintText: 'Contoh: esp_atap_gedung',
                prefixIcon: const Icon(Icons.devices_rounded, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) onChanged(v.trim());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSelector extends StatelessWidget {
  final Map<String, int> options;
  final int selectedMs;
  final ValueChanged<int> onSelected;
  const _ChipSelector(
      {required this.options,
      required this.selectedMs,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final selected = e.value == selectedMs;
        return ChoiceChip(
          label: Text(e.key),
          selected: selected,
          selectedColor: Colors.blue.shade700,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (_) => onSelected(e.value),
        );
      }).toList(),
    );
  }
}

class _NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final String helper;
  final ValueChanged<String> onChanged;

  const _NumericField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.helper,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        helperText: helper,
        helperMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _FormulaPreview extends StatelessWidget {
  final double kFaktor;
  final double radiusM;
  final int magnetCount;

  const _FormulaPreview({
    required this.kFaktor,
    required this.radiusM,
    required this.magnetCount,
  });

  @override
  Widget build(BuildContext context) {
    // Contoh: 1 pulsa per detik
    final exampleRps = 1.0 / magnetCount;
    final exampleSpeed = 2 * 3.14159 * radiusM * exampleRps * kFaktor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.functions_rounded,
                size: 16, color: Colors.amber.shade300),
            const SizedBox(width: 8),
            Text('Preview Rumus',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade300,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(
            'speed = 2π × radius × (pulsa / (dt × magnet)) × k',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
                fontFamily: 'monospace'),
          ),
          const SizedBox(height: 6),
          Text(
            '       = 2π × ${radiusM.toStringAsFixed(3)}m × (p / (dt × $magnetCount)) × ${kFaktor.toStringAsFixed(1)}',
            style: const TextStyle(
                fontSize: 12, color: Colors.white70, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          Text(
            '@ 1 pulsa/detik → ${exampleSpeed.toStringAsFixed(3)} m/s',
            style: TextStyle(
                fontSize: 13,
                color: Colors.green.shade300,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

// ── WIDGET BARU: _MagnetCountSelector ─────────────────────────
// Tambahkan class baru ini di bagian bawah file,
// setelah class _FormulaPreview

class _MagnetCountSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _MagnetCountSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = [1, 2, 3];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: options.map((count) {
          final isSelected = count == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onSelected(count),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Gambar titik magnet
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          count,
                          (_) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blue.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$count magnet',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        count == 1 ? 'default' : 'resolusi ${count}×',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Widgets internal
// ══════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  final DeviceSetupStatus status;
  const _InfoBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering_rounded,
              color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup WiFi Anemometer',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ikuti langkah-langkah berikut untuk mengkonfigurasi '
                  'koneksi WiFi pada perangkat anemometer.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final bool isDone;
  final Widget? trailing;
  final Widget? child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    this.isDone = false,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isDone ? Colors.green.shade300 : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? Colors.green
                        : theme.colorScheme.primaryContainer,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '$step',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: child!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WifiForm extends StatelessWidget {
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback? onSubmit;
  final bool isLoading;

  const _WifiForm({
    required this.ssidController,
    required this.passwordController,
    required this.formKey,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SSID
          TextFormField(
            controller: ssidController,
            decoration: InputDecoration(
              labelText: 'Nama WiFi (SSID)',
              hintText: 'Contoh: RumahKu_2.4GHz',
              prefixIcon: const Icon(Icons.wifi_rounded),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'SSID tidak boleh kosong'
                : null,
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password WiFi',
              hintText: 'Kosongkan jika WiFi terbuka',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: onToggleObscure,
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit?.call(),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                  isLoading ? 'Mengirim ke ESP...' : 'Kirim ke Anemometer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          if (isLoading) ...[
            const SizedBox(height: 10),
            Text(
              '⏳ Mengirim konfigurasi WiFi ke ESP...\n'
              'Koneksi akan terputus sebentar saat ESP restart.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
