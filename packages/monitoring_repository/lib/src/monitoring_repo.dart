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
<<<<<<< Updated upstream
=======

  // ── Device Logs ──────────────────────────────────────────────
  /// Ambil N log terakhir dari /anemometer/{deviceId}/logs
  Future<List<Map<String, dynamic>>> getDeviceLogs(
    String deviceId, {
    int limit = 50,
  });

  Future<void> sendRemoteRestart(String deviceId);

  Future<void> deleteDeviceLogs(String deviceId, List<String> keys);

  // ── Delete Sensor History ────────────────────────────────────
  /// Delete all history untuk sensor tertentu
  Future<void> deleteSensorHistoryAll(String path);

  /// Delete history hanya untuk tanggal tertentu
  Future<void> deleteSensorHistoryByDate(String path, DateTime date);

  /// Delete history untuk range tanggal (inclusive)
  Future<void> deleteSensorHistoryByDateRange(
    String path,
    DateTime startDate,
    DateTime endDate,
  );

  /// Delete history untuk jam tertentu dalam sehari
  /// hourFrom & hourTo: 0-23, inclusive
  Future<void> deleteSensorHistoryByHourRange(
    String path,
    DateTime date,
    int hourFrom,
    int hourTo,
  );
>>>>>>> Stashed changes
}
