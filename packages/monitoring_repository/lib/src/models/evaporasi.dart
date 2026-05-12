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
      if (v is String) {
        final s = v.trim();
        // dukung format seperti "12.3 cm" / "12,3" / "-"
        final normalized = s.replaceAll(',', '.');
        final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(normalized);
        if (match != null) {
          return double.tryParse(match.group(0)!) ?? 0;
        }
        return double.tryParse(normalized) ?? 0;
      }
      return 0;
    }

    final evaporasiVal = toDoubleSafe(
      json['evaporasi_mm'] ??
          json['evaporasi'] ??
          json['evaporasiMm'] ??
          json['evaporation_mm'] ??
          json['evap_mm'] ??
          json['evaporasi_mm_'] ??
          json['evaporasi_mm '] ??
          json['evaporasi_value'] ??
          json['evaporasi_mm_k'] ??
          json['evaporasi_k'],
    );

    final suhuVal = toDoubleSafe(
      json['suhu'] ??
          json['suhu_air'] ??
          json['suhuAir'] ??
          json['temp'] ??
          json['temperature'],
    );

    // Banyak kemungkinan penamaan field tinggi air.
    // Pakai beberapa alias agar tidak default 0.
    final tinggiVal = toDoubleSafe(
      json['tinggi_air_cm'] ??
          json['tinggi_air'] ??
          json['tinggiAir'] ??
          json['tinggiAir_cm'] ??
          json['tinggi_air_cm_'] ??
          json['tinggi_air_cm '] ??
          json['water_level'] ??
          json['waterLevel'] ??
          json['tinggi_air_m'] ??
          json['tinggiAir_m'],
    );


    // Default timestamp: fallback now (kalau field waktu tidak ada).
    // Catatan: untuk Firebase seharusnya timestamp dikirim konsisten (ms atau ISO string).
    DateTime timestamp = DateTime.now();

    // dukung beberapa kemungkinan penamaan timestamp
    final rawTimestamp =
        json['timestamp'] ?? json['time'] ?? json['waktu'] ?? json['datetime'];

    if (rawTimestamp != null) { 

      if (rawTimestamp is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
      } else if (rawTimestamp is double) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt());
      } else if (rawTimestamp is String) {
        final s = rawTimestamp.trim();
        // jika string berupa angka (ms/seconds)
        final unixMs = int.tryParse(s);
        if (unixMs != null) {
          // heuristik: kalau nilainya terlalu kecil kemungkinan seconds
          if (unixMs < 1000000000000) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(unixMs * 1000);
          } else {
            timestamp = DateTime.fromMillisecondsSinceEpoch(unixMs);
          }
        } else {
          final parsed = DateTime.tryParse(s);
          if (parsed != null) {
            timestamp = parsed;
          }
        }
      }
    } else {
      // legacy fallback dari field terpisah
      final datetimeStr = json['datetime'] as String?;
      if (datetimeStr != null) {
        final parsed = DateTime.tryParse(datetimeStr);
        if (parsed != null) timestamp = parsed;
      }

      final waktuStr = json['waktu'] as String?;
      if (waktuStr != null && datetimeStr == null) {
        final parts = waktuStr.split(':');
        if (parts.length >= 2) {
          final jam = int.tryParse(parts[0]) ?? 0;
          final menit = int.tryParse(parts[1]) ?? 0;
          final detik = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
          final now = DateTime.now();
          timestamp = DateTime(now.year, now.month, now.day, jam, menit, detik);
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
