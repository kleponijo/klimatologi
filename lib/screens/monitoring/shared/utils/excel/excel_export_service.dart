import 'atmospheric_excel_builder.dart';

class ExcelExportService {
  ExcelExportService._();

  static Future<void> atmospheric({
    required double pressure,
    required int timeMs,
    required DateTime timestamp,
    List<Map<String, dynamic>>? historyData,
  }) =>
      exportAtmosphericExcel(
        pressure: pressure,
        timeMs: timeMs,
        timestamp: timestamp,
        historyData: historyData,
      );
}
