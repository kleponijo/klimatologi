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

    // anti spike
    if (value > 1000 || value < -1000) return 0.0;

    return value < 0 ? 0.0 : value;
  }

  double _tempToEvapScale({
    required double temp,
    required double evapMin,
    required double evapMax,
    required double tempMin,
    required double tempMax,
  }) {
    final tempRange = (tempMax - tempMin);
    if (tempRange.abs() < 1e-9) return evapMin;

    final normalized = (temp - tempMin) / tempRange;
    return evapMin + normalized * (evapMax - evapMin);
  }

  double _evapScaleToTemp({
    required double yEvap,
    required double evapMin,
    required double evapMax,
    required double tempMin,
    required double tempMax,
  }) {
    final evapRange = (evapMax - evapMin);
    if (evapRange.abs() < 1e-9) return tempMin;

    final normalized = (yEvap - evapMin) / evapRange;
    return tempMin + normalized * (tempMax - tempMin);
  }

  double _xLabelInterval() {
    if (period == 'Minggu Ini') return 1; // 7 label
    if (period == 'Bulan Ini') return 5; // ~31 label tiap 5 hari
    return 3; // 24 jam tiap 3 jam
  }

  String _getBottomLabel(int index) {
    if (chartLabels.isEmpty || index < 0 || index >= chartLabels.length) {
      return '';
    }
    return chartLabels[index];
  }

  double _maxOf(List<double> values) {
    if (values.isEmpty) return 0.0;
    double max = values.first;
    for (final v in values) {
      if (v > max) max = v;
    }
    return max;
  }

  double _minOf(List<double> values) {
    if (values.isEmpty) return 0.0;
    double min = values.first;
    for (final v in values) {
      if (v < min) min = v;
    }
    return min;
  }

  List<FlSpot> _buildEvapSpots(double evapMin, double evapMax) {
    if (dailyValues.isEmpty) return const [];

    return dailyValues.asMap().entries
        .where((e) => e.value >= 0) // Hanya tampilkan data yang ada / valid
        .map((e) {
          final x = e.key.toDouble();
          final y = _safeValue(e.value).clamp(evapMin, evapMax);
          return FlSpot(x, y);
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (dailyValues.isEmpty && dailyTemperatures.isEmpty) {
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

    const evapMin = 0.0;

    final evapMaxRaw = _maxOf(dailyValues);
    final tempMinRaw = _minOf(dailyTemperatures);
    final tempMaxRaw = _maxOf(dailyTemperatures);

    // ── FIXED COORD SYSTEM SUHU MALFUNCTION ──
    // Jika data suhu flat 0 atau sangat rendah, kita kunci range visualnya dari 0 sampai 40 derajat Celsius
    final tempMin = tempMaxRaw < 2.0 ? 0.0 : tempMinRaw;
    final tempMax = tempMaxRaw < 2.0 ? 40.0 : (tempMaxRaw == tempMinRaw ? tempMinRaw + 1 : tempMaxRaw);

    // Evaporasi: Berikan buffer / ruang kosong (+ 20%) di bagian atas grafik agar tidak terpotong rata
    final double evapMaxBase = evapMaxRaw < 1e-9 ? 20.0 : (evapMaxRaw > 50 ? 50.0 : evapMaxRaw);
    final evapMax = evapMaxBase * 1.2; // Tambahan padding atas 20%

    final evapSpots = _buildEvapSpots(evapMin, evapMax);

    // Suhu diproyeksikan ke skala evaporasi
    final tempSpots = dailyTemperatures.asMap().entries
        .where((entry) => entry.value >= 0) // Hanya tampilkan data yang ada / valid
        .map((entry) {
          final x = entry.key.toDouble();
          final temp = _safeValue(entry.value);
          final y = _tempToEvapScale(
            temp: temp,
            evapMin: evapMin,
            evapMax: evapMax,
            tempMin: tempMin,
            tempMax: tempMax,
          );
          return FlSpot(x, y.clamp(evapMin, evapMax));
        }).toList();

    double getRightTitle(double y) {
      if (tempSpots.isEmpty) return tempMin;
      return _evapScaleToTemp(
        yEvap: y,
        evapMin: evapMin,
        evapMax: evapMax,
        tempMin: tempMin,
        tempMax: tempMax,
      );
    }

    final xInterval = _xLabelInterval().toInt().clamp(1, 1000);

    final chart = LineChart(
      LineChartData(
        minY: evapMin,
        maxY: evapMax,
        minX: -0.5,
        maxX: (chartLabels.isNotEmpty ? chartLabels.length - 1 : 23)
                .toDouble() +
            0.5,
        // Diubah ke clipData false agar lengkungan ujung titik teratas tidak ter-crop kaku
        clipData: const FlClipData.none(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (evapMax - evapMin) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: const ExtraLinesData(horizontalLines: []),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: xInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (value != value.roundToDouble()) return const SizedBox();
                if (index < 0 || index >= chartLabels.length) {
                  return const SizedBox();
                }
                if (index % xInterval != 0) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getBottomLabel(index),
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text(
              'mm',
              style: TextStyle(color: Colors.blueGrey, fontSize: 10),
            ),
            axisNameSize: 16,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: (evapMax - evapMin) / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            axisNameWidget: const Text(
              '°C',
              style: TextStyle(color: Colors.brown, fontSize: 10),
            ),
            axisNameSize: 16,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: (evapMax - evapMin) / 4,
              getTitlesWidget: (value, meta) {
                final t = getRightTitle(value);
                // Menampilkan label dengan 1 angka desimal jika nilainya kecil, 
                // atau bulat murni jika data menggunakan fallback sistem (0-40)
                return Text(
                  t > 5 ? t.toStringAsFixed(0) : t.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.brown,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            showOnTopOfTheChartBoxArea: true,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return const <LineTooltipItem>[];

              // Ambil spot pertama yang disentuh untuk mencari index X
              final firstSpot = touchedSpots.first;
              final idx = firstSpot.x.round();

              // Validasi batas index
              if (idx < 0 || idx >= dailyValues.length) {
                return const <LineTooltipItem>[];
              }

              // Ambil data evaporasi dan suhu langsung dari array data berdasarkan index X
              final evapVal = dailyValues[idx];
              final tempVal = idx < dailyTemperatures.length ? dailyTemperatures[idx] : 0.0;

              final tooltipText = 'Evap: ${evapVal.toStringAsFixed(1)} mm\n'
                                  'Suhu: ${tempVal.toStringAsFixed(1)} °C';

              return touchedSpots.asMap().entries.map((entry) {
                final index = entry.key;
                if (index == 0) {
                  return LineTooltipItem(
                    tooltipText,
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  );
                } else {
                  return const LineTooltipItem(
                    '',
                    TextStyle(color: Colors.transparent, fontSize: 0),
                  );
                }
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          if (evapSpots.isNotEmpty)
            LineChartBarData(
              spots: evapSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.blue.shade700,
              barWidth: 2.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.shade100.withOpacity(0.3),
              ),
            ),
          if (tempSpots.isNotEmpty)
            LineChartBarData(
              spots: tempSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.orange.shade700,
              barWidth: 2.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );

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
            '',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // Mengubah ClipBehavior ke none agar garis di titik maksimum visual luar aman tidak ter-crop
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 4),
                child: chart,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Evaporasi (mm)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Suhu (°C)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}