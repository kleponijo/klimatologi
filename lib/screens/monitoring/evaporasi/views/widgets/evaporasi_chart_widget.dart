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

    return dailyValues.asMap().entries.map((e) {
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

    final tempMin = tempMinRaw;
    final tempMax = tempMaxRaw == tempMinRaw ? tempMinRaw + 1 : tempMaxRaw;

    // Evaporasi: batasi maksimum supaya tetap masuk akal
    final evapMax = evapMaxRaw < 1e-9 ? 20.0 : (evapMaxRaw > 50 ? 50.0 : evapMaxRaw);

    final evapSpots = _buildEvapSpots(evapMin, evapMax);

    // Suhu diproyeksikan ke skala evaporasi
    final tempSpots = dailyTemperatures.asMap().entries.map((entry) {
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
        clipData: const FlClipData.all(),
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
                return Text(
                  t.toStringAsFixed(0),
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
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return const <LineTooltipItem>[];

              final items = <LineTooltipItem>[];
              for (int i = 0; i < touchedSpots.length; i++) {
                final spot = touchedSpots[i];
                final y = _safeValue(spot.y).clamp(evapMin, evapMax);

                if (i == 0) {
                  items.add(LineTooltipItem(
                    'Evap: ${y.toStringAsFixed(1)} mm',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ));
                } else {
                  final tempOnly = _evapScaleToTemp(
                    yEvap: y,
                    evapMin: evapMin,
                    evapMax: evapMax,
                    tempMin: tempMin,
                    tempMax: tempMax,
                  );

                  items.add(LineTooltipItem(
                    'Suhu: ${tempOnly.toStringAsFixed(1)} °C',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ));
                }
              }
              return items;
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
      height: 400,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
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
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}

