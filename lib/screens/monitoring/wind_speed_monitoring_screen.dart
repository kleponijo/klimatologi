import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/monitoring_shared.dart';

/// WIND SPEED MONITORING SCREEN
class WindSpeedMonitoringScreen extends StatefulWidget {
  const WindSpeedMonitoringScreen({super.key});

  @override
  State<WindSpeedMonitoringScreen> createState() => _WindSpeedMonitoringScreenState();
}

class _WindSpeedMonitoringScreenState extends State<WindSpeedMonitoringScreen> {
  String _selectedPeriod = "Hari Ini";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Kecepatan Angin"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kecepatan Angin",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              /// GRAFIK MONITORING
              _buildMonitoringGraphBlock(),
              const SizedBox(height: 25),

              /// PENJELASAN
              _buildWindSpeedExplanation(),
              const SizedBox(height: 25),

              /// STATISTIK TAHUNAN
              _buildAnnualWindGraphSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// EXPORT FUNCTIONS
  void _exportDailyWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - HARIAN (24 JAM)");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Jam,Kecepatan (km/h)");

    final dailyData = [
      5.0, 5.2, 4.8, 4.5, 4.3, 4.6, 5.1, 6.0, 7.2, 8.5,
      9.0, 10.2, 11.0, 10.5, 10.0, 9.2, 8.0, 6.5, 5.5, 5.0, 4.8, 4.5, 5.0, 5.2
    ];
    for (int i = 0; i < dailyData.length; i++) {
      csvContent.writeln("$i:00,${dailyData[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Harian");
    csvContent.writeln("Total: 165.8 km/h");
    csvContent.writeln("Rata-rata: 6.9 km/h");
    csvContent.writeln("Maksimal: 11.0 km/h");
    csvContent.writeln("Minimal: 4.3 km/h");

    showExportPreview(context, csvContent.toString(), "Data Harian Kecepatan Angin");
  }

  void _exportWeeklyWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - MINGGUAN");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Hari,Rata-rata (km/h)");

    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final weeklyData = [6.5, 7.2, 7.8, 8.0, 7.5, 6.8, 5.5];

    for (int i = 0; i < days.length; i++) {
      csvContent.writeln("${days[i]},${weeklyData[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Mingguan");
    csvContent.writeln("Total: 49.3 km/h");
    csvContent.writeln("Rata-rata: 7.0 km/h");
    csvContent.writeln("Maksimal: 8.0 km/h");
    csvContent.writeln("Minimal: 5.5 km/h");

    showExportPreview(context, csvContent.toString(), "Data Mingguan Kecepatan Angin");
  }

  void _exportMonthlyWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - BULANAN");
    csvContent.writeln("Bulan: ${DateTime.now().toString().split(' ')[0].substring(0, 7)}");
    csvContent.writeln("");
    csvContent.writeln("Tanggal,Rata-rata (km/h)");

    for (int i = 1; i <= 28; i++) {
      final value = (6.0 + (i % 6) * 0.8).toStringAsFixed(1);
      csvContent.writeln("$i,$value");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Bulanan");
    csvContent.writeln("Total: 180.5 km/h");
    csvContent.writeln("Rata-rata: 6.4 km/h");
    csvContent.writeln("Maksimal: 9.0 km/h");
    csvContent.writeln("Minimal: 4.0 km/h");

    showExportPreview(context, csvContent.toString(), "Data Bulanan Kecepatan Angin");
  }

  void _exportAnnualWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - TAHUNAN");
    csvContent.writeln("Tahun: 2025");
    csvContent.writeln("");
    csvContent.writeln("Bulan,Rata-rata (km/h),Kecepatan Max (km/h)");

    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final averages = [5.5, 6.2, 6.8, 7.5, 7.8, 8.0, 8.2, 8.0, 7.2, 6.5, 5.8, 5.2];
    final maxSpeed = [12.0, 13.5, 14.0, 15.5, 16.0, 16.2, 16.5, 16.0, 15.0, 14.0, 12.5, 11.0];

    for (int i = 0; i < months.length; i++) {
      csvContent.writeln("${months[i]},${averages[i]},${maxSpeed[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("STATISTIK TAHUNAN");
    csvContent.writeln("Rata-rata Tahunan: 7.1 km/h");
    csvContent.writeln("Kecepatan Max Tertinggi: 16.5 km/h");
    csvContent.writeln("Kecepatan Min Terendah: 5.2 km/h");

    showExportPreview(context, csvContent.toString(), "Data Tahunan Kecepatan Angin");
  }

  /// DATA GENERATORS
  List<FlSpot> _getWindSpeedPeriodData() {
    switch (_selectedPeriod) {
      case "Hari Ini":
        return List.generate(24, (i) {
          final values = [
            5.0, 5.2, 4.8, 4.5, 4.3, 4.6, 5.1, 6.0, 7.2, 8.5,
            9.0, 10.2, 11.0, 10.5, 10.0, 9.2, 8.0, 6.5, 5.5, 5.0, 4.8, 4.5, 5.0, 5.2
          ];
          return FlSpot(i.toDouble(), values[i]);
        });
      case "Minggu Ini":
        return [
          const FlSpot(0, 6.5),
          const FlSpot(1, 7.2),
          const FlSpot(2, 7.8),
          const FlSpot(3, 8.0),
          const FlSpot(4, 7.5),
          const FlSpot(5, 6.8),
          const FlSpot(6, 5.5),
        ];
      case "Bulan Ini":
        return [
          const FlSpot(0, 6.0),
          const FlSpot(1, 6.5),
          const FlSpot(2, 7.0),
          const FlSpot(3, 7.5),
          const FlSpot(4, 7.8),
          const FlSpot(5, 8.0),
          const FlSpot(6, 8.2),
          const FlSpot(7, 8.0),
          const FlSpot(8, 7.5),
          const FlSpot(9, 7.0),
          const FlSpot(10, 6.5),
          const FlSpot(11, 6.0),
        ];
      default:
        return [];
    }
  }

  /// UI BUILDERS
  Widget _buildMonitoringGraphBlock() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Status Kecepatan Angin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Normal",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// PERIOD SELECTOR + EXPORT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["Hari Ini", "Minggu Ini", "Bulan Ini"].map((period) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(period),
                            selected: _selectedPeriod == period,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPeriod = period;
                              });
                            },
                            selectedColor: Colors.green,
                            labelStyle: TextStyle(
                              color: _selectedPeriod == period
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedPeriod == "Hari Ini") {
                      _exportDailyWindData();
                    } else if (_selectedPeriod == "Minggu Ini") {
                      _exportWeeklyWindData();
                    } else if (_selectedPeriod == "Bulan Ini") {
                      _exportMonthlyWindData();
                    }
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text("Export"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// GRAPH
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: getPeriodInterval(_selectedPeriod),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            getPeriodLabel(_selectedPeriod, value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getWindSpeedPeriodData(),
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.green,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindSpeedExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Penjelasan Kecepatan Angin",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Kecepatan angin adalah laju gerakan massa udara yang mengalir secara horizontal. Data kecepatan angin penting untuk prediksi cuaca, manajemen rawan angin, perencanaan energi terbarukan (angin), serta membantu dalam pengeringan hasil pertanian. Pengukuran dilakukan dalam satuan km/h.",
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualWindGraphSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistik Tahunan Kecepatan Angin",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        /// STATS
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: "Rata-rata Tahunan",
                value: "7.1 km/h",
                color: Colors.green,
                icon: Icons.air,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: "Kecepatan Max",
                value: "16.5 km/h",
                color: Colors.red,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        /// CHART
        const Text(
          "Grafik Tahunan - Rata-rata & Kecepatan Maksimal",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 320,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                            'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
                          ];
                          return Text(
                            months[value.toInt()],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()} km/h',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    /// Rata-rata
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 5.5),
                        FlSpot(1, 6.2),
                        FlSpot(2, 6.8),
                        FlSpot(3, 7.5),
                        FlSpot(4, 7.8),
                        FlSpot(5, 8.0),
                        FlSpot(6, 8.2),
                        FlSpot(7, 8.0),
                        FlSpot(8, 7.2),
                        FlSpot(9, 6.5),
                        FlSpot(10, 5.8),
                        FlSpot(11, 5.2),
                      ],
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.green,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    /// Max Speed
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 12.0),
                        FlSpot(1, 13.5),
                        FlSpot(2, 14.0),
                        FlSpot(3, 15.5),
                        FlSpot(4, 16.0),
                        FlSpot(5, 16.2),
                        FlSpot(6, 16.5),
                        FlSpot(7, 16.0),
                        FlSpot(8, 15.0),
                        FlSpot(9, 14.0),
                        FlSpot(10, 12.5),
                        FlSpot(11, 11.0),
                      ],
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.red,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        /// LEGEND
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Rata-rata (km/h)",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 20),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Kecepatan Max (km/h)",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _exportAnnualWindData(),
            icon: const Icon(Icons.file_download),
            label: const Text("Download Excel Tahunan"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
