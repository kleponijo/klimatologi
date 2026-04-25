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
    final now = DateTime.now();
    DateTime timestamp = now;

    final waktuStr = json['waktu'] as String?;
    if (waktuStr != null) {
      final parts = waktuStr.split(':');
      if (parts.length >= 2) {
        final jam = int.tryParse(parts[0]) ?? 0;
        final menit = int.tryParse(parts[1]) ?? 0;
        final detik = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
        timestamp = DateTime(now.year, now.month, now.day, jam, menit, detik);
      }
    }

    return Evaporasi(
      evaporasi: (json['evaporasi'] ?? 0).toDouble(),
      suhu: (json['suhu_air'] ?? 0).toDouble(),
      tinggiAir: (json['tinggi_air'] ?? 0).toDouble(),

      /// 🔥 bikin timestamp dari jam & menit
      timestamp: timestamp,
    );
  }
}
