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
    double toDoubleSafe(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    final evaporasiVal = toDoubleSafe(
      json['evaporasi_mm'] ?? json['evaporasi'],
    );
    final suhuVal = toDoubleSafe(json['suhu'] ?? json['suhu_air']);
    final tinggiVal = toDoubleSafe(json['tinggi_air_cm'] ?? json['tinggi_air']);

    DateTime timestamp = DateTime.now();
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
            final now = DateTime.now();
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

    return Evaporasi(
      evaporasi: evaporasiVal,
      suhu: suhuVal,
      tinggiAir: tinggiVal,
      timestamp: timestamp,
    );
  }
}
