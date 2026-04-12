import 'package:firebase_database/firebase_database.dart';

abstract class MonitoringRepository {
  Stream<DatabaseEvent> getSensorStream(String path);

  Future<DataSnapshot> getSensorSnapshot(String path);
}
