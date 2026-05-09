import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EvaporasiChartWidget extends StatelessWidget {
  final List<double> dailyValues;
  final List<double> dailyTemperatures;
  final String period;

  const EvaporasiChartWidget({
    super.key,
    required this.dailyValues,
    required this.dailyTemperatures,
    required this.period,
  });

  double _getMaxY(List<double> data) {
    if (data.isEmpty) return 10;
    final max = data.reduce((a, b) => a > b ? a : b);
    return (max + 5).clamp(10, 100);
  }

  List<double> _safeData(List<double> data) {
    return data.map((e) {
      if (e.isNaN || e.isInfinite) return 0.0;
      return e < 0 ? 0.0 : e;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final safeValues = _safeData(dailyValues);
    final safeTemps = _safeData(dailyTemperatures);

    // Gunakan max dari kedua dataset agar skala Y sesuai
    final maxY = _getMaxY([
      ...safeValues,
      ...safeTemps,
    ]);

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.blue.shade700, "Evaporasi (mm)"),
              const SizedBox(width: 20),
              _legendItem(Colors.orange.shade600, "Suhu (°C)"),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getInterval(),
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            _getBottomTitle(value),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  // === Garis Evaporasi ===
                  LineChartBarData(
                    spots: safeValues.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.2,
                    preventCurveOverShooting: true,
                    color: Colors.blue.shade700,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index == safeValues.length - 1) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.blue.shade900,
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
                          Colors.blue.withOpacity(0.25),
                          Colors.blue.withOpacity(0.05),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // === Garis Suhu ===
                  LineChartBarData(
                    spots: safeTemps.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.2,
                    preventCurveOverShooting: true,
                    color: Colors.orange.shade600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index == safeTemps.length - 1) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.orange.shade800,
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
                          Colors.orange.withOpacity(0.25),
                          Colors.orange.withOpacity(0.05),
                          Colors.transparent
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
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isEvaporasi = spot.barIndex == 0;
                        final label = isEvaporasi ? "Evaporasi" : "Suhu";
                        final unit = isEvaporasi ? "mm" : "°C";
                        return LineTooltipItem(
                          "$label: ${spot.y.toStringAsFixed(1)} $unit",
                          TextStyle(
                            color: isEvaporasi
                                ? Colors.blue.shade100
                                : Colors.orange.shade100,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
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
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _getBottomTitle(double value) {
    int index = value.toInt();
    final len = dailyValues.length;
    if (index < 0 || index >= len) return '';

    if (period == "Hari Ini") {
      return index % 4 == 0 ? "${index.toString().padLeft(2, '0')}:00" : "";
    } else if (period == "Minggu Ini") {
      const days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
      return days[index % 7];
    } else {
      return (index + 1) % 5 == 0 ? "${index + 1}" : "";
    }
  }

  double _getInterval() {
    if (period == "Hari Ini") return 1;
    if (period == "Minggu Ini") return 1;
    return 1;
  }
}

