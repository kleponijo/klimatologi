// ===========================================================
//  evaporasi_excel_service.dart
//  Lokasi: lib/screens/monitoring/shared/utils/excel/
// ===========================================================

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

import 'excel_saver_stub.dart'
    if (dart.library.html) 'excel_saver_web.dart'
    if (dart.library.io) 'excel_saver_mobile.dart';

class EvaporasiExcelService {
  // ── Format helper ──────────────────────────────────────────
  // static final _dateFmt  = DateFormat('dd/MM/yyyy HH:mm:ss', 'id_ID');
  static final _headerFmt = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

  // ── Warna tema ─────────────────────────────────────────────
  static const _colorHeader = '1A4A8C'; // biru tua
  static const _colorSubHead = '2E75B6'; // biru medium
  static const _colorNormal = 'E8F4FD'; // biru sangat muda
  static const _colorTinggi = 'F8D7DA'; // merah muda
  static const _colorRendah = 'D1ECF1'; // biru muda
  static const _colorWhite = 'FFFFFF';
  static const _colorWaspada = 'FFF3CD'; // kuning muda

  /// Export data evaporasi ke file Excel dan buka share sheet
  static Future<void> export({
    required double currentValue,
    required double temperature,
    required double waterLevel,
    required double acuanPagi,
    required String weatherStatus,
    required List<Evaporasi> history,
    required String fileName,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildSummarySheet(
      excel,
      currentValue,
      temperature,
      waterLevel,
      acuanPagi,
      weatherStatus,
      history,
      dateFrom,
      dateTo,
    );
    _buildHistorySheet(excel, history, dateFrom, dateTo);

    // ── Simpan file ─────────────────────────────────────────
    final bytes = excel.save();
    if (bytes == null) throw Exception('Gagal membuat file Excel');

    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await saveAndShareExcel(Uint8List.fromList(bytes), '$safeName.xlsx');
  }

  // ════════════════════════════════════════════════════════════
  //  SHEET 1: Ringkasan
  // ════════════════════════════════════════════════════════════
  static void _buildSummarySheet(
    Excel excel,
    double currentValue,
    double temperature,
    double waterLevel,
    double acuanPagi,
    String weatherStatus,
    List<Evaporasi> history,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) {
    final sheet = excel['Ringkasan'];

    // -- Judul --
    _setCell(sheet, 0, 0, 'DATA EVAPORASI – WEATHER STATION',
        bold: true,
        fontSize: 14,
        bgColor: _colorHeader,
        fontColor: _colorWhite);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );

    // -- Metadata --
    _setCell(sheet, 1, 0, 'Diekspor pada',
        bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
    _setCell(sheet, 1, 1, _headerFmt.format(DateTime.now()),
        bgColor: _colorNormal);

    if (dateFrom != null && dateTo != null) {
      _setCell(sheet, 2, 0, 'Filter tanggal',
          bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
      _setCell(
        sheet,
        2,
        1,
        '${DateFormat('dd MMMM yyyy', 'id_ID').format(dateFrom)}  →  ${DateFormat('dd MMMM yyyy', 'id_ID').format(dateTo)}',
        bgColor: _colorNormal,
      );
    }

    // -- Nilai saat ini --
    _setCell(sheet, 4, 0, 'DATA SAAT INI',
        bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 4),
    );

    _setCell(sheet, 5, 0, 'Evaporasi (mm)', bold: true);
    _setCellDouble(sheet, 5, 1, currentValue);

    _setCell(sheet, 6, 0, 'Suhu Air (°C)', bold: true);
    if (temperature < 0) {
      _setCell(sheet, 6, 1, '-');
    } else {
      _setCellDouble(sheet, 6, 1, temperature);
    }

    _setCell(sheet, 7, 0, 'Tinggi Air (cm)', bold: true);
    _setCellDouble(sheet, 7, 1, waterLevel);

    _setCell(sheet, 8, 0, 'Acuan Air Pagi (cm)', bold: true);
    _setCellDouble(sheet, 8, 1, acuanPagi);

    _setCell(sheet, 9, 0, 'Status', bold: true);
    _setCell(sheet, 9, 1, weatherStatus,
        bgColor: _statusBgColor(weatherStatus));

    // -- Statistik ringkasan --
    if (history.isNotEmpty) {
      final evapValues = history.map((e) => e.evaporasi).toList();
      final tempValues =
          history.map((e) => e.suhu).where((s) => s >= 0).toList();

      final evapAvg = evapValues.reduce((a, b) => a + b) / evapValues.length;
      final evapMax = evapValues.reduce((a, b) => a > b ? a : b);
      final evapMin = evapValues.reduce((a, b) => a < b ? a : b);

      _setCell(sheet, 11, 0, 'STATISTIK HISTORY',
          bold: true, bgColor: _colorSubHead, fontColor: _colorWhite);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 11),
      );

      _setCell(sheet, 12, 0, 'Jumlah data', bold: true);
      _setCellInt(sheet, 12, 1, history.length);

      _setCell(sheet, 13, 0, 'Rata-rata evaporasi (mm)', bold: true);
      _setCellDouble(sheet, 13, 1, evapAvg);

      _setCell(sheet, 14, 0, 'Evaporasi maksimum (mm)', bold: true);
      _setCellDouble(sheet, 14, 1, evapMax);

      _setCell(sheet, 15, 0, 'Evaporasi minimum (mm)', bold: true);
      _setCellDouble(sheet, 15, 1, evapMin);

      if (tempValues.isNotEmpty) {
        final tempAvg = tempValues.reduce((a, b) => a + b) / tempValues.length;
        final tempMax = tempValues.reduce((a, b) => a > b ? a : b);
        final tempMin = tempValues.reduce((a, b) => a < b ? a : b);

        _setCell(sheet, 16, 0, 'Rata-rata suhu (°C)', bold: true);
        _setCellDouble(sheet, 16, 1, tempAvg);

        _setCell(sheet, 17, 0, 'Suhu maksimum (°C)', bold: true);
        _setCellDouble(sheet, 17, 1, tempMax);

        _setCell(sheet, 18, 0, 'Suhu minimum (°C)', bold: true);
        _setCellDouble(sheet, 18, 1, tempMin);
      }
    }

    // Set lebar kolom
    sheet.setColumnWidth(0, 26);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
  }

  // ════════════════════════════════════════════════════════════
  //  SHEET 2: Data History
  // ════════════════════════════════════════════════════════════
  static void _buildHistorySheet(
    Excel excel,
    List<Evaporasi> history,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) {
    final sheet = excel['Data History'];

    // -- Header kolom --
    final headers = [
      'No',
      'Tanggal',
      'Waktu',
      'Evaporasi (mm)',
      'Tinggi Air (cm)',
      'Suhu (°C)',
      'Acuan Pagi (cm)',
      'Status',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 0, i, headers[i],
          bold: true,
          bgColor: _colorHeader,
          fontColor: _colorWhite,
          centered: true);
    }

    // Filter berdasarkan rentang tanggal (inklusif kedua ujung)
    final data = (dateFrom != null && dateTo != null)
        ? history.where((e) {
            final d =
                DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
            final from = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
            final to = DateTime(dateTo.year, dateTo.month, dateTo.day);
            return !d.isBefore(from) && !d.isAfter(to);
          }).toList()
        : history;

    // Urutkan terbaru di atas
    final sorted = [...data]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // -- Isi baris data --
    for (var i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      final rowIdx = i + 1;
      final status = _getStatus(item.evaporasi);
      final bgColor = i.isEven ? _colorNormal : _colorWhite;
      final statusBg = _statusBgColor(status);

      _setCellInt(sheet, rowIdx, 0, i + 1, bgColor: bgColor, centered: true);
      _setCell(sheet, rowIdx, 1,
          DateFormat('dd/MM/yyyy', 'id_ID').format(item.timestamp),
          bgColor: bgColor);
      _setCell(sheet, rowIdx, 2, DateFormat('HH:mm:ss').format(item.timestamp),
          bgColor: bgColor, centered: true);
      _setCellDouble(sheet, rowIdx, 3, item.evaporasi,
          bgColor: bgColor, centered: true);
      _setCellDouble(sheet, rowIdx, 4, item.tinggiAir,
          bgColor: bgColor, centered: true);
      // Suhu: tampilkan '-' jika sensor error (< 0)
      if (item.suhu < 0) {
        _setCell(sheet, rowIdx, 5, '-', bgColor: bgColor, centered: true);
      } else {
        _setCellDouble(sheet, rowIdx, 5, item.suhu,
            bgColor: bgColor, centered: true);
      }
      _setCellDouble(sheet, rowIdx, 6, item.acuanPagi,
          bgColor: bgColor, centered: true);
      _setCell(sheet, rowIdx, 7, status,
          bgColor: statusBg, centered: true, bold: true);
    }

    // -- Footer jika kosong --
    if (sorted.isEmpty) {
      _setCell(sheet, 1, 0, 'Tidak ada data untuk tanggal yang dipilih',
          bgColor: _colorWaspada, centered: true);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1),
      );
    }

    // Set lebar kolom
    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 18);
    sheet.setColumnWidth(7, 12);
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

  static String _statusBgColor(String status) {
    switch (status) {
      case 'Tinggi':
        return _colorTinggi;
      case 'Normal':
        return _colorWaspada;
      default: // Rendah
        return _colorRendah;
    }
  }

  static String _getStatus(double evaporasi) {
    if (evaporasi > 10.0) return 'Tinggi';
    if (evaporasi >= 2.0) return 'Normal';
    return 'Rendah';
  }
}
