import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EvaporasiChartWidget extends StatelessWidget {
  final List<double> dailyValues;
  final List<double> dailyTemperatures;
  final String period;
  final List<String> chartLabels;

  const EvaporasiChartWidget({
    super.key,
    required this.dailyValues,
    required this.dailyTemperatures,
    required this.period,
    required this.chartLabels,
  });

  double _safeValue(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value < 0 ? 0.0 : value;
  }

  double _maxY() {
    final values = [
      ...dailyValues.map(_safeValue),
      ...dailyTemperatures.map(_safeValue),
    ];
    if (values.isEmpty) return 10;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.4).clamp(10.0, 100.0);
  }

  List<FlSpot> _lineSpots(List<double> series) {
    return series.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), _safeValue(entry.value));
    }).toList();
  }

  String _getBottomLabel(int index) {
    if (chartLabels.isEmpty || index < 0 || index >= chartLabels.length) {
      return index.toString();
    }
    return chartLabels[index];
  }

  @override
  Widget build(BuildContext context) {
    final values = _lineSpots(dailyValues);
    final temperatures = _lineSpots(dailyTemperatures);

    if (values.isEmpty && temperatures.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: const Text('Tidak ada data chart'),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: _maxY(),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _getBottomLabel(index),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        spot.y.toStringAsFixed(1),
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                if (values.isNotEmpty)
                  LineChartBarData(
                    spots: values,
                    isCurved: true,
                    color: Colors.blue.shade700,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withAlpha(64),
                          Colors.blue.withAlpha(13),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                if (temperatures.isNotEmpty)
                  LineChartBarData(
                    spots: temperatures,
                    isCurved: true,
                    color: Colors.orange.shade700,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
