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

        // Karena RTDB push() menghasilkan Map dengan ID unik,
        // kita ambil values-nya saja dan ubah jadi List objek
        return data.values.map((item) {
          return mapper(item as Map<dynamic, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
