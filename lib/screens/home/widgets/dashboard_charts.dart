import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../monitoring/wind_speed/blocs/wind_speed_bloc.dart';
import '../../monitoring/evaporasi/blocs/evaporasi_bloc.dart';
import '../../monitoring/atmospheric_conditions/blocs/atmospheric_conditions_bloc.dart';

/// Period selector khusus untuk dashboard
class DashboardPeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const DashboardPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _periods = ["Hari Ini", "Minggu Ini", "Bulan Ini"];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((p) {
          final isSelected = p == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade700 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget utama — semua grafik dashboard
class DashboardCharts extends StatefulWidget {
  const DashboardCharts({super.key});

  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts> {
  String _period = "Hari Ini";

  void _onPeriodChanged(String p) {
    setState(() => _period = p);
    context.read<WindSpeedBloc>().add(WindSpeedPeriodChanged(p));
    context.read<EvaporasiBloc>().add(EvaporasiPeriodChanged(p));
    // AtmosphericBloc tidak punya period (hanya realtime)
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header + Period Selector ──────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Grafik Sensor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DashboardPeriodSelector(
          selected: _period,
          onChanged: _onPeriodChanged,
        ),
        const SizedBox(height: 14),

        // ── Scrollable chart list ─────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // 1. Kecepatan Angin
              BlocBuilder<WindSpeedBloc, WindSpeedState>(
                builder: (context, state) {
                  final data = switch (_period) {
                    "Minggu Ini" => state.weeklySpeeds,
                    "Bulan Ini" => state.monthlySpeeds,
                    _ => state.dailySpeeds,
                  };
                  return _SensorChartCard(
                    title: 'Kecepatan Angin',
                    unit: 'm/s',
                    color: Colors.blue.shade600,
                    bgColor: Colors.blue.shade50,
                    icon: Icons.air,
                    currentValue: state.currentSpeed,
                    data: data,
                    period: _period,
                    isLoading: state.isLoading,
                  );
                },
              ),
              const SizedBox(width: 12),

              // 2. Evaporasi
              BlocBuilder<EvaporasiBloc, EvaporasiState>(
                builder: (context, state) {
                  final data = switch (_period) {
                    "Minggu Ini" => state.dailyValues, // weekly jika ada
                    "Bulan Ini" => state.dailyValues,
                    _ => state.dailyValues,
                  };
                  return _SensorChartCard(
                    title: 'Evaporasi',
                    unit: 'mm',
                    color: Colors.teal.shade600,
                    bgColor: Colors.teal.shade50,
                    icon: Icons.water_drop_outlined,
                    currentValue: state.currentValue,
                    data: data,
                    period: _period,
                    isLoading: state.isLoading,
                  );
                },
              ),
              const SizedBox(width: 12),

              // 3. Tekanan Udara — hanya realtime (tidak ada history)
              BlocBuilder<AtmosphericConditionsBloc,
                  AtmosphericConditionsState>(
                builder: (context, state) {
                  return _AtmosphericCard(state: state);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Sensor Chart Card — untuk angin & evaporasi
// ══════════════════════════════════════════════════════════════════
class _SensorChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final double currentValue;
  final List<double> data;
  final String period;
  final bool isLoading;

  const _SensorChartCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.currentValue,
    required this.data,
    required this.period,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nilai saat ini
          if (isLoading)
            Container(
              height: 28,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentValue.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Mini chart
          isLoading
              ? Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              : _MiniLineChart(
                  data: data,
                  color: color,
                  period: period,
                ),

          const SizedBox(height: 8),
          Text(
            _periodLabel(period),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _periodLabel(String p) {
    return switch (p) {
      "Minggu Ini" => "Rata-rata per hari minggu ini",
      "Bulan Ini" => "Rata-rata per hari bulan ini",
      _ => "Rata-rata per jam hari ini",
    };
  }
}

// ══════════════════════════════════════════════════════════════════
//  Atmospheric Card — tekanan udara (realtime only, no history)
// ══════════════════════════════════════════════════════════════════
class _AtmosphericCard extends StatelessWidget {
  final AtmosphericConditionsState state;

  const _AtmosphericCard({required this.state});

  @override
  Widget build(BuildContext context) {
    // Klasifikasi tekanan udara
    final (label, labelColor) = _classifyPressure(state.pressure);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.compress,
                    color: Colors.purple.shade400, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kondisi Atmosfer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tekanan utama
          if (state.isLoading)
            Container(
              height: 28,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.pressure.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade400,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'hPa',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info tambahan: suhu, humidity, altitude
            _AtmosInfoRow(
              items: [
                _AtmosItem(
                    Icons.thermostat_rounded,
                    '${state.temperature.toStringAsFixed(1)}°C',
                    'Suhu',
                    Colors.orange.shade400),
                _AtmosItem(
                    Icons.water_drop_rounded,
                    '${state.humidity.toStringAsFixed(0)}%',
                    'Kelembapan',
                    Colors.blue.shade400),
                _AtmosItem(
                    Icons.landscape_rounded,
                    '${state.altitude.toStringAsFixed(0)} m',
                    'Altitud',
                    Colors.green.shade400),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Text(
            'Data realtime — tidak ada history',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  static (String, Color) _classifyPressure(double hpa) {
    if (hpa < 1000) return ('Rendah', Colors.orange.shade600);
    if (hpa > 1020) return ('Tinggi', Colors.blue.shade600);
    return ('Normal', Colors.green.shade600);
  }
}

class _AtmosInfoRow extends StatelessWidget {
  final List<_AtmosItem> items;
  const _AtmosInfoRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((item) => Expanded(
                child: Column(
                  children: [
                    Icon(item.icon, color: item.color, size: 18),
                    const SizedBox(height: 3),
                    Text(
                      item.value,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.label,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _AtmosItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _AtmosItem(this.icon, this.value, this.label, this.color);
}

// ══════════════════════════════════════════════════════════════════
//  Mini Line Chart — custom painter, tanpa library tambahan
// ══════════════════════════════════════════════════════════════════
class _MiniLineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final String period;

  const _MiniLineChart({
    required this.data,
    required this.color,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final nonZero = data.where((v) => v > 0).toList();
    if (nonZero.isEmpty) {
      return SizedBox(
        height: 70,
        child: Center(
          child: Text(
            'Belum ada data',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ),
      );
    }

    return SizedBox(
      height: 70,
      child: CustomPaint(
        painter: _LineChartPainter(data: data, color: color),
        size: const Size(double.infinity, 70),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] / maxVal) * size.height;
      points.add(Offset(x, y));
    }

    // Area fill (gradient)
    final path = Path();
    path.moveTo(points.first.dx, size.height);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dot di titik terakhir
    final lastPoint = points.last;
    canvas.drawCircle(
      lastPoint,
      3.5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      lastPoint,
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data || old.color != color;
}
