import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/monitoring_shared.dart';

/// AIR QUALITY MONITORING SCREEN
class AirQualityMonitoringScreen extends StatefulWidget {
  const AirQualityMonitoringScreen({super.key});

  @override
  State<AirQualityMonitoringScreen> createState() => _AirQualityMonitoringScreenState();
}

class _AirQualityMonitoringScreenState extends State<AirQualityMonitoringScreen> {
  String _selectedPeriod = "Hari Ini";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Kualitas Udara"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kualitas Udara",
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
              _buildAirQualityExplanation(),
              const SizedBox(height: 25),

              /// STATISTIK TAHUNAN
              _buildAnnualAirQualityGraphSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// EXPORT FUNCTIONS
  void _exportDailyAirQualityData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KUALITAS UDARA - HARIAN (24 JAM)");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Jam,AQI (Air Quality Index)");

    final dailyData = [
      68.0, 70.0, 72.0, 75.0, 78.0, 80.0, 78.0, 75.0, 72.0, 70.0,
      68.0, 65.0, 60.0, 58.0, 60.0, 62.0, 65.0, 68.0, 70.0, 72.0, 75.0, 78.0, 76.0, 74.0
    ];
    for (int i = 0; i < dailyData.length; i++) {
      csvContent.writeln("$i:00,${dailyData[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Harian");
    csvContent.writeln("Total: 1709 AQI");
    csvContent.writeln("Rata-rata: 71.2 AQI");
    csvContent.writeln("Maksimal: 80 AQI");
    csvContent.writeln("Minimal: 58 AQI");

    showExportPreview(context, csvContent.toString(), "Data Harian Kualitas Udara");
  }

  void _exportWeeklyAirQualityData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KUALITAS UDARA - MINGGUAN");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Hari,Rata-rata AQI");

    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final weeklyData = [68.0, 72.0, 75.0, 78.0, 72.0, 68.0, 62.0];

    for (int i = 0; i < days.length; i++) {
      csvContent.writeln("${days[i]},${weeklyData[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Mingguan");
    csvContent.writeln("Total: 495 AQI");
    csvContent.writeln("Rata-rata: 70.7 AQI");
    csvContent.writeln("Maksimal: 78 AQI");
    csvContent.writeln("Minimal: 62 AQI");

    showExportPreview(context, csvContent.toString(), "Data Mingguan Kualitas Udara");
  }

  void _exportMonthlyAirQualityData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KUALITAS UDARA - BULANAN");
    csvContent.writeln("Bulan: ${DateTime.now().toString().split(' ')[0].substring(0, 7)}");
    csvContent.writeln("");
    csvContent.writeln("Tanggal,Rata-rata AQI");

    for (int i = 1; i <= 28; i++) {
      final value = (70.0 + (i % 6) * 2.5).toStringAsFixed(1);
      csvContent.writeln("$i,$value");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Bulanan");
    csvContent.writeln("Total: 1990 AQI");
    csvContent.writeln("Rata-rata: 71.1 AQI");
    csvContent.writeln("Maksimal: 82 AQI");
    csvContent.writeln("Minimal: 55 AQI");

    showExportPreview(context, csvContent.toString(), "Data Bulanan Kualitas Udara");
  }

  void _exportAnnualAirQualityData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KUALITAS UDARA - TAHUNAN");
    csvContent.writeln("Tahun: 2025");
    csvContent.writeln("");
    csvContent.writeln("Bulan,Rata-rata AQI,AQI Max");

    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final averages = [68.0, 70.0, 72.5, 75.0, 78.0, 80.0, 82.0, 80.0, 75.0, 70.0, 68.0, 65.0];
    final maxAqi = [85.0, 88.0, 90.0, 95.0, 98.0, 100.0, 102.0, 100.0, 95.0, 90.0, 85.0, 80.0];

    for (int i = 0; i < months.length; i++) {
      csvContent.writeln("${months[i]},${averages[i]},${maxAqi[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("STATISTIK TAHUNAN");
    csvContent.writeln("Rata-rata Tahunan: 74.2 AQI");
    csvContent.writeln("AQI Max Teringgi: 102.0");
    csvContent.writeln("AQI Min Terendah: 65.0");

    showExportPreview(context, csvContent.toString(), "Data Tahunan Kualitas Udara");
  }

  /// DATA GENERATORS
  List<FlSpot> _getAirQualityPeriodData() {
    switch (_selectedPeriod) {
      case "Hari Ini":
        return List.generate(24, (i) {
          final values = [
            68.0, 70.0, 72.0, 75.0, 78.0, 80.0, 78.0, 75.0, 72.0, 70.0,
            68.0, 65.0, 60.0, 58.0, 60.0, 62.0, 65.0, 68.0, 70.0, 72.0, 75.0, 78.0, 76.0, 74.0
          ];
          return FlSpot(i.toDouble(), values[i]);
        });
      case "Minggu Ini":
        return [
          const FlSpot(0, 68.0),
          const FlSpot(1, 72.0),
          const FlSpot(2, 75.0),
          const FlSpot(3, 78.0),
          const FlSpot(4, 72.0),
          const FlSpot(5, 68.0),
          const FlSpot(6, 62.0),
        ];
      case "Bulan Ini":
        return [
          const FlSpot(0, 70.0),
          const FlSpot(1, 72.5),
          const FlSpot(2, 75.0),
          const FlSpot(3, 77.5),
          const FlSpot(4, 80.0),
          const FlSpot(5, 82.0),
          const FlSpot(6, 80.0),
          const FlSpot(7, 78.0),
          const FlSpot(8, 75.0),
          const FlSpot(9, 72.0),
          const FlSpot(10, 70.0),
          const FlSpot(11, 68.0),
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
                  "Status Kualitas Udara",
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
                            selectedColor: Colors.orange,
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
                      _exportDailyAirQualityData();
                    } else if (_selectedPeriod == "Minggu Ini") {
                      _exportWeeklyAirQualityData();
                    } else if (_selectedPeriod == "Bulan Ini") {
                      _exportMonthlyAirQualityData();
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
                      spots: _getAirQualityPeriodData(),
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.orange,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.orange,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.1),
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

  Widget _buildAirQualityExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Penjelasan Kualitas Udara",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Kualitas udara diukur menggunakan Air Quality Index (AQI) yang menunjukkan tingkat polusi udara. AQI berkisar dari 0-500, dengan nilai lebih rendah menunjukkan udara lebih bersih. Monitoring kualitas udara penting untuk kesehatan masyarakat, perencanaan lingkungan, dan identifikasi sumber polusi. Kategori: 0-50 (Baik), 51-100 (Wajar), 101-150 (Tidak Sehat), 151+ (Sangat Tidak Sehat).",
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualAirQualityGraphSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistik Tahunan Kualitas Udara",
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
                value: "74.2 AQI",
                color: Colors.orange,
                icon: Icons.cloud,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: "AQI Maksimal",
                value: "102.0",
                color: Colors.red,
                icon: Icons.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        /// CHART
        const Text(
          "Grafik Tahunan - Rata-rata & AQI Maksimal",
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
                    horizontalInterval: 5,
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
                            '${value.toInt()} AQI',
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
                        FlSpot(0, 68.0),
                        FlSpot(1, 70.0),
                        FlSpot(2, 72.5),
                        FlSpot(3, 75.0),
                        FlSpot(4, 78.0),
                        FlSpot(5, 80.0),
                        FlSpot(6, 82.0),
                        FlSpot(7, 80.0),
                        FlSpot(8, 75.0),
                        FlSpot(9, 70.0),
                        FlSpot(10, 68.0),
                        FlSpot(11, 65.0),
                      ],
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.orange,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.orange,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.1),
                      ),
                    ),
                    /// AQI Max
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 85.0),
                        FlSpot(1, 88.0),
                        FlSpot(2, 90.0),
                        FlSpot(3, 95.0),
                        FlSpot(4, 98.0),
                        FlSpot(5, 100.0),
                        FlSpot(6, 102.0),
                        FlSpot(7, 100.0),
                        FlSpot(8, 95.0),
                        FlSpot(9, 90.0),
                        FlSpot(10, 85.0),
                        FlSpot(11, 80.0),
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
                color: Colors.orange,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Rata-rata AQI",
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
              "AQI Maksimal",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _exportAnnualAirQualityData(),
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
