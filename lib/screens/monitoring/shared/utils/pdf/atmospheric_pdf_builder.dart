import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pdf_components.dart';

/// ============================================================
/// Atmospheric PDF Builder
/// Letakkan di: lib/screens/monitoring/shared/utils/pdf/atmospheric_pdf_builder.dart
/// ============================================================

Future<void> exportAtmosphericPdf({
  required double temperature,
  required double humidity,
  required double pressure,
  required double altitude,
  required DateTime timestamp,
  List<Map<String, dynamic>>? historyData,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => buildPdfHeader('Laporan Kondisi Atmosfer', timestamp),
      footer: (ctx) => buildPdfFooter(ctx),
      build: (ctx) => [
        // — Summary card
        buildSummaryCard(
          title: 'Data Terkini',
          subtitle: pdfFullFormat.format(timestamp),
          items: [
            SummaryItem('Suhu', '${temperature.toStringAsFixed(1)} °C', '🌡️'),
            SummaryItem('Kelembapan', '${humidity.toStringAsFixed(1)} %', '💧'),
            SummaryItem('Tekanan', '${pressure.toStringAsFixed(1)} hPa', '🔵'),
            SummaryItem('Ketinggian', '${altitude.toStringAsFixed(1)} m', '⛰️'),
          ],
        ),
        pw.SizedBox(height: 24),

        // — Tabel key-value ringkasan
        buildSectionTitle('Detail Parameter'),
        pw.SizedBox(height: 8),
        buildKeyValueTable([
          ['Parameter', 'Nilai', 'Satuan'],
          ['Suhu', temperature.toStringAsFixed(1), '°C'],
          ['Kelembapan', humidity.toStringAsFixed(1), '%'],
          ['Tekanan Udara', pressure.toStringAsFixed(1), 'hPa'],
          ['Ketinggian', altitude.toStringAsFixed(1), 'm'],
        ]),

        // — Tabel history jika ada
        if (historyData != null && historyData.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          buildSectionTitle('Riwayat Data'),
          pw.SizedBox(height: 8),
          _buildHistoryTable(historyData),
        ],
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) => pdf.save());
}

pw.Widget _buildHistoryTable(List<Map<String, dynamic>> data) {
  return buildDataTable(
    headers: ['No', 'Waktu', 'Suhu (°C)', 'Kelembapan (%)', 'Tekanan (hPa)', 'Ketinggian (m)'],
    rows: data.asMap().entries.map((e) {
      final d = e.value;
      final ts = d['timestamp'] as DateTime?;
      return [
        '${e.key + 1}',
        ts != null ? pdfFullFormat.format(ts) : '-',
        (d['temperature'] as double? ?? 0).toStringAsFixed(1),
        (d['humidity'] as double? ?? 0).toStringAsFixed(1),
        (d['pressure'] as double? ?? 0).toStringAsFixed(1),
        (d['altitude'] as double? ?? 0).toStringAsFixed(1),
      ];
    }).toList(),
    colWidths: {
      0: const pw.FixedColumnWidth(25),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1.2),
      4: const pw.FlexColumnWidth(1.2),
      5: const pw.FlexColumnWidth(1.2),
    },
  );
}
