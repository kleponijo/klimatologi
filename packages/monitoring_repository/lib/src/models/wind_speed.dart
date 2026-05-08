import 'has_timestamp.dart';
import '../utils/timestamp_parser.dart';

class MyWindSpeed implements HasTimestamp {
  final double speed;

  @override
  final DateTime timestamp;

  MyWindSpeed({required this.speed, required this.timestamp});

  static final empty = MyWindSpeed(
    speed: 0.0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory MyWindSpeed.fromJson(Map<dynamic, dynamic> json) {
    return MyWindSpeed(
      speed: (json['speed'] ?? 0).toDouble(),
      timestamp: TimestampParser.parse(json['timestamp']),
    );
  }
}
