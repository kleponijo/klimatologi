import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/atmospheric_conditions_bloc.dart';
import '../../shared/utils/pdf/pdf_export_service.dart';
import '../../shared/widgets/export_pdf_button.dart';

class AtmosphericScreen extends StatelessWidget {
  const AtmosphericScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Kondisi Atmosfer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<AtmosphericConditionsBloc, AtmosphericConditionsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _mainTemperature(state),
                const SizedBox(height: 25),
                _gridInfo(state),
                const SizedBox(height: 25),

                // ← Tombol Export PDF
                ExportPdfButton(
                  onExport: () => PdfExportService.atmospheric(
                    temperature: state.temperature,
                    humidity: state.humidity,
                    pressure: state.pressure,
                    altitude: state.altitude,
                    timestamp: DateTime.now(),
                    // atmospheric state belum punya history,
                    // kalau nanti ditambah tinggal isi historyData di sini
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
  /// 🌡️ TEMPERATURE (HERO CARD)
  /// =========================
  Widget _mainTemperature(AtmosphericConditionsState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 38, 255, 222),
            const Color.fromARGB(255, 53, 132, 229)
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 191, 255).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.thermostat, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          Text(
            state.temperature.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "°C",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// 📊 INFO GRID
  /// =========================
  Widget _gridInfo(AtmosphericConditionsState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.6,
      children: [
        _infoCard(
          "Kelembapan",
          "${state.humidity.toStringAsFixed(1)} %",
          Icons.water_drop,
          Colors.blue,
        ),
        _infoCard(
          "Tekanan",
          "${state.pressure.toStringAsFixed(1)} hPa",
          Icons.speed,
          Colors.green,
        ),
        _infoCard(
          "Ketinggian",
          "${state.altitude.toStringAsFixed(1)} m",
          Icons.terrain,
          Colors.brown,
        ),
      ],
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }
}
