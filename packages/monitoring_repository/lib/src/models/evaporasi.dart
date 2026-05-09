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
    final tinggi = (json['tinggi'] ?? json['tinggi_air'] ?? 0).toDouble();

    // ✅ Prioritas waktu sesuai firmware ESP32:
    // 1) timestamp (Unix, kalau pernah dikirim)
    // 2) datetime ("YYYY-MM-DD HH:MM:SS")
    // 3) waktu ("HH:MM:SS") fallback (akan memakai tanggal hari ini)
    final rawTime = json['timestamp'] ?? json['datetime'] ?? json['waktu'];


    return Evaporasi(
      evaporasi: (json['evaporasi'] ?? 0).toDouble(),
      suhu: suhu,
      tinggiAir: tinggi,
      status: json['status'] ?? '',
      timestamp: TimestampParser.parse(rawTime), // ✅ pakai TimestampParser
    );
  }
}
