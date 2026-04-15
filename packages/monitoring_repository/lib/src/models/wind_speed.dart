class MyWindSpeed {
  double speed;
  int pulse;
  DateTime timestamp;

  MyWindSpeed({
    required this.speed,
    required this.pulse,
    required this.timestamp,
  });

  static final empty = MyWindSpeed(
    speed: 0.0,
    pulse: 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory MyWindSpeed.fromJson(Map<dynamic, dynamic> json) {
    return MyWindSpeed(
      speed: (json['speed'] ?? 0).toDouble(),
      pulse: (json['pulse'] ?? 0) as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] ?? 0) * 1000, // kalau dari Unix detik
      ).toLocal(),
    );
  }
}
