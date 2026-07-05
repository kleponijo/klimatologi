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
import '../../device_setup/views/device_setup_wind_speed_screen.dart';
import '../../shared/utils/excel/wind_speed_excel_service.dart';

class WindSpeedScreen extends StatefulWidget {
  const WindSpeedScreen({super.key});

  @override
  State<WindSpeedScreen> createState() => _WindSpeedScreenState();
}

class _WindSpeedScreenState extends State<WindSpeedScreen> {
  // ── Date picker (untuk filter riwayat di layar utama) ───────
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

  // ════════════════════════════════════════════════════════════
  //  Dialog export: nama file + filter tanggal + filter jam
  // ════════════════════════════════════════════════════════════
  Future<void> _showExportDialog(
      BuildContext context, WindSpeedState state) async {
    // Tentukan batas tanggal dari history
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

    // State dialog — pakai ValueNotifier supaya tidak perlu StatefulWidget terpisah
    final nameController = TextEditingController(
      text: 'kecepatan_angin_${DateFormat('ddMMyyyy').format(DateTime.now())}',
    );
    DateTime? dateFrom;
    DateTime? dateTo;
    TimeOfDay? timeFrom;
    TimeOfDay? timeTo;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

          // Hitung jumlah data sesuai filter aktif
          int countFiltered() {
            return state.history.where((e) {
              bool passDate = true;
              bool passTime = true;
              if (dateFrom != null && dateTo != null) {
                final d = DateTime(
                  e.timestamp.year,
                  e.timestamp.month,
                  e.timestamp.day,
                );
                final from = DateTime(
                  dateFrom!.year,
                  dateFrom!.month,
                  dateFrom!.day,
                );
                final to = DateTime(dateTo!.year, dateTo!.month, dateTo!.day);
                passDate = !d.isBefore(from) && !d.isAfter(to);
              }
              if (timeFrom != null && timeTo != null) {
                final h = e.timestamp.hour;
                final fromH = timeFrom!.hour;
                final toH = timeTo!.hour;
                // Support overnight range (mis. 23→02)
                passTime = fromH <= toH
                    ? h >= fromH && h <= toH
                    : h >= fromH || h <= toH;
              }
              return passDate && passTime;
            }).length;
          }

          Future<void> pickDateRange() async {
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

          Future<void> pickTime(bool isFrom) async {
            final picked = await showTimePicker(
              context: ctx,
              initialTime: isFrom
                  ? (timeFrom ?? const TimeOfDay(hour: 0, minute: 0))
                  : (timeTo ?? const TimeOfDay(hour: 23, minute: 59)),
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                child: Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue.shade700,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              ),
            );
            if (picked != null) {
              setDialogState(() {
                if (isFrom)
                  timeFrom = picked;
                else
                  timeTo = picked;
              });
            }
          }

          String fmtTime(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

          final filtered = countFiltered();
          final hasAnyFilter = dateFrom != null || timeFrom != null;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.file_download_outlined, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                const Text(
                  'Export Excel',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nama file ──────────────────────────────
                    const Text(
                      'Nama file',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'nama_file',
                        suffixText: '.xlsx',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
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
                          borderSide: BorderSide(
                            color: Colors.blue.shade600,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Filter tanggal ─────────────────────────
                    const Text(
                      'Filter rentang tanggal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: pickDateRange,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 18,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dateFrom != null && dateTo != null
                                    ? '${dateFmt.format(dateFrom!)}  →  ${dateFmt.format(dateTo!)}'
                                    : 'Semua tanggal (tanpa filter)',
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
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Filter jam ─────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Filter rentang jam',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        if (timeFrom != null || timeTo != null)
                          GestureDetector(
                            onTap: () => setDialogState(() {
                              timeFrom = null;
                              timeTo = null;
                            }),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Dari jam
                        Expanded(
                          child: InkWell(
                            onTap: () => pickTime(true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: timeFrom != null
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: timeFrom != null
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dari jam',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: timeFrom != null
                                            ? Colors.blue.shade600
                                            : Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeFrom != null
                                            ? fmtTime(timeFrom!)
                                            : '00:00',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: timeFrom != null
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        // Sampai jam
                        Expanded(
                          child: InkWell(
                            onTap: () => pickTime(false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: timeTo != null
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: timeTo != null
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sampai jam',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: timeTo != null
                                            ? Colors.blue.shade600
                                            : Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeTo != null
                                            ? fmtTime(timeTo!)
                                            : '23:59',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: timeTo != null
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Counter data hasil filter ───────────────
                    const SizedBox(height: 10),
                    Text(
                      hasAnyFilter
                          ? '$filtered data akan diekspor'
                          : '${state.history.length} data (semua, tanpa filter)',
                      style: TextStyle(
                        fontSize: 11,
                        color: (filtered == 0 && hasAnyFilter)
                            ? Colors.red.shade400
                            : Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
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
                    timeFrom,
                    timeTo,
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
    WindSpeedState state,
    String customName,
    DateTime? dateFrom,
    DateTime? dateTo,
    TimeOfDay? timeFrom, // ← baru
    TimeOfDay? timeTo, // ← baru
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final fileName = customName.isEmpty
        ? 'kecepatan_angin_${DateFormat('ddMMyyyy').format(DateTime.now())}'
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

      await WindSpeedExcelService.export(
        currentSpeed: state.currentSpeed,
        alertLevel: state.alertLevel,
        period: state.selectedPeriod,
        history: state.history,
        fileName: fileName,
        dateFrom: dateFrom,
        dateTo: dateTo,
        hourFrom: timeFrom?.hour,
        minuteFrom: timeFrom?.minute,
        hourTo: timeTo?.hour,
        minuteTo: timeTo?.minute,
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

  // ════════════════════════════════════════════════════════════
//  Delete bottom sheet
// ════════════════════════════════════════════════════════════
  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<WindSpeedBloc>(),
        child: const _DeleteSheet(),
      ),
    );
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
                  : () => _showExportDialog(context, state),
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
      body: BlocConsumer<WindSpeedBloc, WindSpeedState>(
        listenWhen: (prev, curr) =>
            curr.deleteError != null && prev.deleteError != curr.deleteError,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal menghapus: ${state.deleteError}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ));
        },
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
            speed.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const Text('km/h',
              style: TextStyle(fontSize: 20, color: Colors.white70)),
          const SizedBox(height: 4),
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
            // ── Tombol Delete ──────────────────────────────────────────
            const SizedBox(width: 4),
            state.isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: Colors.redAccent),
                    tooltip: 'Hapus riwayat',
                    onPressed: state.history.isEmpty
                        ? null
                        : () => _showDeleteSheet(context),
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
    if (item.speed >= 45.0) return 'Bahaya';
    if (item.speed >= 25.5) return 'Waspada';
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
    final bg = index.isEven ? Colors.grey.shade50 : Colors.white;
    final hasTotal = item.totalWindwegKm > 0 || item.totalPulse > 0;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // ← child pakai Column, bukan Row langsung
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris utama ───────────────────────────────────
          Row(
            children: [
              // Nomor
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
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
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // Avg + max windweg
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.speed.toStringAsFixed(3)} km/h',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (item.maxWindwegKm > 0)
                      Text(
                        'max ${item.maxWindwegKm.toStringAsFixed(3)} km/h',
                        style: TextStyle(
                            fontSize: 10, color: Colors.orange.shade600),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Baris kedua: total + pulsa + sampel ───────────
          if (hasTotal) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _StatChip(
                    icon: Icons.route_rounded,
                    label: '${item.totalWindwegKm.toStringAsFixed(3)} km total',
                    tooltip: 'Total jarak angin periode ini',
                    color: Colors.blue.shade700,
                  ),
                  _StatChip(
                    icon: Icons.bolt_rounded,
                    label: '${item.totalPulse} pulsa',
                    tooltip: 'Total pulsa terdeteksi',
                    color: Colors.purple.shade600,
                  ),
                  if (item.sampleCount > 0)
                    _StatChip(
                      icon: Icons.analytics_outlined,
                      label: '${item.sampleCount} sampel',
                      tooltip: 'Jumlah interval average dalam periode ini',
                      color: Colors.teal.shade600,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Chip kecil untuk stat di history tile ──────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Delete Bottom Sheet
// ════════════════════════════════════════════════════════════
class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet();

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  int _mode = 0; // 0=all, 1=date, 2=range, 3=hour
  DateTime? _byDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _hourDate;
  int _startHour = 0;
  int _endHour = 23;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.delete_sweep, color: Colors.redAccent),
              const SizedBox(width: 10),
              const Text('Hapus Riwayat Angin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(),
            const SizedBox(height: 4),
            _modeCard(0, Icons.select_all_rounded, 'Hapus Semua',
                'Menghapus seluruh riwayat dari Firebase'),
            _modeCard(1, Icons.event_outlined, 'Berdasarkan Tanggal',
                'Hapus data pada satu tanggal tertentu'),
            _modeCard(2, Icons.date_range_outlined, 'Rentang Tanggal',
                'Hapus data dalam rentang tanggal (inklusif)'),
            _modeCard(3, Icons.schedule_outlined, 'Rentang Jam',
                'Hapus data berdasarkan jam pada suatu tanggal'),
            if (_mode > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildSubInput(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _valid ? _confirm : null,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Hapus Sekarang',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_mode == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: Text('⚠️  Tindakan ini tidak dapat dibatalkan',
                      style: TextStyle(fontSize: 11, color: Colors.deepOrange)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(int value, IconData icon, String title, String sub) {
    final sel = _mode == value;
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? Colors.red.withOpacity(0.07) : Colors.transparent,
          border: Border.all(
              color: sel ? Colors.red.shade300 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: sel ? Colors.red : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: sel ? Colors.red : Colors.black87)),
              Text(sub,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ]),
          ),
          if (sel) const Icon(Icons.check_circle, color: Colors.red, size: 18),
        ]),
      ),
    );
  }

  Widget _buildSubInput() {
    switch (_mode) {
      case 1:
        return _datePicker(
            'Pilih Tanggal', _byDate, (d) => setState(() => _byDate = d),
            key: const ValueKey('by_date'));
      case 2:
        return Column(key: const ValueKey('range'), children: [
          _datePicker('Tanggal Mulai', _rangeStart,
              (d) => setState(() => _rangeStart = d)),
          const SizedBox(height: 8),
          _datePicker(
              'Tanggal Akhir', _rangeEnd, (d) => setState(() => _rangeEnd = d)),
          if (_rangeStart != null &&
              _rangeEnd != null &&
              _rangeEnd!.isBefore(_rangeStart!))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Tanggal akhir harus ≥ tanggal mulai',
                  style: TextStyle(color: Colors.red, fontSize: 11)),
            ),
        ]);
      case 3:
        return Column(
            key: const ValueKey('hour'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _datePicker('Pilih Tanggal', _hourDate,
                  (d) => setState(() => _hourDate = d)),
              const SizedBox(height: 12),
              const Text('Rentang Jam',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: _hourDrop('Jam Mulai', _startHour,
                        (v) => setState(() => _startHour = v))),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('—', style: TextStyle(fontSize: 18))),
                Expanded(
                    child: _hourDrop('Jam Akhir', _endHour,
                        (v) => setState(() => _endHour = v))),
              ]),
              if (_startHour > _endHour)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Jam mulai harus ≤ jam akhir',
                      style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
            ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _datePicker(
      String hint, DateTime? value, ValueChanged<DateTime> onPick,
      {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          confirmText: 'Pilih',
          cancelText: 'Batal',
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(
              color:
                  value != null ? Colors.red.shade300 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.calendar_month_outlined,
              size: 16,
              color: value != null ? Colors.red : Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            value != null
                ? DateFormat('d MMMM yyyy', 'id_ID').format(value)
                : hint,
            style: TextStyle(
                fontSize: 13,
                color: value != null ? Colors.black87 : Colors.grey.shade400),
          ),
        ]),
      ),
    );
  }

  Widget _hourDrop(String label, int value, ValueChanged<int> onChange) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: List.generate(
        24,
        (i) => DropdownMenuItem(
          value: i,
          child: Text('${i.toString().padLeft(2, '0')}:00',
              style: const TextStyle(fontSize: 13)),
        ),
      ),
      onChanged: (v) => onChange(v!),
    );
  }

  bool get _valid {
    switch (_mode) {
      case 0:
        return true;
      case 1:
        return _byDate != null;
      case 2:
        return _rangeStart != null &&
            _rangeEnd != null &&
            !_rangeEnd!.isBefore(_rangeStart!);
      case 3:
        return _hourDate != null && _startHour <= _endHour;
      default:
        return false;
    }
  }

  void _confirm() {
    final bloc = context.read<WindSpeedBloc>();
    if (_mode == 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Semua?'),
          content:
              const Text('Seluruh riwayat akan dihapus permanen dari Firebase. '
                  'Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                bloc.add(const WindSpeedDeleteAllRequested());
              },
              child: const Text('Ya, Hapus Semua'),
            ),
          ],
        ),
      );
      return;
    }
    switch (_mode) {
      case 1:
        bloc.add(WindSpeedDeleteByDateRequested(_byDate!));
        break;
      case 2:
        bloc.add(WindSpeedDeleteByDateRangeRequested(
            start: _rangeStart!, end: _rangeEnd!));
        break;
      case 3:
        bloc.add(WindSpeedDeleteByHourRangeRequested(
            date: _hourDate!, startHour: _startHour, endHour: _endHour));
        break;
    }
    Navigator.pop(context);
  }
}
