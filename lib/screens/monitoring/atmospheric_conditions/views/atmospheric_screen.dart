import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import '../blocs/atmospheric_conditions_bloc.dart';
import '../../shared/utils/pdf/pdf_export_service.dart';
import '../../shared/widgets/export_pdf_button.dart';

String formatClockTime(DateTime timestamp) {
  final h = timestamp.hour.toString().padLeft(2, '0');
  final m = timestamp.minute.toString().padLeft(2, '0');
  final s = timestamp.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class AtmosphericScreen extends StatelessWidget {
  const AtmosphericScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Kondisi Atmosfer',
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
                const SizedBox(height: 24),
                _gridInfo(state),
                const SizedBox(height: 24),
                _historyChart(state),
                const SizedBox(height: 24),
                _HistoryTableCard(history: state.history),
                const SizedBox(height: 24),
                ExportPdfButton(
                  onExport: () => PdfExportService.atmospheric(
                    temperature: state.temperature,
                    humidity: state.humidity,
                    pressure: state.pressure,
                    altitude: state.altitude,
                    timestamp: state.history.isNotEmpty
                        ? state.history.last.timestamp
                        : DateTime.now(),
                    historyData: state.history
                        .map((entry) => {
                              'timestamp': entry.timestamp,
                              'temperature': entry.temperature,
                              'humidity': entry.humidity,
                              'pressure': entry.pressure,
                              'altitude': entry.altitude,
                            })
                        .toList(),
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
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 38, 255, 222),
            Color.fromARGB(255, 53, 132, 229),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 191, 255, 0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
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
            '°C',
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
          'Kelembapan',
          '${state.humidity.toStringAsFixed(1)} %',
          Icons.water_drop,
          Colors.blue,
        ),
        _infoCard(
          'Tekanan',
          '${state.pressure.toStringAsFixed(1)} hPa',
          Icons.speed,
          Colors.green,
        ),
        _infoCard(
          'Ketinggian',
          '${state.altitude.toStringAsFixed(1)} m',
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
          ),
        ],
      ),
    );
  }

  Widget _historyChart(AtmosphericConditionsState state) {
    final history = state.history;

    if (history.isEmpty) {
      return _emptyCard('Grafik histori tekanan hari ini belum ada data');
    }

    final points = <FlSpot>[];
    double minY = history.first.pressure;
    double maxY = history.first.pressure;

    for (var i = 0; i < history.length; i++) {
      final pressure = history[i].pressure;
      points.add(FlSpot(i.toDouble(), pressure));
      minY = pressure < minY ? pressure : minY;
      maxY = pressure > maxY ? pressure : maxY;
    }

    final range = (maxY - minY).abs();
    final padding = range < 1 ? 0.5 : range * 0.15;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Histori Tekanan Hari Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: history.length > 1 ? (history.length - 1).toDouble() : 1,
                minY: minY - padding,
                maxY: maxY + padding,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: range < 1 ? 0.5 : null,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: history.length > 6
                          ? (history.length / 5).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formatClockTime(history[index].timestamp),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: history.length <= 10),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color.fromRGBO(33, 150, 243, 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _HistoryTableCard extends StatelessWidget {
  final List<AtmosphericConditions> history;

  const _HistoryTableCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Tekanan Hari Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Text('Belum ada data histori hari ini.')
          else ...[
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Waktu',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Tekanan',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...history.reversed.take(10).map(
                      (item) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(formatClockTime(item.timestamp)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child:
                                Text('${item.pressure.toStringAsFixed(1)} hPa'),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            if (history.length > 10) ...[
              const SizedBox(height: 12),
              Text(
                'Menampilkan 10 data terakhir dari ${history.length} data.',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
