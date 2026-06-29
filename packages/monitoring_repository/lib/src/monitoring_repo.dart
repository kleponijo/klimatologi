abstract class MonitoringRepository {
  // ── Stream & Snapshot ────────────────────────────────────────
  Stream<T> getSensorStream<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );

  // fungsi untuk ambil sensor sekali
  Future<T> getSensorSnapshot<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );

  // Fungsi untuk ambil riwayat (List)
  Future<List<T>> getSensorHistory<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );

  Future<Map<String, dynamic>> getAnemometerSettings();

  Future<void> updateAnemometerSettings({
    int? intervalRealtimeMs,
    int? intervalAverageMs,
    int? intervalHistoryMs,
    int? magnetCount,
  });

  // ── Device Logs ──────────────────────────────────────────────
  /// Ambil N log terakhir dari /anemometer/{deviceId}/logs
  Future<List<Map<String, dynamic>>> getDeviceLogs(
    String deviceId, {
    int limit = 50,
  });

  Future<void> sendRemoteRestart(String deviceId);
  Future<void> deleteDeviceLogs(String deviceId, List<String> keys);
  Future<Map<String, T>> getSensorHistoryWithKeys<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  );
  Future<void> deleteHistoryByKeys(String path, List<String> keys);
  Future<void> deleteAllHistory(String path);
}
