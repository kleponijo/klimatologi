import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/wind_speed_bloc.dart';

class WindSpeedScreen extends StatelessWidget {
  const WindSpeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan MonitoringRepository sudah diprovide di atas screen ini
    return Scaffold(
      appBar: AppBar(title: const Text("Wind Speed Monitoring")),
      body: BlocBuilder<WindSpeedBloc, WindSpeedState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Card Informasi Kecepatan Saat Ini
                _buildCurrentSpeedCard(state.currentSpeed),
                const SizedBox(height: 30),

                // Area Grafik
                const Text("Grafik Kecepatan Angin",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                SizedBox(
                  height: 300,
                  child: LineChart(
                    _mainData(state.dailySpeeds),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSpeedCard(double speed) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.wind_power, color: Colors.blue, size: 40),
        title: const Text("Kecepatan Saat Ini"),
        trailing: Text("${speed.toStringAsFixed(2)} m/s",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  LineChartData _mainData(List<double> speeds) {
    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: const FlTitlesData(show: true), // Bisa dikustom nanti
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          // Mengubah List<double> menjadi titik koordinat grafik (x, y)
          spots: speeds.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value);
          }).toList(),
          isCurved: true, // Biar garisnya melengkung halus
          color: Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: false), // Sembunyikan titik per data
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.2), // Efek bayangan di bawah garis
          ),
        ),
      ],
    );
  }
}
