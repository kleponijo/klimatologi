import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../widgets/monitoring_shared.dart';

class WindSpeedAnnualSection extends StatelessWidget {
  final VoidCallback onExportAnnual;

  const WindSpeedAnnualSection({
    super.key,
    required this.onExportAnnual,
  });
  final double _rataRata = 0.0;
  final double _kecepatanMax = 0.0;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistik Tahunan Kecepatan Angin",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: "Rata-rata Tahunan",
                value: this._rataRata.toStringAsFixed(2),
                color: Colors.green,
                icon: Icons.air,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: "Kecepatan Max",
                value: this._kecepatanMax.toStringAsFixed(2),
                color: Colors.red,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Grafik Tahunan - Rata-rata & Kecepatan Maksimal",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 320,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 5.5),
                        FlSpot(1, 6.2),
                        FlSpot(2, 6.8),
                        FlSpot(3, 7.5),
                        FlSpot(4, 7.8),
                        FlSpot(5, 8.0),
                        FlSpot(6, 8.2),
                        FlSpot(7, 8.0),
                        FlSpot(8, 7.2),
                        FlSpot(9, 6.5),
                        FlSpot(10, 5.8),
                        FlSpot(11, 5.2),
                      ],
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.green,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 12.0), //sadds
                        FlSpot(1, 13.5),
                        FlSpot(2, 14.0),
                        FlSpot(3, 15.5),
                        FlSpot(4, 16.0),
                        FlSpot(5, 16.2),
                        FlSpot(6, 16.5),
                        FlSpot(7, 16.0),
                        FlSpot(8, 15.0),
                        FlSpot(9, 14.0),
                        FlSpot(10, 12.5),
                        FlSpot(11, 11.0),
                      ],
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.red,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Rata-rata (km/h)",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 20),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Kecepatan Max (km/h)",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Center(
          child: ElevatedButton.icon(
            onPressed: onExportAnnual,
            icon: const Icon(Icons.file_download),
            label: const Text("Download Excel Tahunan"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
