import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'widgets/monitoring_shared.dart';

/// EVAPORASI MONITORING SCREEN
class EvaporasiMonitoringScreen extends StatefulWidget {
  const EvaporasiMonitoringScreen({super.key});

  @override
  State<EvaporasiMonitoringScreen> createState() =>
      _EvaporasiMonitoringScreenState();
}

class _EvaporasiMonitoringScreenState extends State<EvaporasiMonitoringScreen> {
  String _selectedPeriod = "Hari Ini";

  final DatabaseReference _evaporationRef =
      FirebaseDatabase.instance.ref('kelompok1/evaporasi');
  StreamSubscription<DatabaseEvent>? _evaporationSub;

  DateTime? _lastUpdateTime;
  double _currentEvaporation = 0.0;
  double _currentTemperature = 0.0;
  double _currentWaterHeight = 0.0;
  final List<double> _dailyEvaporation = List<double>.filled(24, 0.0);
  double _hourlyTotal = 0.0;
  int _hourlyCount = 0;
  int _currentHour = DateTime.now().hour;

  bool get _isOnline {
    if (_lastUpdateTime == null) return false;
    final diff = DateTime.now().difference(_lastUpdateTime!);
    return diff.inMinutes <= 5;
  }

  @override
  void initState() {
    super.initState();
    _evaporationSub = _evaporationRef.onValue.listen(_onRealtimeData);
  }

  @override
  void dispose() {
    _evaporationSub?.cancel();
    super.dispose();
  }

  void _onRealtimeData(DatabaseEvent event) {
    final data = event.snapshot.value;
    if (data is Map) {
      final value = double.tryParse(
              (data['evaporasi'] ?? data['nilai'] ?? 0).toString()) ??
          0.0;
      final temp = double.tryParse(data['suhu']?.toString() ?? '0') ?? 0.0;
      final waterHeight =
          double.tryParse(data['tinggi_air']?.toString() ?? '0') ?? 0.0;
      final DateTime waktu;

      if (data.containsKey('timestamp')) {
        final timestamp =
            int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0;
        waktu = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        final hour = int.tryParse(data['jam']?.toString() ?? '0') ?? 0;
        final minute = int.tryParse(data['menit']?.toString() ?? '0') ?? 0;
        final now = DateTime.now();
        waktu = DateTime(now.year, now.month, now.day, hour, minute);
      }

      setState(() {
        _currentEvaporation = value;
        _currentTemperature = temp;
        _currentWaterHeight = waterHeight;
        _lastUpdateTime = waktu;

        final incomingHour = waktu.hour;
        if (incomingHour != _currentHour) {
          if (_hourlyCount > 0) {
            _dailyEvaporation[_currentHour] = _hourlyTotal / _hourlyCount;
          }
          _hourlyTotal = 0.0;
          _hourlyCount = 0;
          _currentHour = incomingHour;
          if (incomingHour == 0) {
            for (int i = 0; i < 24; i++) {
              _dailyEvaporation[i] = 0.0;
            }
          }
        }

        _hourlyTotal += value;
        _hourlyCount++;
        _dailyEvaporation[incomingHour] =
            _hourlyCount > 0 ? _hourlyTotal / _hourlyCount : value;
      });
    }
  }

  String _formatUpdateTime() {
    if (_lastUpdateTime == null) return '-';
    return DateFormat('dd MMM yyyy • HH:mm').format(_lastUpdateTime!);
  }

  bool get _hasRealtimeEvaporation =>
      _dailyEvaporation.any((value) => value > 0.0);

  Widget _buildDetailTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Evaporasi"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Evaporasi",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_lastUpdateTime != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_currentEvaporation.toStringAsFixed(1)} mm",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Terakhir diperbarui",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatUpdateTime(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isOnline ? 'OFFLINE' : 'ONLINE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isOnline ? const Color.fromARGB(255, 175, 76, 76) : const Color.fromARGB(255, 89, 244, 54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Sensor Evaporasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailTile(
                            label: 'Jam',
                            value: DateFormat('HH:mm').format(_lastUpdateTime!),
                            icon: Icons.access_time,
                            color: Colors.blue,
                          ),
                          _buildDetailTile(
                            label: 'Suhu',
                            value:
                                '${_currentTemperature.toStringAsFixed(2)} °C',
                            icon: Icons.thermostat,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailTile(
                            label: 'Tinggi Air',
                            value: '${_currentWaterHeight.toStringAsFixed(2)}',
                            icon: Icons.water_drop,
                            color: Colors.blueAccent,
                          ),
                          _buildDetailTile(
                            label: 'Evaporasi',
                            value:
                                '${_currentEvaporation.toStringAsFixed(1)} mm',
                            icon: Icons.opacity,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// SISTEM KONTROL AIR OTOMATIS
              _buildAutomaticWaterControlSystem(),
              const SizedBox(height: 25),

              /// GRAFIK MONITORING
              _buildMonitoringGraphBlock(),
              const SizedBox(height: 25),

              /// PENJELASAN
              _buildMonitoringExplanation(),
              const SizedBox(height: 25),

              /// STATISTIK TAHUNAN
              _buildAnnualCombinedGraphSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// EXPORT FUNCTIONS
  void _exportDailyData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING EVAPORASI - HARIAN (24 JAM)");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Jam,Nilai (mm)");

    final dailyData = [
      2.1,
      2.3,
      2.0,
      1.9,
      2.2,
      2.5,
      3.0,
      3.5,
      4.0,
      4.2,
      4.5,
      4.8,
      5.0,
      5.2,
      5.1,
      4.9,
      4.5,
      4.0,
      3.5,
      3.0,
      2.8,
      2.5,
      2.3,
      2.2
    ];
    for (int i = 0; i < dailyData.length; i++) {
      csvContent.writeln("$i:00,${dailyData[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Harian");
    csvContent.writeln("Total: 79.4 mm");
    csvContent.writeln("Rata-rata: 3.3 mm");
    csvContent.writeln("Maksimal: 5.2 mm");
    csvContent.writeln("Minimal: 1.9 mm");

    showExportPreview(context, csvContent.toString(), "Data Harian");
  }

  void _exportWeeklyData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING EVAPORASI - MINGGUAN");
    csvContent.writeln("Tanggal: ${DateTime.now().toString().split(' ')[0]}");
    csvContent.writeln("");
    csvContent.writeln("Hari,Nilai (mm)");

    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final weeklyData = [3.5, 3.8, 4.2, 4.5, 4.0, 3.8, 3.2];

    for (int i = 0; i < days.length; i++) {
      csvContent.writeln("${days[i]},${weeklyData[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Mingguan");
    csvContent.writeln("Total: 27.0 mm");
    csvContent.writeln("Rata-rata: 3.86 mm");
    csvContent.writeln("Maksimal: 4.5 mm");
    csvContent.writeln("Minimal: 3.2 mm");

    showExportPreview(context, csvContent.toString(), "Data Mingguan");
  }

  void _exportMonthlyData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING EVAPORASI - BULANAN");
    csvContent.writeln(
        "Bulan: ${DateTime.now().toString().split(' ')[0].substring(0, 7)}");
    csvContent.writeln("");
    csvContent.writeln("Tanggal,Nilai (mm)");

    for (int i = 1; i <= 28; i++) {
      final value = (3.0 + (i % 6) * 0.5).toStringAsFixed(1);
      csvContent.writeln("$i,$value");
    }

    csvContent.writeln("");
    csvContent.writeln("Statistik Bulanan");
    csvContent.writeln("Total: 99.2 mm");
    csvContent.writeln("Rata-rata: 3.54 mm");
    csvContent.writeln("Maksimal: 5.0 mm");
    csvContent.writeln("Minimal: 2.5 mm");

    showExportPreview(context, csvContent.toString(), "Data Bulanan");
  }

  void _exportAnnualData() {
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln("DATA MONITORING EVAPORASI - TAHUNAN");
    csvContent.writeln("Tahun: 2025");
    csvContent.writeln("");
    csvContent.writeln("Bulan,Pengisian (x),Rata-rata (mm)");

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
    final fillings = [12, 13, 15, 14, 13, 12, 14, 16, 13, 14, 15, 13];
    final averages = [
      3.5,
      3.8,
      4.2,
      4.5,
      5.0,
      5.2,
      5.5,
      5.8,
      5.0,
      4.5,
      4.0,
      3.7
    ];

    for (int i = 0; i < months.length; i++) {
      csvContent.writeln("${months[i]},${fillings[i]},${averages[i]}");
    }

    csvContent.writeln("");
    csvContent.writeln("STATISTIK TAHUNAN");
    csvContent.writeln("Total Pengisian: 156x");
    csvContent.writeln("Rata-rata Evaporasi: 4.4 mm");
    csvContent.writeln("Total Evaporasi: 52.8 mm");

    showExportPreview(context, csvContent.toString(), "Data Tahunan");
  }

  /// DATA GENERATORS
  List<FlSpot> _getEvaporationPeriodData() {
    switch (_selectedPeriod) {
      case "Hari Ini":
        if (_hasRealtimeEvaporation) {
          return List.generate(
            _dailyEvaporation.length,
            (index) => FlSpot(index.toDouble(), _dailyEvaporation[index]),
          );
        }
        return List.generate(24, (index) => FlSpot(index.toDouble(), 0.0));
      case "Minggu Ini":
        return List.generate(7, (index) => FlSpot(index.toDouble(), 0.0));
      case "Bulan Ini":
        return List.generate(12, (index) => FlSpot(index.toDouble(), 0.0));
      default:
        return [];
    }
  }

  /// UI BUILDERS
  Widget _buildAutomaticWaterControlSystem() {
    bool isActive = DateTime.now().hour >= 6 && DateTime.now().hour < 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sistem Kontrol Air Otomatis",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Jadwal Operasional",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "06.00 - 07.00 WIB",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? "AKTIF" : "TIDAK AKTIF",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Sistem otomatis akan mengisi air pada waktu yang telah ditentukan untuk menjaga tingkat evaporasi pada level optimal.",
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  "Status Evaporasi",
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
                      children:
                          ["Hari Ini", "Minggu Ini", "Bulan Ini"].map((period) {
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
                            selectedColor: Colors.blue,
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
                      _exportDailyData();
                    } else if (_selectedPeriod == "Minggu Ini") {
                      _exportWeeklyData();
                    } else if (_selectedPeriod == "Bulan Ini") {
                      _exportMonthlyData();
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
                      spots: _getEvaporationPeriodData(),
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.blue,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
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

  Widget _buildMonitoringExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Penjelasan Evaporasi",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Evaporasi adalah proses penguapan air dari permukaan tanah atau air menuju atmosfer. Tingkat evaporasi dipengaruhi oleh suhu, kelembaban udara, kecepatan angin, dan intensitas cahaya matahari. Data ini penting untuk manajemen irigasi dan perencanaan kebutuhan air.",
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualCombinedGraphSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistik Tahunan & Rata-rata",
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
                title: "Total Pengisian",
                value: "156x",
                color: Colors.blue,
                icon: Icons.water_drop,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: "Rata-rata",
                value: "4.2 mm",
                color: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        /// CHART
        const Text(
          "Grafik Tahunan - Pengisian Air & Rata-rata Evaporasi",
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
            child: Column(
              children: [
                SizedBox(
                  height: 320,
                  child: BarChart(
                    BarChartData(
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
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'Mei',
                                'Jun',
                                'Jul',
                                'Agu',
                                'Sep',
                                'Okt',
                                'Nov',
                                'Des'
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
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()} mm',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                ),
                              );
                            },
                            reservedSize: 45,
                          ),
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
                          right: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        12,
                        (index) => buildBarGroup(index, 0),
                      ),
                      rangeAnnotations: RangeAnnotations(
                        horizontalRangeAnnotations: [
                          HorizontalRangeAnnotation(
                            y1: 3.5,
                            y2: 5.8,
                            color: Colors.green.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Pengisian Air (kali)",
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Area Rata-rata (mm)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _exportAnnualData(),
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
