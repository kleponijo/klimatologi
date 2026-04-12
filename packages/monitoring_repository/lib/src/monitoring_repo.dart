import 'package:firebase_database/firebase_database.dart';
import 'models/models.dart';

abstract class MonitoringRepository {
  Stream<T> getSensorStream<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );

  Future<T> getSensorSnapshot<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );
}
