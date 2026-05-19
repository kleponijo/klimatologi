// lib/screens/monitoring/evaporasi/views/evaporasi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/evaporasi_bloc.dart';
import '../../shared/utils/pdf/pdf_export_service.dart';
import '../../shared/widgets/export_pdf_button.dart';
import 'widgets/evaporasi_chart_widget.dart';
import 'widgets/evaporasi_range_selector.dart';
import 'widgets/evaporasi_history_list.dart';

class EvaporasiScreen extends StatefulWidget {
  const EvaporasiScreen({super.key});

  @override
  State<EvaporasiScreen> createState() => _EvaporasiScreenState();
}

class _EvaporasiScreenState extends State<EvaporasiScreen> {
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
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const EvaporasiRangeSelector(),
                const SizedBox(height: 12),

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniCard('Suhu Air',
            '${state.temperature.toStringAsFixed(1)} °C',
            Icons.thermostat, Colors.orange),
        _miniCard('Tinggi Air',
            '${state.waterLevel.toStringAsFixed(1)} cm',
            Icons.water, Colors.blue),
      ],
    );
  }

  Widget _miniCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
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
        warningText =
            'Sedang — evaporasi dalam batas normal, pantau kondisi.';
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
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
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