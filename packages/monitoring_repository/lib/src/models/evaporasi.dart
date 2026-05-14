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
    // ===========================
    // 🔧 HELPER: parse angka aman
    // ===========================
    double toDoubleSafe(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final s = v.trim();
        final normalized = s.replaceAll(',', '.');
        final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(normalized);
        if (match != null) {
          return double.tryParse(match.group(0)!) ?? 0.0;
        }
        return double.tryParse(normalized) ?? 0.0;
      }
      return 0.0;
    }

    // ===========================
    // 💧 EVAPORASI
    // ✅ Firebase: evaporasi_mm → prioritas pertama
    // ===========================
    final evaporasiVal = toDoubleSafe(
      json['evaporasi_mm'] ??
          json['evaporasi'] ??
          json['evaporasiMm'] ??
          json['evaporation_mm'] ??
          json['evap_mm'] ??
          json['evaporasi_value'] ??
          json['evaporasi_k'],
    );

    // ===========================
    // 🌡️ SUHU
    // ✅ Firebase: suhu_air → prioritas pertama
    // ===========================
    final suhuRaw = toDoubleSafe(
      json['suhu_air'] ??      // ✅ field utama di Firebase
          json['suhu'] ??
          json['suhuAir'] ??
          json['temp'] ??
          json['temperature'],
    );
    // Filter nilai tidak masuk akal (sensor error)
    final suhuVal = (suhuRaw < -50 || suhuRaw > 100) ? 0.0 : suhuRaw;

    // ===========================
    // 💦 TINGGI AIR
    // ✅ Firebase: tinggi_air_cm → prioritas pertama
    // ===========================
    final tinggiVal = toDoubleSafe(
      json['tinggi_air_cm'] ??  // ✅ field utama di Firebase
          json['tinggi_air'] ??
          json['tinggiAir'] ??
          json['tinggiAir_cm'] ??
          json['water_level'] ??
          json['waterLevel'] ??
          json['tinggi_air_m'] ??
          json['tinggiAir_m'],
    );

    // ===========================
    // 🕐 TIMESTAMP
    // ✅ Firebase: datetime "2026-05-14 01:25:25" → prioritas pertama
    // ===========================
    DateTime timestamp = DateTime.now();

    // Urutan prioritas sesuai field yang ada di Firebase
    final rawTimestamp =
        json['datetime'] ??    // ✅ field utama di Firebase
        json['timestamp'] ??
        json['time'];

    if (rawTimestamp != null) {
      if (rawTimestamp is String) {
        final s = rawTimestamp.trim();
        // Coba parse sebagai integer unix ms/s
        final unixMs = int.tryParse(s);
        if (unixMs != null) {
          timestamp = unixMs < 1000000000000
              ? DateTime.fromMillisecondsSinceEpoch(unixMs * 1000)
              : DateTime.fromMillisecondsSinceEpoch(unixMs);
        } else {
          // ✅ Format Firebase: "2026-05-14 01:25:25"
          // DateTime.tryParse butuh ISO format → ganti spasi dengan T
          final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
          timestamp = DateTime.tryParse(iso) ?? DateTime.now();
        }
      } else if (rawTimestamp is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
      } else if (rawTimestamp is double) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt());
      }
    } else {
      // Legacy fallback: field 'waktu' format "HH:mm:ss"
      final waktuStr = json['waktu'] as String?;
      if (waktuStr != null) {
        final parts = waktuStr.split(':');
        if (parts.length >= 2) {
          final jam = int.tryParse(parts[0]) ?? 0;
          final menit = int.tryParse(parts[1]) ?? 0;
          final detik =
              parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
          final now = DateTime.now();
          timestamp =
              DateTime(now.year, now.month, now.day, jam, menit, detik);
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