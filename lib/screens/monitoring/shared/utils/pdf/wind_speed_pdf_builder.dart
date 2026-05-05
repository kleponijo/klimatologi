import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pdf_components.dart';

/// ============================================================
/// Wind Speed PDF Builder
/// Letakkan di: lib/screens/monitoring/shared/utils/pdf/wind_speed_pdf_builder.dart
/// ============================================================

Future<void> exportWindSpeedPdf({
  required double currentSpeed,
  required String period,
  required List<double> speeds,
  required DateTime timestamp,
  List<Map<String, dynamic>>? historyData,
}) async {
  final pdf = pw.Document();
  final stats = calcStats(speeds);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => buildPdfHeader('Laporan Kecepatan Angin', timestamp),
      footer: (ctx) => buildPdfFooter(ctx),
      build: (ctx) => [
        // — Summary card
        buildSummaryCard(
          title: 'Data Terkini',
          subtitle: 'Periode: $period',
          items: [
            SummaryItem('Kecepatan', '${currentSpeed.toStringAsFixed(1)} m/s', '💨'),
            SummaryItem('Rata-rata', '${stats['avg']!.toStringAsFixed(1)} m/s', '📊'),
            SummaryItem('Maksimum', '${stats['max']!.toStringAsFixed(1)} m/s', '⬆️'),
            SummaryItem('Minimum', '${stats['min']!.toStringAsFixed(1)} m/s', '⬇️'),
          ],
        ),
        pw.SizedBox(height: 24),

        // — Tabel data per periode
        if (speeds.isNotEmpty) ...[
          buildSectionTitle('Data Periode ($period)'),
          pw.SizedBox(height: 8),
          _buildPeriodTable(speeds, period),
        ],

        // — Tabel history jika ada
        if (historyData != null && historyData.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          buildSectionTitle('Riwayat Detail'),
          pw.SizedBox(height: 8),
          _buildHistoryTable(historyData),
        ],
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) => pdf.save());
}

pw.Widget _buildPeriodTable(List<double> speeds, String period) {
  final labels = _periodLabels(speeds.length, period);
  return buildDataTable(
    headers: ['No', 'Label', 'Kecepatan (m/s)'],
    rows: speeds.asMap().entries.map((e) => [
      '${e.key + 1}',
      labels[e.key],
      e.value.toStringAsFixed(2),
    ]).toList(),
    colWidths: {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(1.5),
    },
  );
}

pw.Widget _buildHistoryTable(List<Map<String, dynamic>> data) {
  return buildDataTable(
    headers: ['No', 'Waktu', 'Kecepatan (m/s)', 'Pulse'],
    rows: data.asMap().entries.map((e) {
      final d = e.value;
      final ts = d['timestamp'] as DateTime?;
      return [
        '${e.key + 1}',
        ts != null ? pdfFullFormat.format(ts) : '-',
        (d['speed'] as double? ?? 0).toStringAsFixed(2),
        '${d['pulse'] ?? 0}',
      ];
    }).toList(),
    colWidths: {
      0: const pw.FixedColumnWidth(25),
      1: const pw.FlexColumnWidth(2.5),
      2: const pw.FlexColumnWidth(1.5),
      3: const pw.FlexColumnWidth(1),
    },
  );
}

List<String> _periodLabels(int count, String period) {
  if (period == 'Hari Ini') {
    return List.generate(count, (i) => 'Jam ${i.toString().padLeft(2, '0')}:00');
  } else if (period == 'Minggu Ini') {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return List.generate(count, (i) => days[i % 7]);
  } else {
    return List.generate(count, (i) => 'Minggu ${i + 1}');
  }
}
