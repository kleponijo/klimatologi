import 'has_timestamp.dart';
import '../utils/timestamp_parser.dart';

class Evaporasi implements HasTimestamp {
  final double evaporasi;
  final double suhu;
  final double tinggiAir;
  final String status;

  @override
  final DateTime timestamp;

  Evaporasi({
    required this.evaporasi,
    required this.suhu,
    required this.tinggiAir,
    required this.timestamp,
    this.status = '',
  });

  static final empty = Evaporasi(
    evaporasi: 0.0,
    suhu: 0.0,
    tinggiAir: 0.0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory Evaporasi.fromJson(Map<dynamic, dynamic> json) {
    // ✅ Handle perbedaan field name antara history dan realtime:
    // History path  : suhu, tinggi, evaporasi, waktu
    // Realtime path : suhu_air, tinggi_air, evaporasi, waktu, status
    final suhu = (json['suhu'] ?? json['suhu_air'] ?? 0).toDouble();
    final tinggi = (json['tinggi'] ?? json['tinggi_air_cm'] ?? 0).toDouble();

    // ✅ Prioritas: timestamp (Unix, kalau firmware sudah diupdate)
    //              → fallback ke waktu ("HH:MM:SS")
    final rawTime = json['timestamp'] ?? json['waktu'];

    return Evaporasi(
      evaporasi: (json['evaporasi_mm'] ?? 0).toDouble(),
      suhu: suhu,
      tinggiAir: tinggi,
      status: json['status'] ?? '',
      timestamp: TimestampParser.parse(rawTime), // ✅ pakai TimestampParser
    );
  }
}
