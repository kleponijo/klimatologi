import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/wind_speed_bloc.dart';
import './widgets/wind_speed_chart_widget.dart';
import 'widgets/period_selector.dart';

import '../../shared/utils/pdf/pdf_export_service.dart';
import '../../shared/widgets/export_pdf_button.dart';

class WindSpeedScreen extends StatelessWidget {
  const WindSpeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Kecepatan Angin",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),

      /// === Body area, lokasi dan tata letak Widgets === ///
      body: BlocBuilder<WindSpeedBloc, WindSpeedState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Pilih data sesuai periode
          final List<double> data = switch (state.selectedPeriod) {
            "Minggu Ini" => state.weeklySpeeds,
            "Bulan Ini" => state.monthlySpeeds,
            _ => state.dailySpeeds,
          };

          // List<double> data;

          // if (state.selectedPeriod == "Minggu Ini") {
          //   data = state.weeklySpeeds;
          // } else if (state.selectedPeriod == "Bulan Ini") {
          //   data = state.monthlySpeeds;
          // } else {
          //   data = state.dailySpeeds;
          // }

          // Konversi history MyWindSpeed → Map (untuk tabel PDF)
          final historyMaps = state.history
              .map((e) => {
                    'timestamp': e.timestamp,
                    'speed': e.speed,
                    'pulse': e.pulse,
                  })
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                /// ==== 1. Tampilan Angka Utama kecepatan angin (Hero Widget look) ==== ///
                _buildMainSpeedDisplay(state.currentSpeed),
                const SizedBox(height: 30),

                const Text("Tren Kecepatan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                const PeriodSelector(),
                const SizedBox(height: 15),

                WindSpeedChartWidget(
                  dailySpeeds: data,
                  period: state.selectedPeriod,
                ),

                const SizedBox(height: 30),

                // 3. Info Tambahan (Status/Periode)
                _buildDetailRow(state.selectedPeriod),
                const SizedBox(height: 24),

                // ← Tombol Export PDF
                ExportPdfButton(
                  onExport: () => PdfExportService.windSpeed(
                    currentSpeed: state.currentSpeed,
                    period: state.selectedPeriod,
                    speeds: data,
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

  Widget _buildMainSpeedDisplay(double speed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.air, color: Colors.white, size: 50),
          const SizedBox(
            height: 10,
          ),
          Text(
            "${speed.toStringAsFixed(1)}",
            style: const TextStyle(
                fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text("m/s",
              style: TextStyle(fontSize: 20, color: Colors.white70))
        ],
      ),
    );
  }

  Widget _buildDetailRow(String period) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniInfoCard("Status", "Normal", Icons.check_circle, Colors.green),
        _miniInfoCard("Periode", period, Icons.timer, Colors.orange),
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
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
