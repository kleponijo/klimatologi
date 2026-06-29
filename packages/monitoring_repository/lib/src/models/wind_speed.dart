class MyWindSpeed {
  final double windwegKm;
  final double maxWindwegKm;
  final int sampleCount;
  final DateTime timestamp;

  MyWindSpeed({
    required this.windwegKm,
    this.maxWindwegKm = 0.0,
    this.sampleCount = 0,
    required this.timestamp,
  });

  // Getter alias untuk kompatibilitas dengan bloc/chart yang pakai .speed
  double get speed => windwegKm;
  double get maxSpeed => maxWindwegKm;

  static final empty = MyWindSpeed(
    windwegKm: 0.0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory MyWindSpeed.fromJson(Map<dynamic, dynamic> json) {
    return MyWindSpeed(
      // realtime  → windweg_km
      // history   → avg_windweg_km
      // average   → windweg_km
      windwegKm:
          ((json['windweg_km'] ??
                  json['avg_windweg_km'] ??
                  json['speed_ms'] ?? // fallback data lama
                  json['speed'] ??
                  0))
              .toDouble(),
      maxWindwegKm: (json['max_windweg_km'] ?? 0).toDouble(),
      sampleCount: (json['sample_count'] ?? 0) as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] ?? 0) * 1000,
      ).toLocal(),
    );
  }
}
