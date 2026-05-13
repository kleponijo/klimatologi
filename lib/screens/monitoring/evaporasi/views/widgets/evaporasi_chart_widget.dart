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

  double _minOf(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.map(_safeValue).reduce((a, b) => a < b ? a : b);
  }

  double _maxOf(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.map(_safeValue).reduce((a, b) => a > b ? a : b);
  }

  double _clampDouble(double v, double minV, double maxV) {
    if (v.isNaN || v.isInfinite) return minV;
    return v.clamp(minV, maxV);
  }

  List<FlSpot> _evapSpots() {
    return dailyValues.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), _safeValue(entry.value));
    }).toList();
  }

  /// Mapping suhu (°C) -> posisi Y internal agar bisa ditampilkan dalam chart
  /// yang sama dengan skala evaporasi (mm).
  double _tempToEvapScale({
    required double temp,
    required double evapMin,
    required double evapMax,
    required double tempMin,
    required double tempMax,
  }) {
    // Hindari pembagian nol
    final tempRange = (tempMax - tempMin);
    if (tempRange.abs() < 1e-9) return evapMin;

    final normalized = (temp - tempMin) / tempRange; // 0..1 (secara ideal)
    final scaled = evapMin + normalized * (evapMax - evapMin);
    return scaled;
  }

  /// Reverse mapping Y internal (skala evaporasi) -> suhu asli (°C)
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

  String _getBottomLabel(int index) {
    if (chartLabels.isEmpty || index < 0 || index >= chartLabels.length) {
      return index.toString();
    }
    return chartLabels[index];
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

    // Hitung range masing-masing agar axis kanan (°C) masuk akal.
    final evapMinRaw = _minOf(dailyValues);
    final evapMaxRaw = _maxOf(dailyValues);
    final tempMinRaw = _minOf(dailyTemperatures);
    final tempMaxRaw = _maxOf(dailyTemperatures);

    // Evaporasi mm biasanya >= 0, kita pakai min 0 agar estetik.
    final evapMin = 0.0;
    final evapMax = _clampDouble(evapMaxRaw * 1.15, 8.0, 50.0);

    // Suhu bisa saja 0 jika data kosong; tetap aman.
    final tempMin = tempMinRaw;
    final tempMax = tempMaxRaw == tempMinRaw ? tempMinRaw + 1 : tempMaxRaw;

    final evapSpotsAll = _evapSpots();

    // Deduplicate X=hour agar garis tidak kelihatan dobel/acak.
    final Map<int, double> evapByX = {};
    for (final s in evapSpotsAll) {
      evapByX[s.x.toInt()] = s.y;
    }

    final dedupEvapSpots = evapByX.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final Map<int, double> tempByX = {};
    for (final entry in dailyTemperatures.asMap().entries) {
      tempByX[entry.key] = _safeValue(entry.value);
    }
    final tempSpots = tempByX.entries.map((entry) {
      final x = entry.key.toDouble();
      final temp = entry.value;
      final y = _tempToEvapScale(
        temp: temp,
        evapMin: evapMin,
        evapMax: evapMax,
        tempMin: tempMin,
        tempMax: tempMax,
      );
      return FlSpot(x, y);
    }).toList();

    final evapSpots =
        dedupEvapSpots.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    if (evapSpots.isEmpty && tempSpots.isEmpty) {
      return const SizedBox.shrink();
    }

    double _getRightTitle(double y) {
      return _evapScaleToTemp(
        yEvap: y,
        evapMin: evapMin,
        evapMax: evapMax,
        tempMin: tempMin,
        tempMax: tempMax,
      );
    }

    final chart = LineChart(
      LineChartData(
        minY: evapMin,
        maxY: evapMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (evapMax - evapMin) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: period == 'Hari Ini'
                  ? 3
                  : period == 'Minggu Ini'
                      ? 1
                      : 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getBottomLabel(index),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (evapMax - evapMin) / 4,
              getTitlesWidget: (value, meta) {
                final v = value;
                return Text(
                  '${v.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (evapMax - evapMin) / 4,
              getTitlesWidget: (value, meta) {
                final t = _getRightTitle(value);
                return Text(
                  '${t.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.brown, fontSize: 10),
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
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final isTemp = spot.bar.color == Colors.orange.shade700;

                if (isTemp) {
                  final temp = _evapScaleToTemp(
                    yEvap: spot.y,
                    evapMin: evapMin,
                    evapMax: evapMax,
                    tempMin: tempMin,
                    tempMax: tempMax,
                  );

                  return LineTooltipItem(
                    '🌡 Suhu\n${temp.toStringAsFixed(1)} °C',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }

                return LineTooltipItem(
                  '💧 Evaporasi\n${spot.y.toStringAsFixed(1)} mm',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          if (evapSpots.isNotEmpty)
            LineChartBarData(
              spots: evapSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              isStrokeCapRound: true,
              color: Colors.blue.shade700,
              barWidth: 3,
              showingIndicators: [0],
              dotData: FlDotData(
                show: false,
                checkToShowDot: (spot, barData) => false,
              ),
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
          if (tempSpots.isNotEmpty)
            LineChartBarData(
              spots: tempSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              isStrokeCapRound: true,
              color: Colors.orange.shade700,
              barWidth: 3,
              showingIndicators: [0],
              dotData: FlDotData(
                show: false,
                checkToShowDot: (spot, barData) => false,
              ),
            ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );

    return Container(
      height: 340,
      padding: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Evaporasi (mm)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Suhu (°C)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Monitoring Evaporasi & Suhu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}
