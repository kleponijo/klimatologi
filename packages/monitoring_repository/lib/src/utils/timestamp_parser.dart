/// Mengubah berbagai format waktu Firebase → DateTime.
///
/// Format yang didukung:
///   int   Unix detik      1777807041           (anemometer)
///   int   Unix milidetik  1777950497446        (sensor/atmospheric)
///   String "HH:MM:SS"    "11:09:00"            (Monitoring/evaporasi, intraday only)
///   String ISO 8601       "2025-03-05T14:26"   (untuk masa depan)
class TimestampParser {
  // Angka > ini dianggap milidetik (threshold: ~Nov 2001 dalam detik)
  static const int _msThreshold = 10000000000;

  static DateTime parse(dynamic raw) {
    if (raw == null) return DateTime.now();

    if (raw is int) {
      if (raw <= 0) return DateTime.now();
      if (raw > _msThreshold) {
        return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000).toLocal();
    }

    if (raw is double) return parse(raw.toInt());

    if (raw is String) {
      // "HH:MM:SS" → pakai tanggal hari ini (intraday only)
      final m = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})$').firstMatch(raw);
      if (m != null) {
        final now = DateTime.now();
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
        );
      }
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {}
    }

    return DateTime.now();
  }
}
