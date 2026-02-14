import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../monitoring/evaporasi_monitoring_screen.dart';
import '../../monitoring/wind_speed_monitoring_screen.dart';
import '../../monitoring/air_quality_monitoring_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Klimatologi"),
        centerTitle: true,
      ),

      /// 🔹 SIDEBAR (MENU 3 GARIS DI KIRI)
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 🔹 HEADER DENGAN AKUN INFO
              UserAccountsDrawerHeader(
                accountName: const Text(
                  "Admin Klimatologi",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: const Text("admin@klimatologi.com"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: const Text(
                    "A",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 🔹 DASHBOARD MENU
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Dashboard"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Divider(),

              // 🔹 MONITORING MENU
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Monitoring",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),

              _buildDrawerItem(
                context,
                "Evaporasi",
                Icons.opacity,
              ),
              _buildDrawerItem(
                context,
                "Kecepatan Angin",
                Icons.air,
              ),
              _buildDrawerItem(
                context,
                "Kualitas Udara",
                Icons.cloud,
              ),
            ],
          ),
        ),
      ),

      /// 🔹 DASHBOARD UTAMA - 3 MONITORING
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Selamat Datang Admin Klimatologi",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 3 BLOCK DATA HARI INI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataBlock(
                    "Evaporasi",
                    "45.2",
                    "mm",
                    Colors.blue,
                    Icons.opacity,
                  ),
                  _buildDataBlock(
                    "Kec. Angin",
                    "12.5",
                    "km/h",
                    Colors.green,
                    Icons.air,
                  ),
                  _buildDataBlock(
                    "Kualitas Udara",
                    "78",
                    "AQI",
                    Colors.orange,
                    Icons.cloud,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Grafik Monitoring",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              _buildDashboardCard(context, "Evaporasi"),
              const SizedBox(height: 20),
              _buildDashboardCard(context, "Kecepatan Angin"),
              const SizedBox(height: 20),
              _buildDashboardCard(context, "Kualitas Udara"),
            ],
          ),
        ),
      ),
    );
  }

  /// DATA BLOCK - PREVIEW DATA HARI INI
  Widget _buildDataBlock(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// DRAWER ITEM
  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Widget screen;
        if (title == "Evaporasi") {
          screen = const EvaporasiMonitoringScreen();
        } else if (title == "Kecepatan Angin") {
          screen = const WindSpeedMonitoringScreen();
        } else if (title == "Kualitas Udara") {
          screen = const AirQualityMonitoringScreen();
        } else {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }

  /// DASHBOARD CARD - PREVIEW GRAFIK 24 JAM
  Widget _buildDashboardCard(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        Widget screen;
        if (title == "Evaporasi") {
          screen = const EvaporasiMonitoringScreen();
        } else if (title == "Kecepatan Angin") {
          screen = const WindSpeedMonitoringScreen();
        } else if (title == "Kualitas Udara") {
          screen = const AirQualityMonitoringScreen();
        } else {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Card(
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "24 Jam",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
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
                          interval: 3,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}h',
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
                        spots: _getMonitoringData(title),
                        isCurved: true,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: _getColorByTitle(title),
                              strokeWidth: 0,
                            );
                          },
                        ),
                        color: _getColorByTitle(title),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _getColorByTitle(title).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rata-rata: ${_getAverageData(title)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Tap untuk detail",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// GET MONITORING DATA FOR 24 HOURS
  List<FlSpot> _getMonitoringData(String title) {
    final dataMap = {
      "Evaporasi": [
        2.1, 2.3, 2.0, 1.9, 2.2, 2.5, 3.0, 3.5, 4.0, 4.2,
        4.5, 4.8, 5.0, 5.2, 5.1, 4.9, 4.5, 4.0, 3.5, 3.0, 2.8, 2.5, 2.3, 2.2
      ],
      "Kecepatan Angin": [
        5.0, 5.2, 4.8, 4.5, 4.3, 4.6, 5.1, 6.0, 7.2, 8.5,
        9.0, 10.2, 11.0, 10.5, 10.0, 9.2, 8.0, 6.5, 5.5, 5.0, 4.8, 4.5, 5.0, 5.2
      ],
      "Kualitas Udara": [
        68.0, 70.0, 72.0, 75.0, 78.0, 80.0, 78.0, 75.0, 72.0, 70.0,
        68.0, 65.0, 60.0, 58.0, 60.0, 62.0, 65.0, 68.0, 70.0, 72.0, 75.0, 78.0, 76.0, 74.0
      ],
    };

    final data = dataMap[title] ?? [];
    return List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index]),
    );
  }

  /// GET AVERAGE VALUE
  String _getAverageData(String title) {
    final dataMap = {
      "Evaporasi": "3.5 mm",
      "Kecepatan Angin": "6.8 km/h",
      "Kualitas Udara": "70 AQI",
    };
    return dataMap[title] ?? "N/A";
  }

  /// GET COLOR BY TITLE
  Color _getColorByTitle(String title) {
    switch (title) {
      case "Evaporasi":
        return Colors.blue;
      case "Kecepatan Angin":
        return Colors.green;
      case "Kualitas Udara":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
