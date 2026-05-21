// packages/monitoring_repository/lib/src/models/evaporasi.dart

class Evaporasi {
  final double evaporasi;
  final double suhu;
  final double tinggiAir;
  final double acuanPagi;
  final String status;
  final DateTime timestamp;

  Evaporasi({
    required this.evaporasi,
    required this.suhu,
    required this.tinggiAir,
    required this.acuanPagi,
    required this.status,
    required this.timestamp,
  });

  static final empty = Evaporasi(
    evaporasi: 0.0,
    suhu: 0.0,
    tinggiAir: 0.0,
    acuanPagi: 0.0,
    status: "Normal",
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory Evaporasi.fromJson(Map<dynamic, dynamic> json) {
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

    // ── Evaporasi (mm) ───────────────────────────────────
    // Dibalik: Mengambil dari field tinggi_air karena ditukar
    final evaporasiRaw = toDoubleSafe(
      json['tinggi_air_cm'] ??
          json['tinggi_air'] ??
          json['tinggiAir'] ??
          json['tinggiAir_cm'] ??
          json['water_level'] ??
          json['waterLevel'] ??
          json['tinggi_air_m'] ??
          json['tinggiAir_m'],
    );
    // Konversi cm ke mm dengan mengalikan 10
    final evaporasiVal = evaporasiRaw * 10.0;

    // ── Suhu (°C) ────────────────────────────────────────
    // FIX: tambah 'suhu_air_c' sesuai field yang dikirim ESP32
    final suhuRaw = toDoubleSafe(
      json['suhu_air_c'] ??     // ← ESP32 kirim field ini
          json['suhu_air'] ??
          json['suhu'] ??
          json['suhuAir'] ??
          json['temp'] ??
          json['temperature'],
    );
    final suhuVal = (suhuRaw < -50 || suhuRaw > 100) ? -1.0 : suhuRaw;

    // ── Tinggi Air (cm) ──────────────────────────────────
    // Dibalik: Mengambil dari field evaporasi karena ditukar
    final tinggiRaw = toDoubleSafe(
      json['evaporasi_mm'] ??
          json['evaporasi'] ??
          json['evaporasiMm'] ??
          json['evaporation_mm'] ??
          json['evap_mm'] ??
          json['evaporasi_value'] ??
          json['evaporasi_k'],
    );
    // Konversi mm ke cm dengan membagi 10 (misal 241.78 mm -> 24.18 cm)
    final tinggiVal = tinggiRaw / 10.0;

    // ── Sanity check ─────────────────────────────────────
    final evaporasiFiltered =
        (evaporasiVal < 0 || evaporasiVal > 50) ? 0.0 : evaporasiVal;
    final tinggiFiltered =
        (tinggiVal < 0 || tinggiVal > 100) ? 0.0 : tinggiVal;

    // ── Acuan Pagi (cm) ──────────────────────────────────
    final acuanPagiVal = toDoubleSafe(
      json['acuan_pagi_cm'] ?? json['acuan_pagi'] ?? 0.0,
    );

    // ── Status ───────────────────────────────────────────
    final statusVal = json['status']?.toString() ?? "Normal";

    // ── Parse Timestamp ──────────────────────────────────
    // FIX: Tambahkan offset +07:00 (WIB) jika string tidak punya info timezone,
    //      agar tidak terjadi mismatch 7 jam antara Firebase dan Flutter.
    DateTime parseTimestamp(dynamic rawTimestamp) {
      try {
        if (rawTimestamp is int) {
          if (rawTimestamp < 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(rawTimestamp * 1000)
                .toLocal();
          }
          return DateTime.fromMillisecondsSinceEpoch(rawTimestamp).toLocal();
        }

        if (rawTimestamp is double) {
          final value = rawTimestamp.toInt();
          if (value < 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(value * 1000).toLocal();
          }
          return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
        }

        if (rawTimestamp is String) {
          String s = rawTimestamp.trim();

          // UNIX string
          final unixValue = int.tryParse(s);
          if (unixValue != null) {
            if (unixValue < 1000000000000) {
              return DateTime.fromMillisecondsSinceEpoch(unixValue * 1000)
                  .toLocal();
            }
            return DateTime.fromMillisecondsSinceEpoch(unixValue).toLocal();
          }

          // Format "YYYY-MM-DD HH:mm:ss" → tambah 'T' agar bisa diparsing
          if (s.contains(' ') && !s.contains('T')) {
            s = s.replaceFirst(' ', 'T');
          }

          // FIX: Jika tidak ada info timezone, anggap WIB (UTC+7)
          // agar jam di chart tidak mismatch 7 jam
          if (!s.contains('+') && !s.contains('Z') && !s.contains('-', 10)) {
            s = '${s}+07:00';
          }

          final parsed = DateTime.tryParse(s);
          if (parsed != null) return parsed.toLocal();
        }
      } catch (_) {}

      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(0);

    final rawTimestamp =
        json['timestamp'] ?? json['time'] ?? json['datetime'];

    if (rawTimestamp != null) {
      timestamp = parseTimestamp(rawTimestamp);
    } else {
      // Legacy fallback: field "waktu" format "HH:mm:ss"
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
      evaporasi: evaporasiFiltered,
      suhu: suhuVal,
      tinggiAir: tinggiFiltered,
      acuanPagi: acuanPagiVal,
      status: statusVal,
      timestamp: timestamp,
    );
  }
}