import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/evaporasi_bloc.dart';
import '../../shared/utils/pdf/pdf_export_service.dart';
import '../../shared/widgets/export_pdf_button.dart';

class EvaporasiScreen extends StatelessWidget {
  const EvaporasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Evaporasi",
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
              children: [
                _mainCard(state),
                const SizedBox(height: 25),
                _infoRow(state),
                const SizedBox(height: 25),
<<<<<<< HEAD
                _statusCard(state),
                const SizedBox(height: 25),
                const Text("Tren Evaporasi & Suhu",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
// Period selector with date picker
                Builder(
                  builder: (context) {
                    final state = context.watch<EvaporasiBloc>().state;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show selected date info when in custom mode
                        if (state.viewMode == EvaporasiViewMode.customDate &&
                            state.selectedDate != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "📅 ${_formatDateInfo(state.selectedDate!)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        const EvaporasiPeriodSelector(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 15),
                Builder(
                  builder: (context) {
                    final state = context.watch<EvaporasiBloc>().state;
                    return EvaporasiChartWidget(
                      dailyValues: state.dailyValues,
                      dailyTemperatures: state.dailyTemperatures,
                      period: state.viewMode == EvaporasiViewMode.customDate
                          ? "Tanggal Khusus"
                          : state.selectedPeriod,
                    );
                  },
                ),
=======
                _trendSection(),
>>>>>>> parent of 6f38d3b (update evaporsi)
                const SizedBox(height: 25),
                ExportPdfButton(
                  onExport: () => PdfExportService.evaporasi(
                    evaporasi: state.currentValue,
                    suhu: state.temperature,
                    tinggiAir: state.waterLevel,
                    timestamp: DateTime.now(),
                    historyData: historyMaps.isNotEmpty ? historyMaps : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// =========================
  /// 🔥 MAIN CARD (EVAPORASI)
  /// =========================
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
            state.currentValue.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "mm",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// 📊 INFO KECIL (SUHU & AIR)
  /// =========================
  Widget _infoRow(EvaporasiState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniCard(
          "Suhu",
          "${state.temperature.toStringAsFixed(1)} °C",
          Icons.thermostat,
          Colors.orange,
        ),
        _miniCard(
          "Tinggi Air",
          "${state.waterLevel.toStringAsFixed(1)} cm",
          Icons.water,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _miniCard(String title, String value, IconData icon, Color color) {
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  /// =========================
  /// 📈 TREND (SIMPLE PLACEHOLDER)
  /// =========================
  Widget _trendSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
<<<<<<< HEAD
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Status Cuaca",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  state.weatherStatus,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (state.willRain)
                  const Text(
                    "⚠️ Potensi hujan tinggi",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
],
=======
      child: const Center(
        child: Text(
          "Grafik Evaporasi",
          style: TextStyle(color: Colors.grey),
        ),
>>>>>>> parent of 6f38d3b (update evaporsi)
      ),
    );
  }

  /// =========================
  /// 📅 FORMAT DATE INFO (for custom date display)
  /// =========================
  String _formatDateInfo(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return "Hari Ini";
    } else if (selected == yesterday) {
      return "Kemarin";
    } else {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    }
  }
}
