import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

/// === ambil data dari realtime database firebase === ///
class FirebaseMonitoringRepo implements MonitoringRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Satu fungsi untuk semua jenis sensor
  // Kamu cukup masukkan "path" database-nya saja
  @override
  Stream<T> getSensorStream<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  ) {
    return _db.ref(path).onValue.map((event) {
      final Object? value = event.snapshot.value;
      return mapper(value is Map ? value : {});
    });
  }

  // ── Snapshot ─────────────────────────────────────────────────
  @override
  Future<T> getSensorSnapshot<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  ) async {
    final snapshot = await _db.ref(path).get();
    return mapper(
      snapshot.value is Map ? snapshot.value as Map<dynamic, dynamic> : {},
    );
  }

  // ── History ──────────────────────────────────────────────────
  @override
  Future<List<T>> getSensorHistory<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  ) async {
    try {
      final snapshot = await _db.ref(path).get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final list = data.values
            .map((item) => mapper(item as Map<dynamic, dynamic>))
            .toList();
        list.sort((a, b) {
          try {
            final aT = (a as dynamic).timestamp as DateTime;
            final bT = (b as dynamic).timestamp as DateTime;
            return aT.compareTo(bT);
          } catch (_) {
            return 0;
          }
        });
        return list;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Anemometer Settings ──────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getAnemometerSettings() async {
    // Default sama dengan cfg_config.h di ESP
    const defaults = <String, dynamic>{
      'k_faktor': 50.0,
      'radius_m': 0.08,
      'interval_realtime_ms': 1000,
      'interval_history_ms': 3600000,
    };
    try {
      final snapshot = await _db.ref('anemometer/settings').get();
      if (snapshot.exists && snapshot.value is Map) {
        final raw = snapshot.value as Map<dynamic, dynamic>;
        return {
          'k_faktor': (raw['k_faktor'] ?? defaults['k_faktor']).toDouble(),
          'radius_m': (raw['radius_m'] ?? defaults['radius_m']).toDouble(),
          'interval_realtime_ms':
              (raw['interval_realtime_ms'] ?? defaults['interval_realtime_ms'])
                  as int,
          'interval_history_ms':
              (raw['interval_history_ms'] ?? defaults['interval_history_ms'])
                  as int,
        };
      }
    } catch (_) {}

    return defaults;
  }

  // ── Tulis settings ke Firebase (dari app) ────────────────────
  @override
  Future<void> updateAnemometerSettings({
    double? kFaktor,
    double? radiusM,
    int? intervalRealtimeMs,
    int? intervalHistoryMs,
  }) async {
    final updates = <String, dynamic>{};
    if (kFaktor != null) updates['k_faktor'] = kFaktor;
    if (intervalRealtimeMs != null)
      updates['interval_realtime_ms'] = intervalRealtimeMs;
    if (intervalHistoryMs != null)
      updates['interval_history_ms'] = intervalHistoryMs;
    if (updates.isNotEmpty) {
      await _db.ref('anemometer/settings').update(updates);
    }
  }

  // ── Ambil logs dari device tertentu ──────────────────────────
  @override
  Future<List<Map<String, dynamic>>> getDeviceLogs(
    String deviceId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _db
          .ref('anemometer/$deviceId/logs')
          .orderByKey()
          .limitToLast(limit)
          .get();

      if (snapshot.exists && snapshot.value is Map) {
        final raw = snapshot.value as Map<dynamic, dynamic>;
        final list = raw.entries.map((e) {
          final v = e.value as Map<dynamic, dynamic>;
          return {
            'msg': v['msg'] ?? '',
            'timestamp': DateTime.fromMillisecondsSinceEpoch(
              (v['timestamp'] ?? 0) * 1000,
            ).toLocal(),
          };
        }).toList();
        list.sort(
          (a, b) => (b['timestamp'] as DateTime).compareTo(
            a['timestamp'] as DateTime,
          ),
        );
        return list;
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> sendRemoteRestart(String deviceId) async {
    await _db.ref('anemometer/$deviceId/command/restart').set(true);
  }
}
