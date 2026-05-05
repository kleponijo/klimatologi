import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

Future<void> exportAtmosphericExcel({
  required double pressure,
  required int timeMs,
  required DateTime timestamp,
  List<Map<String, dynamic>>? historyData,
}) async {
  final excel = Excel.createExcel();
  final sheet = excel['Histori Tekanan'];

  sheet.appendRow([
    TextCellValue('Laporan Tekanan Atmosfer (Hari Ini)'),
  ]);
  sheet.appendRow([
    TextCellValue('Waktu export: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(timestamp)}'),
  ]);
  sheet.appendRow([
    TextCellValue('Tekanan terbaru: ${pressure.toStringAsFixed(1)} hPa'),
  ]);
  sheet.appendRow([
    TextCellValue('Uptime terbaru: ${_formatUptime(timeMs)}'),
  ]);
  sheet.appendRow([
    TextCellValue('')
  ]);

  sheet.appendRow([
    TextCellValue('No'),
    TextCellValue('Uptime'),
    TextCellValue('Tekanan (hPa)'),
    TextCellValue('Timestamp'),
  ]);

  final rows = historyData ?? const [];
  for (int i = 0; i < rows.length; i++) {
    final row = rows[i];
    final rowTimeMs = _toInt(row['timeMs']);
    final rowPressure = _toDouble(row['pressure']);
    final rowTimestamp = row['timestamp'] as DateTime?;

    sheet.appendRow([
      IntCellValue(i + 1),
      TextCellValue(_formatUptime(rowTimeMs)),
      TextCellValue(rowPressure.toStringAsFixed(1)),
      TextCellValue(
        rowTimestamp == null ? '-' : DateFormat('dd-MM-yyyy HH:mm:ss').format(rowTimestamp),
      ),
    ]);
  }

  final bytes = excel.encode();
  if (bytes == null) {
    return;
  }

  final filename = 'histori_tekanan_${DateFormat('yyyyMMdd_HHmmss').format(timestamp)}';

  await FileSaver.instance.saveFile(
    name: filename,
    bytes: Uint8List.fromList(bytes),
    fileExtension: 'xlsx',
    mimeType: MimeType.other,
  );
}

String _formatUptime(int timeMs) {
  final duration = Duration(milliseconds: timeMs);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
