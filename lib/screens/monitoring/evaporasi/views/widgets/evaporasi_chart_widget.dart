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

  double _tempToEvapScale({
    required double temp,
    required double evapMin,
    required double evapMax,
    required double tempMin,
    required double tempMax,
  }) {
    final tempRange = (tempMax - tempMin);
    if (tempRange.abs() < 1e-9) return evapMin;

    final normalized = (temp - tempMin) / tempRange; // 0..1 ideal
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
            ),
          ],
        ),
        child: const Text('Tidak ada data chart'),
      );
    }

    // Sesuai permintaan: evaporasi 0..20 dan suhu 0..30
    const evapMin = 0.0;
    const evapMax = 20.0;
    const tempMin = 0.0;
    const tempMax = 30.0;

    // Deduplicate X by index for evaporasi
    final evapSpotsAll = dailyValues.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _safeValue(e.value));
    }).toList();

    final Map<int, double> evapByX = {};
    for (final s in evapSpotsAll) {
      evapByX[s.x.toInt()] = s.y;
    }

    final dedupEvapSpots = evapByX.entries
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final tempByX = <int, double>{};
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

    final evapSpots = dedupEvapSpots
        .map((e) => FlSpot(
              e.key.toDouble(),
              e.value.clamp(evapMin, evapMax),
            ))
        .toList();

    double getRightTitle(double y) {
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
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
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(

            getTooltipItems: (spots) {
              return spots.map((spot) {
                final temp = _evapScaleToTemp(
                  yEvap: spot.y,
                  evapMin: evapMin,
                  evapMax: evapMax,
                  tempMin: tempMin,
                  tempMax: tempMax,
                );
                return LineTooltipItem(
                  'Evap: ${spot.y.toStringAsFixed(1)} mm\nSuhu: ${temp.toStringAsFixed(1)} °C',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          if (evapSpots.isNotEmpty)
            LineChartBarData(
              spots: evapSpots,
              isCurved: false,
              color: Colors.blue.shade700,
              barWidth: 2,
                  dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),


            ),

          if (tempSpots.isNotEmpty)
            LineChartBarData(
              spots: tempSpots,
              isCurved: false,
              color: Colors.orange.shade700,
              barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),

            ),
        ],
      ),
    );

    return Container(
      height: 380,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
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
                    decoration: const BoxDecoration(
                      color: Colors.blue,
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
                    decoration: const BoxDecoration(
                      color: Colors.orange,
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
              borderRadius: BorderRadius.circular(25),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }
}

