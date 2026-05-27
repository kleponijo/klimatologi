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
import 'package:intl/intl.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

import 'excel_saver_stub.dart'
    if (dart.library.html) 'excel_saver_web.dart'
    if (dart.library.io) 'excel_saver_mobile.dart';

class WindSpeedExcelService {
  // ── Format helper ──────────────────────────────────────────
  static final _headerFmt = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

  // ── Warna tema ─────────────────────────────────────────────
  static const _colorHeader = '1A4A8C';
  static const _colorSubHead = '2E75B6';
  static const _colorNormal = 'E8F4FD';
  static const _colorWaspada = 'FFF3CD';
  static const _colorBahaya = 'F8D7DA';
  static const _colorWhite = 'FFFFFF';

  // ════════════════════════════════════════════════════════════
  //  Filter helper — dipakai oleh dua sheet
  // ════════════════════════════════════════════════════════════
  static List<MyWindSpeed> _applyFilter(
    List<MyWindSpeed> history, {
    DateTime? dateFrom,
    DateTime? dateTo,
    int? hourFrom,
    int? minuteFrom,
    int? hourTo,
    int? minuteTo,
  }) {
    return history.where((e) {
      // ── Filter tanggal ──────────────────────────────────────
      if (dateFrom != null && dateTo != null) {
        final d =
            DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
        final from = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
        final to = DateTime(dateTo.year, dateTo.month, dateTo.day);
        if (d.isBefore(from) || d.isAfter(to)) return false;
      }

      // ── Filter jam ──────────────────────────────────────────
      if (hourFrom != null && hourTo != null) {
        // Bandingkan dalam menit total agar menit ikut diperhitungkan
        final eMin = e.timestamp.hour * 60 + e.timestamp.minute;
        final fromMin = hourFrom * 60 + (minuteFrom ?? 0);
        final toMin = hourTo * 60 + (minuteTo ?? 59);

        final pass = fromMin <= toMin
            ? eMin >= fromMin && eMin <= toMin // normal: 08:00–17:00
            : eMin >= fromMin || eMin <= toMin; // overnight: 23:00–02:00
        if (!pass) return false;
      }

      return true;
    }).toList();
  }

  // ════════════════════════════════════════════════════════════
  //  PUBLIC: export
  // ════════════════════════════════════════════════════════════
  static Future<void> export({
    required double currentSpeed,
    required String alertLevel,
    required String period,
    required List<MyWindSpeed> history,
    required String fileName,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? hourFrom, // ← jam mulai (0–23)
    int? minuteFrom, // ← menit mulai
    int? hourTo, // ← jam selesai (0–23)
    int? minuteTo, // ← menit selesai
  }) async {
    // Terapkan filter SATU KALI, hasil dipakai kedua sheet
    final filtered = _applyFilter(
      history,
      dateFrom: dateFrom,
      dateTo: dateTo,
      hourFrom: hourFrom,
      minuteFrom: minuteFrom,
      hourTo: hourTo,
      minuteTo: minuteTo,
    );

    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildSummarySheet(
      excel,
      currentSpeed,
      alertLevel,
      period,
      filtered,
      history.length,
      dateFrom: dateFrom,
      dateTo: dateTo,
      hourFrom: hourFrom,
      minuteFrom: minuteFrom,
      hourTo: hourTo,
      minuteTo: minuteTo,
    );
    _buildHistorySheet(excel, filtered);

    // ── Simpan file ─────────────────────────────────────────
    final bytes = excel.save();
    if (bytes == null) throw Exception('Gagal membuat file Excel');

    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await saveAndShareExcel(Uint8List.fromList(bytes), '$safeName.xlsx');
  }

  // ════════════════════════════════════════════════════════════
  //  SHEET 1: Ringkasan
  //  — statistik dihitung dari [filteredHistory] bukan all data
  // ════════════════════════════════════════════════════════════
  static void _buildSummarySheet(
    Excel excel,
    double currentSpeed,
    String alertLevel,
    String period,
    List<MyWindSpeed> filteredHistory,
    int totalCount, {
    DateTime? dateFrom,
    DateTime? dateTo,
    int? hourFrom,
    int? minuteFrom,
    int? hourTo,
    int? minuteTo,
  }) {
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

    int metaRow = 3;

    if (dateFrom != null && dateTo != null) {
      _setCell(sheet, metaRow, 0, 'Filter tanggal',
          bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
      _setCell(
        sheet,
        metaRow,
        1,
        '${DateFormat('dd MMMM yyyy', 'id_ID').format(dateFrom)}  →  ${DateFormat('dd MMMM yyyy', 'id_ID').format(dateTo)}',
        bgColor: _colorNormal,
      );
      metaRow++;
    }

    if (hourFrom != null && hourTo != null) {
      final fromStr =
          '${hourFrom.toString().padLeft(2, '0')}:${(minuteFrom ?? 0).toString().padLeft(2, '0')}';
      final toStr =
          '${hourTo.toString().padLeft(2, '0')}:${(minuteTo ?? 59).toString().padLeft(2, '0')}';
      _setCell(sheet, metaRow, 0, 'Filter jam',
          bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
      _setCell(sheet, metaRow, 1, '$fromStr  →  $toStr', bgColor: _colorNormal);
      metaRow++;
    }

    // -- Kecepatan realtime saat ini --
    final secRow = metaRow + 1;
    _setCell(sheet, secRow, 0, 'KECEPATAN SAAT INI',
        bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: secRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: secRow));

    _setCell(sheet, secRow + 1, 0, 'Kecepatan (m/s)', bold: true);
    _setCellDouble(sheet, secRow + 1, 1, currentSpeed);
    _setCell(sheet, secRow + 2, 0, 'Kecepatan (km/h)', bold: true);
    _setCellDouble(sheet, secRow + 2, 1, currentSpeed * 3.6);
    _setCell(sheet, secRow + 3, 0, 'Status', bold: true);
    _setCell(sheet, secRow + 3, 1, alertLevel,
        bgColor: _alertBgColor(alertLevel));

    // -- Statistik dari data TERFILTER (bukan all history) --
    final statRow = secRow + 5;
    _setCell(sheet, statRow, 0, 'STATISTIK DATA DIEKSPOR',
        bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: statRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: statRow));

    _setCell(sheet, statRow + 1, 0, 'Total data tersimpan', bold: true);
    _setCellInt(sheet, statRow + 1, 1, totalCount);
    _setCell(sheet, statRow + 2, 0, 'Data diekspor', bold: true);
    _setCellInt(sheet, statRow + 2, 1, filteredHistory.length);

    if (filteredHistory.isNotEmpty) {
      final speeds = filteredHistory.map((e) => e.speed).toList();
      final avg = speeds.reduce((a, b) => a + b) / speeds.length;
      final max = speeds.reduce((a, b) => a > b ? a : b);
      final min = speeds.reduce((a, b) => a < b ? a : b);

      _setCell(sheet, statRow + 3, 0, 'Rata-rata (m/s)', bold: true);
      _setCellDouble(sheet, statRow + 3, 1, avg);
      _setCell(sheet, statRow + 4, 0, 'Maksimum (m/s)', bold: true);
      _setCellDouble(sheet, statRow + 4, 1, max);
      _setCell(sheet, statRow + 5, 0, 'Minimum (m/s)', bold: true);
      _setCellDouble(sheet, statRow + 5, 1, min);
      _setCell(sheet, statRow + 6, 0, 'Rata-rata (km/h)', bold: true);
      _setCellDouble(sheet, statRow + 6, 1, avg * 3.6);
    } else {
      _setCell(sheet, statRow + 3, 0, 'Tidak ada data dalam filter ini',
          bgColor: _colorWaspada);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: statRow + 3),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: statRow + 3),
      );
    }

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
  }

  // ════════════════════════════════════════════════════════════
  //  SHEET 2: Data History
  //  — menerima data yang sudah difilter, tidak filter ulang
  // ════════════════════════════════════════════════════════════
  static void _buildHistorySheet(
    Excel excel,
    List<MyWindSpeed> data,
  ) {
    final sheet = excel['Data History'];

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

    if (data.isEmpty) {
      _setCell(sheet, 1, 0, 'Tidak ada data untuk filter yang dipilih',
          bgColor: _colorWaspada, centered: true);
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1));
    } else {
      // Urutkan ascending (terlama → terbaru) di Excel
      final sorted = [...data]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (var i = 0; i < sorted.length; i++) {
        final item = sorted[i];
        final rowIdx = i + 1;
        final kmh = item.speed * 3.6;
        final status = _getAlertLevel(item.speed);
        final bgColor = i.isEven ? _colorNormal : _colorWhite;

        _setCellInt(sheet, rowIdx, 0, i + 1, bgColor: bgColor, centered: true);
        _setCell(sheet, rowIdx, 1,
            DateFormat('dd/MM/yyyy', 'id_ID').format(item.timestamp),
            bgColor: bgColor);
        _setCell(
            sheet, rowIdx, 2, DateFormat('HH:mm:ss').format(item.timestamp),
            bgColor: bgColor, centered: true);
        _setCellDouble(sheet, rowIdx, 3, item.speed,
            bgColor: bgColor, centered: true);
        _setCellDouble(sheet, rowIdx, 4, kmh, bgColor: bgColor, centered: true);
        _setCell(sheet, rowIdx, 5, status,
            bgColor: _alertBgColor(status), centered: true, bold: true);
      }
    }

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
  static CellStyle _baseStyle({
    String bgColor = _colorWhite,
    String fontColor = '000000',
    bool bold = false,
    int fontSize = 11,
    bool centered = false,
  }) =>
      CellStyle(
        bold: bold,
        fontSize: fontSize,
        backgroundColorHex: ExcelColor.fromHexString('#$bgColor'),
        fontColorHex: ExcelColor.fromHexString('#$fontColor'),
        horizontalAlign:
            centered ? HorizontalAlign.Center : HorizontalAlign.Left,
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
