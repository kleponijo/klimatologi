import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// SHOW EXPORT PREVIEW DIALOG
/// Helper function untuk menampilkan preview export data
void showExportPreview(BuildContext context, String content, String title) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Preview Export - $title"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup"),
        ),
      ],
    ),
  );
}

/// STAT CARD WIDGET
/// Reusable card untuk menampilkan statistik
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// BUILD BAR GROUP FOR CHART
/// Helper untuk membuat bar group di BarChart
BarChartGroupData buildBarGroup(int x, double value) {
  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: value.toDouble(),
        color: Colors.blue,
        width: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    ],
  );
}

/// GET PERIOD INTERVAL
/// Menentukan spacing interval berdasarkan periode
double getPeriodInterval(String period) {
  switch (period) {
    case "Hari Ini":
      return 3;
    case "Minggu Ini":
      return 1;
    case "Bulan Ini":
      return 2;
    default:
      return 1;
  }
}

/// GET PERIOD LABEL
/// Menentukan label untuk X-axis berdasarkan periode
String getPeriodLabel(String period, double value) {
  switch (period) {
    case "Hari Ini":
      return '${value.toInt()}h';
    case "Minggu Ini":
      final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return days[value.toInt()];
    case "Bulan Ini":
      return 'M${value.toInt() + 1}';
    default:
      return '';
  }
}
