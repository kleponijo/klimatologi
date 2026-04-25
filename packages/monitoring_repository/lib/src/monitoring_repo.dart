// import 'models/models.dart';

abstract class MonitoringRepository {
  // fungsi untuk ambil data berkali/streaming
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
}
