class Evaporasi {
  final double evaporasi;
  final double suhu;
  final double tinggiAir;
  final DateTime timestamp;

  Evaporasi({
    required this.evaporasi,
    required this.suhu,
    required this.tinggiAir,
    required this.timestamp,
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

    // ✅ Prioritas waktu sesuai firmware ESP32:
    // 1) timestamp (Unix atau ISO string, kalau pernah dikirim)
    // 2) datetime ("YYYY-MM-DD HH:MM:SS")
    // 3) waktu ("HH:MM:SS") fallback (pakai tanggal hari ini)
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp != null) {
      if (rawTimestamp is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
      } else if (rawTimestamp is double) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt());
      } else if (rawTimestamp is String) {
        final unix = int.tryParse(rawTimestamp);
        if (unix != null) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(unix);
        } else {
          final parsed = DateTime.tryParse(rawTimestamp);
          if (parsed != null) {
            timestamp = parsed;
          }
        }
      }
    } else {
      final datetimeStr = json['datetime'] as String?;
      if (datetimeStr != null) {
        final parsed = DateTime.tryParse(datetimeStr);
        if (parsed != null) {
          timestamp = parsed;
        }
      } else {
        final waktuStr = json['waktu'] as String?;
        if (waktuStr != null) {
          final parts = waktuStr.split(':');
          if (parts.length >= 2) {
            final jam = int.tryParse(parts[0]) ?? 0;
            final menit = int.tryParse(parts[1]) ?? 0;
            final detik = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
            timestamp = DateTime(
              now.year,
              now.month,
              now.day,
              jam,
              menit,
              detik,
            );
          }
        }
      }
    }

    // Field di DB (dari info Anda):
    // - evaporasi_mm
    // - suhu_air
    // - tinggi_air_cm
    // Namun tetap toleran jika key berubah.
    final evaporasiVal = json['evaporasi_mm'] ?? json['evaporasi'] ?? 0;
    final suhuVal = json['suhu_air'] ?? json['suhu'] ?? 0;
    final tinggiVal = json['tinggi_air_cm'] ?? json['tinggi_air'] ?? 0;

    double toDoubleSafe(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return Evaporasi(
      evaporasi: (json['evaporasi_mm'] ?? 0).toDouble(),
      suhu: suhu,
      tinggiAir: tinggi,
      status: json['status'] ?? '',
      timestamp: TimestampParser.parse(rawTime), // ✅ pakai TimestampParser
    );
  }
}
