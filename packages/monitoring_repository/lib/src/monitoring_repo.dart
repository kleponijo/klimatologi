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

  // ── Anemometer Settings ──────────────────────────────────────
  /// Baca semua settings dari /anemometer/settings/
  /// Return map dengan keys:
  ///   k_faktor (double), radius_m (double),
  ///   interval_realtime_ms (int), interval_history_ms (int)
  Future<Map<String, dynamic>> getAnemometerSettings();

  /// Tulis settings ke /anemometer/settings/ (field yang null tidak ditulis)
  Future<void> updateAnemometerSettings({
    double? kFaktor,
    double? radiusM,
    int? intervalRealtimeMs,
    int? intervalHistoryMs,
  });

  // ── Device Logs ──────────────────────────────────────────────
  /// Ambil N log terakhir dari /anemometer/{deviceId}/logs
  Future<List<Map<String, dynamic>>> getDeviceLogs(
    String deviceId, {
    int limit = 50,
  });

  Future<void> sendRemoteRestart(String deviceId);
}
