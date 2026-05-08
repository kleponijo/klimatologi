/// file monitoring_repo.dart di "C:\App_project\klimatologi\packages\monitoring_repository\lib\src\monitoring_repo.dart"

import 'models/has_timestamp.dart';

abstract class MonitoringRepository {
  Stream<T> getSensorStream<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );

  Future<T> getSensorSnapshot<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );

  Future<List<T>> getSensorHistory<T extends HasTimestamp>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper, {
    String? orderByChild,
    int limit = 500,
  });
}
