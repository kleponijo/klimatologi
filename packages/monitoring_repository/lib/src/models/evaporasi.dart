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
    final int jam = (json['jam'] ?? 0) as int;
    final int menit = (json['menit'] ?? 0) as int;

    final now = DateTime.now();

    return Evaporasi(
      evaporasi: (json['evaporasi'] ?? 0).toDouble(),
      suhu: (json['suhu'] ?? 0).toDouble(),
      tinggiAir: (json['tinggi_air'] ?? 0).toDouble(),

      /// 🔥 bikin timestamp dari jam & menit
      timestamp: DateTime(now.year, now.month, now.day, jam, menit),
    );
  }
}
