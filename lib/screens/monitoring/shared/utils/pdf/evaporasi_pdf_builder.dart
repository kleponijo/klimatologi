import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pdf_components.dart';

/// ============================================================
/// Evaporasi PDF Builder
/// Letakkan di: lib/screens/monitoring/shared/utils/pdf/evaporasi_pdf_builder.dart
/// ============================================================

Future<void> exportEvaporasiPdf({
  required double evaporasi,
  required double suhu,
  required double tinggiAir,
  required DateTime timestamp,
  List<Map<String, dynamic>>? historyData,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => buildPdfHeader('Laporan Evaporasi', timestamp),
      footer: (ctx) => buildPdfFooter(ctx),
      build: (ctx) => [
        // — Summary card
        buildSummaryCard(
          title: 'Data Terkini',
          subtitle: pdfFullFormat.format(timestamp),
          items: [
            SummaryItem('Evaporasi', '${evaporasi.toStringAsFixed(2)} mm', '💧'),
            SummaryItem('Suhu', '${suhu.toStringAsFixed(1)} °C', '🌡️'),
            SummaryItem('Tinggi Air', '${tinggiAir.toStringAsFixed(1)} cm', '📏'),
          ],
        ),
        pw.SizedBox(height: 24),

        // — Tabel key-value ringkasan
        buildSectionTitle('Detail Parameter'),
        pw.SizedBox(height: 8),
        buildKeyValueTable([
          ['Parameter', 'Nilai', 'Satuan'],
          ['Evaporasi', evaporasi.toStringAsFixed(2), 'mm'],
          ['Suhu', suhu.toStringAsFixed(1), '°C'],
          ['Tinggi Air', tinggiAir.toStringAsFixed(1), 'cm'],
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
    headers: ['No', 'Waktu', 'Evaporasi (mm)', 'Suhu (°C)', 'Tinggi Air (cm)'],
    rows: data.asMap().entries.map((e) {
      final d = e.value;
      final ts = d['timestamp'] as DateTime?;
      return [
        '${e.key + 1}',
        ts != null ? pdfFullFormat.format(ts) : '-',
        (d['evaporasi'] as double? ?? 0).toStringAsFixed(2),
        (d['suhu'] as double? ?? 0).toStringAsFixed(1),
        (d['tinggiAir'] as double? ?? 0).toStringAsFixed(1),
      ];
    }).toList(),
    colWidths: {
      0: const pw.FixedColumnWidth(25),
      1: const pw.FlexColumnWidth(2),
      2: const pw.FlexColumnWidth(1.3),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1.3),
    },
  );
}
