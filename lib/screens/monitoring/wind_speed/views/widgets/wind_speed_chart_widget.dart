/// === File ini khusus untuk urusan Grafik === ///
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

class WindSpeedChartWidget extends StatelessWidget {
  final List<double> dailySpeeds;
  final String period; // menambahkan parameter periode

  const WindSpeedChartWidget(
      {super.key, required this.dailySpeeds, required this.period});

  @override
  Widget build(BuildContext context) {
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
        LineChartData(
          minY: 0,
          maxY: 50,
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
              spots: dailySpeeds.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: Colors.blue.shade700,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.0)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
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
