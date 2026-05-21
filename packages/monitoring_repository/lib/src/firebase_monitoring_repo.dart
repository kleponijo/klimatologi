// import 'dart:developer';
import 'dart:async';
// import 'package:rxdart/rxdart.dart';
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
    /// === ambil data mentah dari firebase === ///
    return _db.ref(path).onValue.map((event) {
      final Object? value = event.snapshot.value;

      if (value is Map) {
        return mapper(value);
      } else {
        // Jika data kosong atau bukan Map, berikan Map kosong agar mapper tidak crash
        return mapper({});
      }
    });
  }

  @override
  // Jika ingin mengambil data sekali saja (bukan stream)
  Future<T> getSensorSnapshot<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  ) async {
    final snapshot = await _db.ref(path).get();
    final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
    return mapper(data);
  }

  @override
  Future<List<T>> getSensorHistory<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  ) async {
    try {
      // Ambil data dari path history
      final snapshot = await _db.ref(path).get();

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;

        final list = data.values.map((item) {
          return mapper(item as Map<dynamic, dynamic>);
        }).toList();

        // ✅ Sort by timestamp — Firebase push tidak selalu menghasilkan urutan kronologis.
        list.sort((a, b) {
          try {
            final aTimestamp = (a as dynamic).timestamp as DateTime;
            final bTimestamp = (b as dynamic).timestamp as DateTime;
            return aTimestamp.compareTo(bTimestamp);
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

  // ── Baca settings dari Firebase ──────────────────────────────
  Future<Map<String, dynamic>> getAnemometerSettings() async {
    try {
      final snapshot = await _db.ref('anemometer/settings').get();
      if (snapshot.exists && snapshot.value is Map) {
        final raw = snapshot.value as Map<dynamic, dynamic>;
        return {
          'k_faktor': (raw['k_faktor'] ?? 50.0).toDouble(),
          'interval_realtime_ms': (raw['interval_realtime_ms'] ?? 1000) as int,
          'interval_history_ms': (raw['interval_history_ms'] ?? 3600000) as int,
        };
      }
    } catch (_) {}
    return {
      'k_faktor': 50.0,
      'interval_realtime_ms': 1000,
      'interval_history_ms': 3600000,
    };
  }

  // ── Tulis settings ke Firebase (dari app) ────────────────────
  Future<void> updateAnemometerSettings({
    double? kFaktor,
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
}
