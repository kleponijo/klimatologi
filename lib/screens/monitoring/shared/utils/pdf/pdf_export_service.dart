import 'atmospheric_pdf_builder.dart';
import 'evaporasi_pdf_builder.dart';
import 'wind_speed_pdf_builder.dart';

/// ============================================================
/// PDF Export Service — Entry Point
/// Letakkan di: lib/screens/monitoring/shared/utils/pdf/pdf_export_service.dart
///
/// Ini cuma facade — semua logic ada di builder masing-masing.
/// Import file ini saja di screen kamu.
/// ============================================================

class PdfExportService {
  PdfExportService._(); // tidak bisa di-instantiate

  static Future<void> atmospheric({
    required double temperature,
    required double humidity,
    required double pressure,
    required double altitude,
    required DateTime timestamp,
    List<Map<String, dynamic>>? historyData,
  }) =>
      exportAtmosphericPdf(
        temperature: temperature,
        humidity: humidity,
        pressure: pressure,
        altitude: altitude,
        timestamp: timestamp,
        historyData: historyData,
      );

  static Future<void> evaporasi({
    required double evaporasi,
    required double suhu,
    required double tinggiAir,
    required DateTime timestamp,
    List<Map<String, dynamic>>? historyData,
  }) =>
      exportEvaporasiPdf(
        evaporasi: evaporasi,
        suhu: suhu,
        tinggiAir: tinggiAir,
        timestamp: timestamp,
        historyData: historyData,
      );

  static Future<void> windSpeed({
    required double currentSpeed,
    required String period,
    required List<double> speeds,
    required DateTime timestamp,
    List<Map<String, dynamic>>? historyData,
  }) =>
      exportWindSpeedPdf(
        currentSpeed: currentSpeed,
        period: period,
        speeds: speeds,
        timestamp: timestamp,
        historyData: historyData,
      );
}
