import 'package:monitoring_repository/monitoring_repository.dart';

class WindSpeedBloc {
  final MonitoringRepository _repo;

  WindSpeedBloc({required MonitoringRepository repo}) : _repo = repo;

  void startListening() {
    // 3. Sekarang kamu bisa akses _repo di dalam lingkup class ini
    _repo.getSensorStream('anemometer/realtime').listen((event) {
      // Olah datanya di sini
      print(event.snapshot.value);
    });
  }
}
