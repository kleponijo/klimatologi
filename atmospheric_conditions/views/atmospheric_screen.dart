import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import '../blocs/atmospheric_conditions_bloc.dart';
import '../../shared/utils/excel/excel_export_service.dart';
import '../../shared/widgets/export_excel_button.dart';

String formatUptimeShort(int timeMs) {
  final duration = Duration(milliseconds: timeMs);
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$minutes:$seconds";
}

String formatUptimeLong(int timeMs) {
  final duration = Duration(milliseconds: timeMs);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$hours:$minutes:$seconds";
}

String formatClockTime(DateTime timestamp) {
  final h = timestamp.hour.toString().padLeft(2, '0');
  final m = timestamp.minute.toString().padLeft(2, '0');
  final s = timestamp.second.toString().padLeft(2, '0');
  return "$h:$m:$s";
}

class AtmosphericScreen extends StatelessWidget {
  const AtmosphericScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Kondisi Atmosfer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<AtmosphericConditionsBloc, AtmosphericConditionsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _mainPressure(state),
                const SizedBox(height: 24),
                _historyChart(state),
                const SizedBox(height: 24),
                _HistoryTableCard(history: state.history),
                const SizedBox(height: 24),
                ExportExcelButton(
                  onExport: () {
                    final historyData = state.history
                        .map((e) => {
                              'timeMs': e.timeMs,
                              'pressure': e.pressure,
                              'timestamp': e.timestamp,
                            })
                        .toList();

                    return ExcelExportService.atmospheric(
                      pressure: state.pressure,
                      timeMs: state.timeMs,
                      timestamp: state.history.isNotEmpty ? state.history.last.timestamp : DateTime.now(),
                      historyData: historyData,
                    );
                  },
                  label: 'Export Excel Hari Ini',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// =========================
  /// 🔵 PRESSURE (HERO CARD)
  /// =========================
  Widget _mainPressure(AtmosphericConditionsState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 38, 255, 222),
            const Color.fromARGB(255, 53, 132, 229)
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 191, 255).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.speed, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          Text(
            state.pressure.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "hPa",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _historyChart(AtmosphericConditionsState state) {
    final history = state.history;

    if (history.isEmpty) {
      return _emptyCard("Grafik histori tekanan hari ini belum ada data");
    }

    final points = <FlSpot>[];
    double minY = history.first.pressure;
    double maxY = history.first.pressure;

    for (int i = 0; i < history.length; i++) {
      final pressure = history[i].pressure;
      points.add(FlSpot(i.toDouble(), pressure));

      if (pressure < minY) {
        minY = pressure;
      }
      if (pressure > maxY) {
        maxY = pressure;
      }
    }

    final range = (maxY - minY).abs();
    final padding = range < 1 ? 0.5 : range * 0.15;

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
            "Grafik Histori Tekanan Hari Ini",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (history.length - 1).toDouble(),
                minY: minY - padding,
                maxY: maxY + padding,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: range < 1 ? 0.5 : null,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: history.length > 6 ? (history.length / 5).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formatClockTime(history[index].timestamp),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: history.length <= 10),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _HistoryTableCard extends StatefulWidget {
  final List<AtmosphericConditions> history;

  const _HistoryTableCard({required this.history});

  @override
  State<_HistoryTableCard> createState() => _HistoryTableCardState();
}

class _HistoryTableCardState extends State<_HistoryTableCard> {
  static const int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant _HistoryTableCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final totalPages = _totalPages;
    if (totalPages > 0 && _currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
  }

  int get _totalPages {
    if (widget.history.isEmpty) {
      return 0;
    }
    return (widget.history.length / _rowsPerPage).ceil();
  }

  List<AtmosphericConditions> get _pageItems {
    final reversedHistory = widget.history.reversed.toList();
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, reversedHistory.length);
    return reversedHistory.sublist(start, end);
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Tabel histori tekanan hari ini belum ada data",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final pageItems = _pageItems;
    final hasMultiplePages = _totalPages > 1;

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
            "Tabel Histori Tekanan Hari Ini",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Halaman ${_currentPage + 1} dari $_totalPages · ${widget.history.length} data",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("No")),
                DataColumn(label: Text("Waktu")),
                DataColumn(label: Text("Tekanan")),
              ],
              rows: List<DataRow>.generate(pageItems.length, (index) {
                final item = pageItems[index];
                final absoluteIndex = (_currentPage * _rowsPerPage) + index + 1;
                return DataRow(
                  cells: [
                    DataCell(Text(absoluteIndex.toString())),
                    DataCell(Text(formatClockTime(item.timestamp))),
                    DataCell(Text("${item.pressure.toStringAsFixed(1)} hPa")),
                  ],
                );
              }),
            ),
          ),
          if (hasMultiplePages) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _currentPage == 0 ? null : _goToPreviousPage,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Sebelumnya'),
                ),
                TextButton.icon(
                  onPressed: _currentPage >= _totalPages - 1 ? null : _goToNextPage,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Berikutnya'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
