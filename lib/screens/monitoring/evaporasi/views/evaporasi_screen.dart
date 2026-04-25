import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                _trendSection(),
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
      child: const Center(
        child: Text(
          "Grafik Evaporasi",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
