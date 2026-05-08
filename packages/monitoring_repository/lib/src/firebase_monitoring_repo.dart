import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'monitoring_repo.dart';
import 'models/has_timestamp.dart';
import 'models/models.dart';

class FirebaseMonitoringRepo implements MonitoringRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  @override
  Stream<T> getSensorStream<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  ) {
    return _db.ref(path).onValue.map((event) {
      final value = event.snapshot.value;
      return mapper(value is Map ? value : {});
    });
  }

  @override
  Future<T> getSensorSnapshot<T>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper,
  ) async {
    final snapshot = await _db.ref(path).get();
    return mapper(snapshot.value as Map<dynamic, dynamic>? ?? {});
  }

  @override
  Future<List<T>> getSensorHistory<T extends HasTimestamp>(
    String path,
    T Function(Map<dynamic, dynamic> json) mapper, {
    String? orderByChild,
    int limit = 500,
  }) async {
    try {
      Query query = _db.ref(path);

      if (orderByChild != null) {
        query = query.orderByChild(orderByChild).limitToLast(limit);
      } else {
        query = query.limitToLast(limit);
      }

      final snapshot = await query.get();
      if (!snapshot.exists || snapshot.value is! Map) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = data.values
          .whereType<Map>()
          .map((item) => mapper(item))
          .toList();

      // Sort generik — works untuk SEMUA sensor karena T extends HasTimestamp
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } catch (_) {
      return [];
    }
  }
}
