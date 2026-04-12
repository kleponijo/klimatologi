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
      /// == ambil value-nya dan pastikan tipenya map == ///
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

      /// == masukan ke dalam "pabrik" (mapper) agar jadi objek == ///
      return mapper(data);
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
}
