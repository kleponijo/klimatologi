// ===========================================================
//  wind_speed_excel_service.dart
//  Lokasi: lib/screens/monitoring/shared/utils/excel/
//
//  Dependensi (tambahkan ke pubspec.yaml):
//    excel: ^4.0.6
//    path_provider: ^2.1.4
//    share_plus: ^10.0.2
// ===========================================================

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

// Import kondisional: web pakai dart:html, mobile pakai io + share_plus
import 'excel_saver_stub.dart'
    if (dart.library.html) 'excel_saver_web.dart'
    if (dart.library.io) 'excel_saver_mobile.dart';

class WindSpeedExcelService {
  // ── Format helper ──────────────────────────────────────────
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm:ss', 'id_ID');
  static final _fileFmt = DateFormat('yyyyMMdd_HHmmss');
  static final _headerFmt = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

  // ── Warna tema ─────────────────────────────────────────────
  static const _colorHeader = '1A4A8C'; // biru tua
  static const _colorSubHead = '2E75B6'; // biru medium
  static const _colorNormal = 'E8F4FD'; // biru sangat muda
  static const _colorWaspada = 'FFF3CD'; // kuning muda
  static const _colorBahaya = 'F8D7DA'; // merah muda
  static const _colorWhite = 'FFFFFF';

  /// Export data kecepatan angin ke file Excel dan buka share sheet
  static Future<void> export({
    required double currentSpeed,
    required String alertLevel,
    required String period,
    required List<MyWindSpeed> history,
    DateTime? filterDate,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildSummarySheet(
        excel, currentSpeed, alertLevel, period, history, filterDate);
    _buildHistorySheet(excel, history, filterDate);

    // ── Simpan file ─────────────────────────────────────────
    final bytes = excel.save();
    if (bytes == null) throw Exception('Gagal membuat file Excel');
    final name = 'wind_speed_${_fileFmt.format(DateTime.now())}.xlsx';

    await saveAndShareExcel(Uint8List.fromList(bytes), name);
  }

  // ════════════════════════════════════════════════════════════
  //  SHEET 1: Ringkasan
  // ════════════════════════════════════════════════════════════
  static void _buildSummarySheet(
    Excel excel,
    double currentSpeed,
    String alertLevel,
    String period,
    List<MyWindSpeed> history,
    DateTime? filterDate,
  ) {
    final sheet = excel['Ringkasan'];

    // -- Judul --
    _setCell(sheet, 0, 0, 'DATA KECEPATAN ANGIN – ANEMOMETER',
        bold: true,
        fontSize: 14,
        bgColor: _colorHeader,
        fontColor: _colorWhite);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));

    // -- Metadata --
    _setCell(sheet, 1, 0, 'Diekspor pada',
        bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
    _setCell(sheet, 1, 1, _headerFmt.format(DateTime.now()),
        bgColor: _colorNormal);
    _setCell(sheet, 2, 0, 'Periode grafik',
        bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
    _setCell(sheet, 2, 1, period, bgColor: _colorNormal);

    if (filterDate != null) {
      _setCell(sheet, 3, 0, 'Filter tanggal',
          bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
      _setCell(
          sheet, 3, 1, DateFormat('dd MMMM yyyy', 'id_ID').format(filterDate),
          bgColor: _colorNormal);
    }

    // -- Kecepatan saat ini --
    _setCell(sheet, 5, 0, 'KECEPATAN SAAT INI',
        bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 5));

    _setCell(sheet, 6, 0, 'Kecepatan (m/s)', bold: true);
    _setCellDouble(sheet, 6, 1, currentSpeed);
    _setCell(sheet, 7, 0, 'Kecepatan (km/h)', bold: true);
    _setCellDouble(sheet, 7, 1, currentSpeed * 3.6);
    _setCell(sheet, 8, 0, 'Status', bold: true);
    final statusColor = _alertBgColor(alertLevel);
    _setCell(sheet, 8, 1, alertLevel, bgColor: statusColor);

    // -- Statistik ringkasan --
    if (history.isNotEmpty) {
      final speeds = history.map((e) => e.speed).toList();
      final avg = speeds.reduce((a, b) => a + b) / speeds.length;
      final max = speeds.reduce((a, b) => a > b ? a : b);
      final min = speeds.reduce((a, b) => a < b ? a : b);

      _setCell(sheet, 10, 0, 'STATISTIK HISTORY',
          bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10),
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 10));

      _setCell(sheet, 11, 0, 'Jumlah data', bold: true);
      _setCellInt(sheet, 11, 1, history.length);
      _setCell(sheet, 12, 0, 'Rata-rata (m/s)', bold: true);
      _setCellDouble(sheet, 12, 1, avg);
      _setCell(sheet, 13, 0, 'Maksimum (m/s)', bold: true);
      _setCellDouble(sheet, 13, 1, max);
      _setCell(sheet, 14, 0, 'Minimum (m/s)', bold: true);
      _setCellDouble(sheet, 14, 1, min);
      _setCell(sheet, 15, 0, 'Rata-rata (km/h)', bold: true);
      _setCellDouble(sheet, 15, 1, avg * 3.6);
    }

    // Set lebar kolom
    sheet.setColumnWidth(0, 22);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
  }

  // ════════════════════════════════════════════════════════════
  //  SHEET 2: Data History
  // ════════════════════════════════════════════════════════════
  static void _buildHistorySheet(
    Excel excel,
    List<MyWindSpeed> history,
    DateTime? filterDate,
  ) {
    final sheet = excel['Data History'];

    // -- Header kolom --
    final headers = [
      'No',
      'Tanggal',
      'Waktu',
      'Kecepatan (m/s)',
      'Kecepatan (km/h)',
      'Status'
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 0, i, headers[i],
          bold: true,
          bgColor: _colorHeader,
          fontColor: _colorWhite,
          centered: true);
    }

    // -- Filter jika ada tanggal dipilih --
    final data = filterDate != null
        ? history
            .where((e) =>
                e.timestamp.year == filterDate.year &&
                e.timestamp.month == filterDate.month &&
                e.timestamp.day == filterDate.day)
            .toList()
        : history;

    // -- Isi baris data --
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final rowIdx = i + 1;
      final kmh = item.speed * 3.6;
      final status = _getAlertLevel(item.speed);
      final bgColor = i.isEven ? _colorNormal : _colorWhite;
      final statusBg = _alertBgColor(status);

      _setCellInt(sheet, rowIdx, 0, i + 1, bgColor: bgColor, centered: true);
      _setCell(sheet, rowIdx, 1,
          DateFormat('dd/MM/yyyy', 'id_ID').format(item.timestamp),
          bgColor: bgColor);
      _setCell(sheet, rowIdx, 2, DateFormat('HH:mm:ss').format(item.timestamp),
          bgColor: bgColor, centered: true);
      _setCellDouble(sheet, rowIdx, 3, item.speed,
          bgColor: bgColor, centered: true);
      _setCellDouble(sheet, rowIdx, 4, kmh, bgColor: bgColor, centered: true);
      _setCell(sheet, rowIdx, 5, status,
          bgColor: statusBg, centered: true, bold: true);
    }

    // -- Footer jika kosong --
    if (data.isEmpty) {
      _setCell(sheet, 1, 0, 'Tidak ada data untuk tanggal yang dipilih',
          bgColor: _colorWaspada, centered: true);
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1));
    }

    // Set lebar kolom
    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 12);
  }

  // ════════════════════════════════════════════════════════════
  //  HELPER CELLS
  // ════════════════════════════════════════════════════════════
  static void _setCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
    double fontSize = 11,
    String bgColor = _colorWhite,
    String fontColor = '000000',
    bool centered = false,
  }) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      backgroundColorHex: ExcelColor.fromHexString('#$bgColor'),
      fontColorHex: ExcelColor.fromHexString('#$fontColor'),
      horizontalAlign: centered ? HorizontalAlign.Center : HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
    );
  }

  static void _setCellDouble(
    Sheet sheet,
    int row,
    int col,
    double value, {
    String bgColor = _colorWhite,
    bool centered = false,
  }) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = DoubleCellValue(double.parse(value.toStringAsFixed(4)));
    cell.cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#$bgColor'),
      horizontalAlign:
          centered ? HorizontalAlign.Center : HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
    );
  }

  static void _setCellInt(
    Sheet sheet,
    int row,
    int col,
    int value, {
    String bgColor = _colorWhite,
    bool centered = false,
  }) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = IntCellValue(value);
    cell.cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#$bgColor'),
      horizontalAlign:
          centered ? HorizontalAlign.Center : HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
      bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC')),
    );
  }

  static String _alertBgColor(String level) {
    switch (level) {
      case 'Bahaya':
        return _colorBahaya;
      case 'Waspada':
        return _colorWaspada;
      default:
        return _colorNormal;
    }
  }

  static String _getAlertLevel(double speed) {
    if (speed >= 12.5) return 'Bahaya';
    if (speed >= 8.0) return 'Waspada';
    return 'Normal';
  }
}
