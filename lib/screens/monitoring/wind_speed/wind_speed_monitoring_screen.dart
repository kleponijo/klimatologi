import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/monitoring_shared.dart';
import 'widgets/wind_speed_annual_section.dart';
import 'widgets/wind_speed_explanation.dart';
import 'widgets/wind_speed_graph_block.dart';
import 'widgets/wind_speed_status_block.dart';

class WindSpeedMonitoringScreen extends StatefulWidget {
  const WindSpeedMonitoringScreen({super.key});

  @override
  State<WindSpeedMonitoringScreen> createState() =>
      _WindSpeedMonitoringScreenState();
}

class _WindSpeedMonitoringScreenState extends State<WindSpeedMonitoringScreen> {
  String _selectedPeriod = "Hari Ini";

  // realtime database state
  final DatabaseReference _realtimeRef =
      FirebaseDatabase.instance.ref('anemometer/realtime');
  StreamSubscription<DatabaseEvent>? _realtimeSub;

  // realtime values
  DateTime? _lastUpdateTime;
  double _currentSpeed = 0.0;
  final List<double> _dailySpeeds = List<double>.filled(24, 0.0);

  // hourly aggregation helpers (PRO version)
  double _hourlyTotalSpeed = 0.0;
  int _hourlyCount = 0;
  int _currentHour = DateTime.now().hour;

  bool get _isOnline {
    if (_lastUpdateTime == null) return false;
    final diff = DateTime.now().difference(_lastUpdateTime!);
    return diff.inSeconds <= 5;
  }

  @override
  void initState() {
    super.initState();
    _realtimeSub = _realtimeRef.onValue.listen(_onRealtimeData);
  }

  void _onRealtimeData(DatabaseEvent event) {
    final data = event.snapshot.value;

    if (data is Map) {
      final speed = (data['kecepatan'] ?? 0).toDouble();
      final timestamp = data['timestamp'] ?? 0;

      final waktu = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      setState(() {
        _currentSpeed = speed;
        _lastUpdateTime = waktu;

        final incomingHour = waktu.hour;

        if (incomingHour != _currentHour) {
          if (_hourlyCount > 0) {
            final avg = _hourlyTotalSpeed / _hourlyCount;
            _dailySpeeds[_currentHour] = avg;
          }

          _hourlyTotalSpeed = 0.0;
          _hourlyCount = 0;
          _currentHour = incomingHour;

          if (incomingHour == 0) {
            for (int i = 0; i < 24; i++) {
              _dailySpeeds[i] = 0.0;
            }
          }
        }

        _hourlyTotalSpeed += speed;
        _hourlyCount++;
      });
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  void _handleExportSelectedPeriod(String period) {
    switch (period) {
      case "Hari Ini":
        _exportDailyWindData();
        break;
      case "Minggu Ini":
        _exportWeeklyWindData();
        break;
      case "Bulan Ini":
        _exportMonthlyWindData();
        break;
    }
  }

  void _exportDailyWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - HARIAN (24 JAM)");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Jam,Kecepatan (km/h)");

    final dailyData = [
      5.0,
      5.2,
      4.8,
      4.5,
      4.3,
      4.6,
      5.1,
      6.0,
      7.2,
      8.5,
      9.0,
      10.2,
      11.0,
      10.5,
      10.0,
      9.2,
      8.0,
      6.5,
      5.5,
      5.0,
      4.8,
      4.5,
      5.0,
      5.2
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

    showExportPreview(
        context, csvContent.toString(), "Data Harian Kecepatan Angin");
  }

  void _exportWeeklyWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - MINGGUAN");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Hari,Rata-rata (km/h)");

    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
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

    showExportPreview(
        context, csvContent.toString(), "Data Mingguan Kecepatan Angin");
  }

  void _exportMonthlyWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - BULANAN");
    csvContent.writeln(
        "Bulan: ${DateTime.now().toString().split(' ')[0].substring(0, 7)}");
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

    showExportPreview(
        context, csvContent.toString(), "Data Bulanan Kecepatan Angin");
  }

  void _exportAnnualWindData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING KECEPATAN ANGIN - TAHUNAN");
    csvContent.writeln("Tahun: 2025");
    csvContent.writeln("");
    csvContent.writeln("Bulan,Rata-rata (km/h),Kecepatan Max (km/h)");

    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final averages = [
      5.5,
      6.2,
      6.8,
      7.5,
      7.8,
      8.0,
      8.2,
      8.0,
      7.2,
      6.5,
      5.8,
      5.2
    ];
    final maxSpeed = [
      12.0,
      13.5,
      14.0,
      15.5,
      16.0,
      16.2,
      16.5,
      16.0,
      15.0,
      14.0,
      12.5,
      11.0
    ];

    for (int i = 0; i < months.length; i++) {
      csvContent.writeln("${months[i]},${averages[i]},${maxSpeed[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("STATISTIK TAHUNAN");
    csvContent.writeln("Rata-rata Tahunan: 7.1 km/h");
    csvContent.writeln("Kecepatan Max Tertinggi: 16.5 km/h");
    csvContent.writeln("Kecepatan Min Terendah: 5.2 km/h");

    showExportPreview(
        context, csvContent.toString(), "Data Tahunan Kecepatan Angin");
  }

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
              if (_lastUpdateTime != null)
                WindSpeedStatusBlock(
                  currentSpeed: _currentSpeed,
                  isOnline: _isOnline,
                  lastUpdateTime: _lastUpdateTime!,
                ),
              WindSpeedGraphBlock(
                selectedPeriod: _selectedPeriod,
                dailySpeeds: _dailySpeeds,
                isOnline: _isOnline,
                onPeriodChanged: (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
                onExportPressed: _handleExportSelectedPeriod,
              ),
              const SizedBox(height: 25),
              const WindSpeedExplanation(),
              const SizedBox(height: 25),
              WindSpeedAnnualSection(
                onExportAnnual: _exportAnnualWindData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
