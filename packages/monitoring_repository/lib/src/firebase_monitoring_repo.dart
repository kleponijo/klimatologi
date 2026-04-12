import 'dart:developer';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

/// === ambil data dari realtime database firebase === ///
class FirebaseMonitoringRepo implements MonitoringRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Satu fungsi untuk semua jenis sensor
  // Kamu cukup masukkan "path" database-nya saja
  @override
  Stream<DatabaseEvent> getSensorStream(String path) {
    return _db.ref(path).onValue;
  }

  @override
  // Jika ingin mengambil data sekali saja (bukan stream)
  Future<DataSnapshot> getSensorSnapshot(String path) async {
    return await _db.ref(path).get();
  }
}
