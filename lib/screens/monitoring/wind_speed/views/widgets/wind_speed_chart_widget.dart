/// === File ini khusus untuk urusan Grafik === ///
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

class WindSpeedChartWidget extends StatelessWidget {
  final List<double> dailySpeeds;
  final String period; // menambahkan parameter periode

  const WindSpeedChartWidget(
      {super.key, required this.dailySpeeds, required this.period});

  double _getMaxY() {
    if (dailySpeeds.isEmpty) return 10;

    final max = dailySpeeds.reduce((a, b) => a > b ? a : b);

    return (max + 5).clamp(10, 100); // kasih padding
  }

  @override
  Widget build(BuildContext context) {
    final List<double> safeData = dailySpeeds.map((e) {
      if (e.isNaN || e.isInfinite) return 0.0;
      return e < 0 ? 0.0 : e;
    }).toList();
    return Container(
      height: 270,
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
      child: LineChart(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        LineChartData(
          minY: 0,

          maxY: _getMaxY(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),

          // === PENGATURAN LABEL SUMBU X ===
          titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval:
                          _getInterval(), // Mengatur jarak label agar tidak tumpang tindih
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
                      }))),
          lineBarsData: [
            LineChartBarData(
              spots: safeData.asMap().entries.map((e) {
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
                  if (index == dailySpeeds.length - 1) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: Colors.red,
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
                    Colors.blue.withOpacity(0.35),
                    Colors.blue.withOpacity(0.1),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              shadow: Shadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 6,
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    "${spot.y.toStringAsFixed(1)} m/s",
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // Logika untuk menentukan teks label di bawah
  String _getBottomTitle(double value) {
    int index = value.toInt();
    if (index < 0 || index >= dailySpeeds.length) return '';

    if (period == "Hari Ini") {
      // Tampilkan jam genap saja (0, 2, 4...) agar tidak penuh
      return index % 4 == 0 ? "${index.toString().padLeft(2, '0')}:00" : "";
    } else if (period == "Minggu Ini") {
      const days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
      return days[index % 7];
    } else {
      // Bulanan: Tampilkan tanggal kelipatan 5
      return (index + 1) % 5 == 0 ? "${index + 1}" : "";
    }
  }

  double _getInterval() {
    if (period == "Hari Ini") return 1; // Cek tiap jam
    if (period == "Minggu Ini") return 1; // Cek tiap hari
    return 1;
  }
}
