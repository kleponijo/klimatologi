class MyWindSpeed {
  final double speed; // realtime: speed_ms | history: avg_ms
  final double maxSpeed; // history only (0 jika dari realtime)
  final double kFaktor;
  final int sampleCount;
  final DateTime timestamp;

  MyWindSpeed({
    required this.speed,
    this.maxSpeed = 0.0,
    this.kFaktor = 1.0,
    this.sampleCount = 0,
    required this.timestamp,
  });

  static final empty = MyWindSpeed(
    speed: 0.0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // Dipakai untuk realtime node
  factory MyWindSpeed.fromJson(Map<dynamic, dynamic> json) {
    return MyWindSpeed(
      // support field lama 'speed' dan baru 'speed_ms'/'avg_ms'
      speed: ((json['speed_ms'] ?? json['avg_ms'] ?? json['speed']) ?? 0)
          .toDouble(),
      maxSpeed: (json['max_ms'] ?? 0).toDouble(),
      kFaktor: (json['k_faktor'] ?? 1.0).toDouble(),
      sampleCount: (json['sample_count'] ?? 0) as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] ?? 0) * 1000,
      ).toLocal(),
    );
  }
}
