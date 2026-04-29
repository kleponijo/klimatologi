import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/device_setup_bloc.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeviceSetupBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setup WiFi Anemometer'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocConsumer<DeviceSetupBloc, DeviceSetupState>(
          listener: (context, state) {
            if (state.status == DeviceSetupStatus.success) {
              _showResultDialog(context,
                  success: true, message: state.successMessage ?? '');
            } else if (state.status == DeviceSetupStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Terjadi kesalahan.'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info Banner ───────────────────────────────
                  _InfoBanner(status: state.status),
                  const SizedBox(height: 24),

                  // ── Step 1: Panduan konek hotspot ─────────────
                  _StepCard(
                    step: 1,
                    title: 'Nyalakan Perangkat Anemometer',
                    description:
                        'Pastikan ESP32 anemometer sudah menyala dan belum pernah '
                        'dikonfigurasi WiFi-nya. LED akan berkedip menandakan '
                        'mode hotspot aktif.',
                    isDone: state.status == DeviceSetupStatus.connected ||
                        state.status == DeviceSetupStatus.sending ||
                        state.status == DeviceSetupStatus.success,
                  ),
                  const SizedBox(height: 12),

                  _StepCard(
                    step: 2,
                    title: 'Sambungkan HP ke Hotspot ESP',
                    description:
                        'Buka Pengaturan WiFi di HP kamu, lalu sambungkan ke:\n\n'
                        '📶  Anemometer-Setup\n\n'
                        'Hotspot ini tidak punya password. Setelah tersambung, '
                        'kembali ke aplikasi ini.',
                    isDone: state.status == DeviceSetupStatus.connected ||
                        state.status == DeviceSetupStatus.sending ||
                        state.status == DeviceSetupStatus.success,
                    trailing: _OpenWifiSettingsButton(status: state.status),
                  ),
                  const SizedBox(height: 12),

                  // ── Step 3: Cek koneksi ───────────────────────
                  _StepCard(
                    step: 3,
                    title: 'Verifikasi Koneksi ke ESP',
                    description: state.status == DeviceSetupStatus.notConnected
                        ? state.errorMessage ?? 'Belum terhubung ke ESP.'
                        : state.status == DeviceSetupStatus.connected ||
                                state.status == DeviceSetupStatus.sending ||
                                state.status == DeviceSetupStatus.success
                            ? '✅ HP sudah terhubung ke ESP. Lanjutkan ke langkah berikutnya.'
                            : 'Tekan tombol di bawah untuk memverifikasi koneksi ke ESP.',
                    isDone: state.status == DeviceSetupStatus.connected ||
                        state.status == DeviceSetupStatus.sending ||
                        state.status == DeviceSetupStatus.success,
                    trailing: state.status == DeviceSetupStatus.connected ||
                            state.status == DeviceSetupStatus.sending ||
                            state.status == DeviceSetupStatus.success
                        ? null
                        : _CheckConnectionButton(state: state),
                  ),
                  const SizedBox(height: 12),

                  // ── Step 4: Isi form WiFi ─────────────────────
                  _StepCard(
                    step: 4,
                    title: 'Masukkan Kredensial WiFi',
                    description: 'Isi SSID dan password WiFi yang ingin '
                        'digunakan oleh anemometer.',
                    isDone: state.status == DeviceSetupStatus.success,
                    child: state.status == DeviceSetupStatus.connected ||
                            state.status == DeviceSetupStatus.sending
                        ? _WifiForm(
                            ssidController: _ssidController,
                            passwordController: _passwordController,
                            formKey: _formKey,
                            obscurePassword: _obscurePassword,
                            onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            onSubmit: state.status == DeviceSetupStatus.sending
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<DeviceSetupBloc>().add(
                                            SendWifiCredentialsEvent(
                                              ssid: _ssidController.text,
                                              password:
                                                  _passwordController.text,
                                            ),
                                          );
                                    }
                                  },
                            isLoading:
                                state.status == DeviceSetupStatus.sending,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showResultDialog(
    BuildContext context, {
    required bool success,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Berhasil!' : 'Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // tutup dialog
              Navigator.of(context).pop(); // kembali ke wind_speed_screen
            },
            child: const Text('Selesai'),
          ),
        ],
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

class _OpenWifiSettingsButton extends StatelessWidget {
  final DeviceSetupStatus status;
  const _OpenWifiSettingsButton({required this.status});

  @override
  Widget build(BuildContext context) {
    // Tidak perlu tampil kalau sudah connected
    if (status == DeviceSetupStatus.connected ||
        status == DeviceSetupStatus.sending ||
        status == DeviceSetupStatus.success) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      onPressed: () {
        // Buka pengaturan WiFi sistem HP
        // Butuh package: app_settings (opsional)
        // AppSettings.openWIFISettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Buka Pengaturan WiFi HP → sambungkan ke "Anemometer-Setup"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.settings_rounded, size: 16),
      label: const Text('Buka Setting'),
    );
  }
}

class _CheckConnectionButton extends StatelessWidget {
  final DeviceSetupState state;
  const _CheckConnectionButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isChecking = state.status == DeviceSetupStatus.checkingConn;
    return ElevatedButton.icon(
      onPressed: isChecking
          ? null
          : () =>
              context.read<DeviceSetupBloc>().add(CheckEspConnectionEvent()),
      icon: isChecking
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_find_rounded, size: 16),
      label: Text(isChecking ? 'Mengecek...' : 'Cek Koneksi'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: const TextStyle(fontSize: 13),
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
