import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../../../blocs/authentication_bloc/authentication_bloc.dart';
import '../../monitoring/evaporasi_monitoring_screen.dart';
import '../../monitoring/wind_speed_monitoring_screen.dart';
import '../../monitoring/air_quality_monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase realtime database references
  final DatabaseReference _evaporasiRef = FirebaseDatabase.instance.ref('evaporasi/realtime');
  final DatabaseReference _windSpeedRef = FirebaseDatabase.instance.ref('anemometer/realtime');
  final DatabaseReference _airQualityRef = FirebaseDatabase.instance.ref('air_quality/realtime');

  // Stream subscriptions
  StreamSubscription<DatabaseEvent>? _evaporasiSub;
  StreamSubscription<DatabaseEvent>? _windSpeedSub;
  StreamSubscription<DatabaseEvent>? _airQualitySub;

  // Realtime values
  double _currentEvaporasi = 0.0;
  double _currentWindSpeed = 0.0;
  double _currentAirQuality = 0.0;
  
  DateTime? _evaporasiUpdateTime;
  DateTime? _windSpeedUpdateTime;
  DateTime? _airQualityUpdateTime;

  // Hourly data for charts (24 hours)
  final List<double> _evaporasiData = List<double>.filled(24, 0.0);
  final List<double> _windSpeedData = List<double>.filled(24, 0.0);
  final List<double> _airQualityData = List<double>.filled(24, 0.0);

  // Hourly aggregation helpers
  double _evaporasiHourlyTotal = 0.0;
  int _evaporasiHourlyCount = 0;
  
  double _windSpeedHourlyTotal = 0.0;
  int _windSpeedHourlyCount = 0;
  
  double _airQualityHourlyTotal = 0.0;
  int _airQualityHourlyCount = 0;
  
  int _currentHour = DateTime.now().hour;

  @override
  void initState() {
    super.initState();
    _evaporasiSub = _evaporasiRef.onValue.listen(_onEvaporasiData);
    _windSpeedSub = _windSpeedRef.onValue.listen(_onWindSpeedData);
    _airQualitySub = _airQualityRef.onValue.listen(_onAirQualityData);
  }

  void _onEvaporasiData(DatabaseEvent event) {
    final data = event.snapshot.value;
    if (data is Map) {
      final value = (data['nilai'] ?? 0).toDouble();
      final timestamp = data['timestamp'] ?? 0;
      final waktu = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      setState(() {
        _currentEvaporasi = value;
        _evaporasiUpdateTime = waktu;

        final incomingHour = waktu.hour;

        if (incomingHour != _currentHour) {
          if (_evaporasiHourlyCount > 0) {
            final avg = _evaporasiHourlyTotal / _evaporasiHourlyCount;
            _evaporasiData[_currentHour] = avg;
          }

          _evaporasiHourlyTotal = 0.0;
          _evaporasiHourlyCount = 0;

          _currentHour = incomingHour;

          if (incomingHour == 0) {
            for (int i = 0; i < 24; i++) {
              _evaporasiData[i] = 0.0;
            }
          }
        }

        _evaporasiHourlyTotal += value;
        _evaporasiHourlyCount++;
      });
    }
  }

  void _onWindSpeedData(DatabaseEvent event) {
    final data = event.snapshot.value;
    if (data is Map) {
      final value = (data['kecepatan'] ?? 0).toDouble();
      final timestamp = data['timestamp'] ?? 0;
      final waktu = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      setState(() {
        _currentWindSpeed = value;
        _windSpeedUpdateTime = waktu;

        final incomingHour = waktu.hour;

        if (incomingHour != _currentHour) {
          if (_windSpeedHourlyCount > 0) {
            final avg = _windSpeedHourlyTotal / _windSpeedHourlyCount;
            _windSpeedData[_currentHour] = avg;
          }

          _windSpeedHourlyTotal = 0.0;
          _windSpeedHourlyCount = 0;

          _currentHour = incomingHour;

          if (incomingHour == 0) {
            for (int i = 0; i < 24; i++) {
              _windSpeedData[i] = 0.0;
            }
          }
        }

        _windSpeedHourlyTotal += value;
        _windSpeedHourlyCount++;
      });
    }
  }

  void _onAirQualityData(DatabaseEvent event) {
    final data = event.snapshot.value;
    if (data is Map) {
      final value = (data['aqi'] ?? 0).toDouble();
      final timestamp = data['timestamp'] ?? 0;
      final waktu = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      setState(() {
        _currentAirQuality = value;
        _airQualityUpdateTime = waktu;

        final incomingHour = waktu.hour;

        if (incomingHour != _currentHour) {
          if (_airQualityHourlyCount > 0) {
            final avg = _airQualityHourlyTotal / _airQualityHourlyCount;
            _airQualityData[_currentHour] = avg;
          }

          _airQualityHourlyTotal = 0.0;
          _airQualityHourlyCount = 0;

          _currentHour = incomingHour;

          if (incomingHour == 0) {
            for (int i = 0; i < 24; i++) {
              _airQualityData[i] = 0.0;
            }
          }
        }

        _airQualityHourlyTotal += value;
        _airQualityHourlyCount++;
      });
    }
  }

  @override
  void dispose() {
    _evaporasiSub?.cancel();
    _windSpeedSub?.cancel();
    _airQualitySub?.cancel();
    super.dispose();
  }

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
              // 🔹 HEADER DENGAN AKUN INFO (dynamic dari AuthenticationBloc)
              BlocBuilder<AuthenticationBloc, AuthenticationState>(
                builder: (context, state) {
                  final user = state.user;
                  final displayName = (user != null && user.name.isNotEmpty)
                      ? user.name
                      : 'Pengguna';
                  final email = (user != null && user.email.isNotEmpty)
                      ? user.email
                      : 'Tidak ada email';
                  final initials = (displayName.isNotEmpty)
                      ? displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                      : 'U';

                  return UserAccountsDrawerHeader(
                    accountName: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    accountEmail: Text(email),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
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
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  // trigger logout via bloc
                  final bloc = context.read<AuthenticationBloc>();
                  bloc.add(const AuthenticationLogoutRequested());
                },
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
              BlocBuilder<AuthenticationBloc, AuthenticationState>(
                builder: (context, state) {
                  final name = state.user?.name.isNotEmpty == true
                      ? state.user!.name
                      : 'Pengguna';
                  return Text(
                    'Selamat Datang $name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 🔹 3 BLOCK DATA HARI INI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataBlock(
                    "Evaporasi",
                    _currentEvaporasi.toStringAsFixed(1),
                    "mm",
                    Colors.blue,
                    Icons.opacity,
                  ),
                  _buildDataBlock(
                    "Kec. Angin",
                    _currentWindSpeed.toStringAsFixed(1),
                    "km/h",
                    Colors.green,
                    Icons.air,
                  ),
                  _buildDataBlock(
                    "Kualitas Udara",
                    _currentAirQuality.toStringAsFixed(0),
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
    late final List<double> data;
    
    switch (title) {
      case "Evaporasi":
        data = _evaporasiData;
        break;
      case "Kecepatan Angin":
        data = _windSpeedData;
        break;
      case "Kualitas Udara":
        data = _airQualityData;
        break;
      default:
        data = [];
    }

    return List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index]),
    );
  }

  /// GET AVERAGE VALUE
  String _getAverageData(String title) {
    late final double average;
    late final String unit;
    
    switch (title) {
      case "Evaporasi":
        average = _evaporasiData.isNotEmpty 
            ? _evaporasiData.reduce((a, b) => a + b) / _evaporasiData.length 
            : 0.0;
        unit = "mm";
        break;
      case "Kecepatan Angin":
        average = _windSpeedData.isNotEmpty 
            ? _windSpeedData.reduce((a, b) => a + b) / _windSpeedData.length 
            : 0.0;
        unit = "km/h";
        break;
      case "Kualitas Udara":
        average = _airQualityData.isNotEmpty 
            ? _airQualityData.reduce((a, b) => a + b) / _airQualityData.length 
            : 0.0;
        unit = "AQI";
        break;
      default:
        return "N/A";
    }
    
    return "${average.toStringAsFixed(1)} $unit";
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
