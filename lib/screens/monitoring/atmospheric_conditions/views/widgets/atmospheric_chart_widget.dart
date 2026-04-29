import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AtmosphericChartWidget extends StatelessWidget {
  final List<double> dailyTemperatures;
  final String period;

  const AtmosphericChartWidget({
    super.key,
    required this.dailyTemperatures,
    required this.period,
  });

  double _getMaxY() {
    if (dailyTemperatures.isEmpty) return 50;
    final max = dailyTemperatures.reduce((a, b) => a > b ? a : b);
    return (max + 5).clamp(30.0, 100.0);
  }

  List<double> _safeData(List<double> data) {
    return data.map((e) => e.isNaN || e.isInfinite ? 25.0 : e.clamp(0.0, 100.0) as double).toList();
  }

  @override
  Widget build(BuildContext context) {
    final safeTemps = _safeData(dailyTemperatures);
    final maxY = _getMaxY();

    return Container(
      height: 200, // Compact for dashboard
      padding: const EdgeInsets.fromLTRB(10, 15, 15, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Legend
          _legendItem(Colors.teal.shade600, "Suhu (°C)"),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 1,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          _getBottomTitle(value.toInt()),
                          style: TextStyle(color: Colors.grey, fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: safeTemps.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.teal.shade600,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index == safeTemps.length - 1) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.teal.shade800,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withOpacity(0.3),
                          Colors.teal.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => 
                      LineTooltipItem("${spot.y.toStringAsFixed(1)} °C", 
                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      )
                    ).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  String _getBottomTitle(int index) {
    final len = dailyTemperatures.length;
    if (index < 0 || index >= len) return '';
    if (period == "Hari Ini") {
      return index % 4 == 0 ? "${index.toString().padLeft(2, '0')}:00" : "";
    }
    return (index + 1).toString();
  }
}

