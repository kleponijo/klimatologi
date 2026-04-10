import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../widgets/monitoring_shared.dart';

class WindSpeedGraphBlock extends StatelessWidget {
  final String selectedPeriod;
  final List<double> dailySpeeds;
  final bool isOnline;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onExportPressed;

  const WindSpeedGraphBlock({
    super.key,
    required this.selectedPeriod,
    required this.dailySpeeds,
    required this.isOnline,
    required this.onPeriodChanged,
    required this.onExportPressed,
  });

  List<FlSpot> _getPeriodSpots() {
    switch (selectedPeriod) {
      case "Hari Ini":
        return List.generate(24, (i) {
          final value = dailySpeeds[i];
          return FlSpot(i.toDouble(), value);
        });
      case "Minggu Ini":
        return const [
          FlSpot(0, 6.5),
          FlSpot(1, 7.2),
          FlSpot(2, 7.8),
          FlSpot(3, 8.0),
          FlSpot(4, 7.5),
          FlSpot(5, 6.8),
          FlSpot(6, 5.5),
        ];
      case "Bulan Ini":
        return const [
          FlSpot(0, 6.0),
          FlSpot(1, 6.5),
          FlSpot(2, 7.0),
          FlSpot(3, 7.5),
          FlSpot(4, 7.8),
          FlSpot(5, 8.0),
          FlSpot(6, 8.2),
          FlSpot(7, 8.0),
          FlSpot(8, 7.5),
          FlSpot(9, 7.0),
          FlSpot(10, 6.5),
          FlSpot(11, 6.0),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Status Kecepatan Angin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOnline ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnline ? "ONLINE" : "OFFLINE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          ["Hari Ini", "Minggu Ini", "Bulan Ini"].map((period) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(period),
                            selected: selectedPeriod == period,
                            onSelected: (selected) {
                              if (selected) {
                                onPeriodChanged(period);
                              }
                            },
                            selectedColor: Colors.green,
                            labelStyle: TextStyle(
                              color: selectedPeriod == period
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => onExportPressed(selectedPeriod),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text("Export"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: getPeriodInterval(selectedPeriod),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            getPeriodLabel(selectedPeriod, value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      spots: _getPeriodSpots(),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
