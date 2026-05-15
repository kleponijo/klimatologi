// ===========================================================
//  wind_speed_screen.dart
//  Lokasi: lib/screens/monitoring/wind_speed/views/
// ===========================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import '../blocs/wind_speed_bloc.dart';
import 'widgets/wind_speed_chart_widget.dart';
import 'widgets/period_selector.dart';
import '../../device_setup/views/device_setup_screen.dart';
import '../../shared/utils/excel/wind_speed_excel_service.dart';

class WindSpeedScreen extends StatefulWidget {
  const WindSpeedScreen({super.key});

  @override
  State<WindSpeedScreen> createState() => _WindSpeedScreenState();
}

class _WindSpeedScreenState extends State<WindSpeedScreen> {
  // ── Date picker ─────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context, WindSpeedState state) async {
    DateTime firstDate = DateTime.now().subtract(const Duration(days: 365));
    DateTime lastDate = DateTime.now();

    if (state.history.isNotEmpty) {
      final sorted = [...state.history]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      firstDate = DateTime(sorted.first.timestamp.year,
          sorted.first.timestamp.month, sorted.first.timestamp.day);
      lastDate = DateTime(sorted.last.timestamp.year,
          sorted.last.timestamp.month, sorted.last.timestamp.day);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade700,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && context.mounted) {
      context.read<WindSpeedBloc>().add(WindSpeedDateFilterChanged(picked));
    }
  }

  // ── Export Excel ─────────────────────────────────────────────
  Future<void> _exportExcel(BuildContext context, WindSpeedState state) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Membuat file Excel...'),
          ]),
          duration: Duration(seconds: 30),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await WindSpeedExcelService.export(
        currentSpeed: state.currentSpeed,
        alertLevel: state.alertLevel,
        period: state.selectedPeriod,
        history: state.history,
        filterDate: state.selectedDate,
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('File Excel berhasil dibuat!'),
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Gagal: $e'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Kecepatan Angin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          BlocBuilder<WindSpeedBloc, WindSpeedState>(
            builder: (context, state) => IconButton(
              tooltip: 'Export Excel',
              icon: const Icon(Icons.file_download_outlined),
              onPressed: state.history.isEmpty
                  ? null
                  : () => _exportExcel(context, state),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan Perangkat',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceSetupScreen()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<WindSpeedBloc, WindSpeedState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<double> data = switch (state.selectedPeriod) {
            'Minggu Ini' => state.weeklySpeeds,
            'Bulan Ini' => state.monthlySpeeds,
            _ => state.dailySpeeds,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Hero kecepatan ────────────────────────────
                _buildMainSpeedDisplay(state.currentSpeed, state.alertLevel),
                const SizedBox(height: 24),

                // ── 2. Tren grafik ───────────────────────────────
                const Text(
                  'Tren Kecepatan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const PeriodSelector(),
                const SizedBox(height: 12),
                if (data.isEmpty)
                  _buildEmptyChart()
                else
                  WindSpeedChartWidget(
                    dailySpeeds: data,
                    period: state.selectedPeriod,
                  ),
                const SizedBox(height: 20),

                // ── 3. Info status + periode ─────────────────────
                _buildDetailRow(state.selectedPeriod, state.alertLevel),
                const SizedBox(height: 28),

                // ── 4. Riwayat data ──────────────────────────────
                _buildHistorySection(context, state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Hero kecepatan
  // ════════════════════════════════════════════════════════════
  Widget _buildMainSpeedDisplay(double speed, String alertLevel) {
    final (badgeColor, badgeIcon) = switch (alertLevel) {
      'Bahaya' => (Colors.red.shade400, Icons.warning_rounded),
      'Waspada' => (Colors.orange.shade400, Icons.info_outline_rounded),
      _ => (Colors.green.shade400, Icons.check_circle_outline_rounded),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.air, color: Colors.white, size: 46),
          const SizedBox(height: 8),
          Text(
            speed.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const Text('m/s',
              style: TextStyle(fontSize: 20, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            '${(speed * 3.6).toStringAsFixed(1)} km/h',
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, color: badgeColor, size: 15),
                const SizedBox(width: 6),
                Text(
                  alertLevel,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Info baris: status + periode
  // ════════════════════════════════════════════════════════════
  Widget _buildDetailRow(String period, String alertLevel) {
    final (icon, color) = switch (alertLevel) {
      'Bahaya' => (Icons.warning_rounded, Colors.red),
      'Waspada' => (Icons.info_outline, Colors.orange),
      _ => (Icons.check_circle, Colors.green),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniInfoCard('Status', alertLevel, icon, color),
        _miniInfoCard('Periode', period, Icons.timer, Colors.orange),
      ],
    );
  }

  Widget _miniInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Placeholder chart kosong — cegah crash saat data belum ada
  // ════════════════════════════════════════════════════════════
  Widget _buildEmptyChart() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 42, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Data grafik belum tersedia',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Section riwayat
  // ════════════════════════════════════════════════════════════
  Widget _buildHistorySection(BuildContext context, WindSpeedState state) {
    // Urutkan terbaru di atas
    final sorted = [...state.filteredHistory]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header judul + tombol filter
        Row(
          children: [
            const Text(
              'Riwayat Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            state.selectedDate != null
                ? _FilterChip(
                    label: DateFormat('dd MMM yyyy', 'id_ID')
                        .format(state.selectedDate!),
                    icon: Icons.close_rounded,
                    onTap: () => context
                        .read<WindSpeedBloc>()
                        .add(const WindSpeedDateFilterChanged(null)),
                  )
                : _FilterChip(
                    label: 'Filter Tanggal',
                    icon: Icons.calendar_month_rounded,
                    onTap: () => _pickDate(context, state),
                  ),
          ],
        ),

        if (state.selectedDate != null) ...[
          const SizedBox(height: 4),
          Text(
            '${sorted.length} data pada ${DateFormat('dd MMMM yyyy', 'id_ID').format(state.selectedDate!)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            '${sorted.length} data tersimpan',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],

        const SizedBox(height: 12),

        // List dengan batas tinggi 420px — di dalamnya bisa di-scroll
        sorted.isEmpty
            ? _buildEmptyHistory(state.selectedDate != null)
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      shrinkWrap: false,
                      padding: EdgeInsets.zero,
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, i) =>
                          _HistoryTile(item: sorted[i], index: i),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyHistory(bool hasFilter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            hasFilter ? Icons.search_off_rounded : Icons.inbox_rounded,
            size: 44,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            hasFilter
                ? 'Tidak ada data untuk tanggal ini'
                : 'Belum ada data history',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Chip filter tanggal
// ════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Colors.blue.shade700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Satu baris data riwayat
// ════════════════════════════════════════════════════════════
class _HistoryTile extends StatelessWidget {
  final MyWindSpeed item;
  final int index;

  const _HistoryTile({required this.item, required this.index});

  String get _alertLevel {
    if (item.speed >= 12.5) return 'Bahaya';
    if (item.speed >= 8.0) return 'Waspada';
    return 'Normal';
  }

  Color get _alertColor {
    switch (_alertLevel) {
      case 'Bahaya':
        return Colors.red.shade600;
      case 'Waspada':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  IconData get _alertIcon {
    switch (_alertLevel) {
      case 'Bahaya':
        return Icons.warning_rounded;
      case 'Waspada':
        return Icons.info_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kmh = item.speed * 3.6;
    final bg = index.isEven ? Colors.grey.shade50 : Colors.white;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Nomor
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600),
            ),
          ),

          // Tanggal + jam
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy', 'id_ID').format(item.timestamp),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('HH:mm:ss').format(item.timestamp),
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          // Kecepatan
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.speed.toStringAsFixed(3)} m/s',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${kmh.toStringAsFixed(2)} km/h',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Badge status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _alertColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _alertColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_alertIcon, size: 11, color: _alertColor),
                const SizedBox(width: 3),
                Text(
                  _alertLevel,
                  style: TextStyle(
                      fontSize: 10,
                      color: _alertColor,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
