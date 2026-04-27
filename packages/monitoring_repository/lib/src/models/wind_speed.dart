class MyWindSpeed {
  double speed;

  DateTime timestamp;

  MyWindSpeed({required this.speed, required this.timestamp});

  static final empty = MyWindSpeed(
    speed: 0.0,

    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory MyWindSpeed.fromJson(Map<dynamic, dynamic> json) {
    return MyWindSpeed(
      speed: (json['speed'] ?? 0).toDouble(),

      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] ?? 0) * 1000, // kalau dari Unix detik
      ).toLocal(),
    );
  }
}
