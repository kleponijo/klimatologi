// lib/screens/monitoring/evaporasi/views/evaporasi_screen.dart

import '../../device_setup/blocs/evaporasi_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/evaporasi_bloc.dart';
import '../../shared/utils/pdf/pdf_export_service.dart';
import '../../shared/widgets/export_pdf_button.dart';
import 'widgets/evaporasi_chart_widget.dart';
import 'widgets/evaporasi_control_panel.dart';
import 'widgets/evaporasi_range_selector.dart';
import 'widgets/evaporasi_history_list.dart';
import '../../shared/utils/excel/evaporasi_excel_service.dart';

class EvaporasiScreen extends StatefulWidget {
  const EvaporasiScreen({super.key});

  @override
  State<EvaporasiScreen> createState() => _EvaporasiScreenState();
}

class _EvaporasiScreenState extends State<EvaporasiScreen> {
// ── Dialog export: nama file + date range ───────────────────
  Future<void> _showExportDialog(
      BuildContext context, EvaporasiState state) async {
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

    final nameController = TextEditingController(
      text: 'evaporasi_${DateFormat('ddMMyyyy').format(DateTime.now())}',
    );
    DateTime? dateFrom;
    DateTime? dateTo;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final fmt = DateFormat('dd MMM yyyy', 'id_ID');

          Future<void> pickRange() async {
            final range = await showDateRangePicker(
              context: ctx,
              firstDate: firstDate,
              lastDate: lastDate,
              initialDateRange: dateFrom != null && dateTo != null
                  ? DateTimeRange(start: dateFrom!, end: dateTo!)
                  : null,
              locale: const Locale('id', 'ID'),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.blue.shade700,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (range != null) {
              setDialogState(() {
                dateFrom = range.start;
                dateTo = range.end;
              });
            }
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.file_download_outlined, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                const Text('Export Excel',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nama file ──────────────────────────────
                  const Text('Nama file',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'nama_file',
                      suffixText: '.xlsx',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.blue.shade600, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Range tanggal ──────────────────────────
                  const Text('Filter rentang tanggal',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: pickRange,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range_rounded,
                              size: 18, color: Colors.blue.shade600),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dateFrom != null && dateTo != null
                                  ? '${fmt.format(dateFrom!)}  →  ${fmt.format(dateTo!)}'
                                  : 'Semua data (tanpa filter)',
                              style: TextStyle(
                                fontSize: 13,
                                color: dateFrom != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          if (dateFrom != null)
                            GestureDetector(
                              onTap: () => setDialogState(() {
                                dateFrom = null;
                                dateTo = null;
                              }),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (dateFrom != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${state.history.where((e) {
                        final d = DateTime(e.timestamp.year, e.timestamp.month,
                            e.timestamp.day);
                        final from = DateTime(
                            dateFrom!.year, dateFrom!.month, dateFrom!.day);
                        final to =
                            DateTime(dateTo!.year, dateTo!.month, dateTo!.day);
                        return !d.isBefore(from) && !d.isAfter(to);
                      }).length} data dalam rentang ini',
                      style:
                          TextStyle(fontSize: 11, color: Colors.blue.shade600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _doExport(
                    context,
                    state,
                    nameController.text.trim(),
                    dateFrom,
                    dateTo,
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
  }

// ── Proses export setelah dialog ditutup ────────────────────
  Future<void> _doExport(
    BuildContext context,
    EvaporasiState state,
    String customName,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final fileName = customName.isEmpty
        ? 'evaporasi_${DateFormat('ddMMyyyy').format(DateTime.now())}'
        : customName;

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

      await EvaporasiExcelService.export(
        currentValue: state.currentValue,
        temperature: state.temperature,
        waterLevel: state.waterLevel,
        acuanPagi: state.currentData?.acuanPagi ?? 0.0,
        weatherStatus: state.weatherStatus,
        history: state.history,
        fileName: fileName,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text('$fileName.xlsx berhasil dibuat!')),
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
          'Evaporasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          BlocBuilder<EvaporasiBloc, EvaporasiState>(
            builder: (context, state) => IconButton(
              tooltip: 'Export Excel',
              icon: const Icon(Icons.file_download_outlined),
              onPressed: state.history.isEmpty
                  ? null
                  : () => _showExportDialog(context, state),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EvaporasiSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<EvaporasiBloc, EvaporasiState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final historyMaps = state.history
              .map((e) => {
                    'timestamp': e.timestamp,
                    'evaporasi': e.evaporasi,
                    'suhu': e.suhu,
                    'tinggiAir': e.tinggiAir,
                  })
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main Card ───────────────────────────────
                _mainCard(state),
                const SizedBox(height: 20),

                // ── Info Row ────────────────────────────────
                _infoRow(state),
                const SizedBox(height: 20),

                // ── Status Card ─────────────────────────────
                _statusCard(state),
                const SizedBox(height: 20),

                // ── Range Selector ──────────────────────────
                const Text(
                  'Tren Evaporasi & Suhu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const EvaporasiRangeSelector(),
                const SizedBox(height: 12),

                // ── Block nilai E (kalibrasi H1 - H2) ──────────────────
                BlocBuilder<EvaporasiBloc, EvaporasiState>(
                  builder: (context, s) {
                    if (s.chartValues.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Untuk range > 1 hari, chartValues berisi E per hari
                    final isRange = !s.isSingleDay;
                    if (!isRange) {
                      return const SizedBox.shrink();
                    }

                    // Tampilkan E pada hari terakhir rentang (hari ke-N)
                    final eLast = s.chartValues.last;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.calculate_rounded,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Nilai Evaporasi Terkalibrasi (E)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'E terakhir (hari terakhir rentang): ${eLast.toStringAsFixed(2)} mm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rumus: E = max(H1) − max(H2)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Chart ───────────────────────────────────
                BlocBuilder<EvaporasiBloc, EvaporasiState>(
                  builder: (context, s) => EvaporasiChartWidget(
                    dailyValues: s.chartValues,
                    dailyTemperatures: s.chartTemperatures,
                    period: s.isSingleDay ? 'Hari Ini' : 'Range',
                    chartLabels: s.chartLabels,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Riwayat Data ────────────────────────────
                BlocBuilder<EvaporasiBloc, EvaporasiState>(
                  builder: (context, s) => EvaporasiHistoryList(
                    history: s.filteredHistory,
                    selectedDate: s.selectedDateFilter,
                    onPickDate: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        locale: const Locale('id', 'ID'),
                      );
                      if (picked != null && context.mounted) {
                        context.read<EvaporasiBloc>().add(
                              EvaporasiDateFilterChanged(picked),
                            );
                      }
                    },
                    onClearDate: () {
                      context.read<EvaporasiBloc>().add(
                            const EvaporasiDateFilterChanged(null),
                          );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // ── Export PDF ──────────────────────────────
                ExportPdfButton(
                  onExport: () => PdfExportService.evaporasi(
                    evaporasi: state.currentValue,
                    suhu: state.temperature,
                    tinggiAir: state.waterLevel,
                    timestamp: DateTime.now(),
                    historyData: historyMaps.isNotEmpty ? historyMaps : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mainCard(EvaporasiState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Icon(Icons.water_drop, color: Colors.white, size: 45),
          const SizedBox(height: 10),
          Text(
            state.currentValue.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'mm',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(EvaporasiState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _miniCard(
              cardWidth,
              'Suhu Air',
              state.temperature < 0
                  ? '- °C'
                  : '${state.temperature.toStringAsFixed(1)} °C',
              Icons.thermostat,
              Colors.orange,
            ),
            _miniCard(
              cardWidth,
              'Tinggi Air',
              '${state.waterLevel.toStringAsFixed(1)} cm',
              Icons.water,
              Colors.blue,
            ),
          ],
        );
      },
    );
  }

  Widget _miniCard(
      double width, String title, String value, IconData icon, Color color) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(EvaporasiState state) {
    Color statusColor;
    IconData statusIcon;
    String warningText;

    switch (state.weatherStatus) {
      case 'Normal':
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_rounded;
        warningText = 'Sedang — evaporasi dalam batas normal, pantau kondisi.';
        break;
      case 'Tinggi':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        warningText =
            'Tinggi — evaporasi signifikan, berpotensi memengaruhi kondisi lingkungan.';
        break;
      case 'Rendah':
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        warningText = 'Rendah — evaporasi stabil, risiko dampak rendah.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Evaporasi',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  state.weatherStatus,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  warningText,
                  style: TextStyle(
                      fontSize: 12,
                      color: statusColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// hhhhhhhh