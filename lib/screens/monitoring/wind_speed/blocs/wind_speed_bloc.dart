import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
part 'wind_speed_event.dart';
part 'wind_speed_state.dart';

class WindSpeedBloc extends Bloc<WindSpeedEvent, WindSpeedState> {
  final MonitoringRepository _repository;

  WindSpeedBloc({required MonitoringRepository repository})
      : _repository = repository,
        super(const WindSpeedState()) {
    // Handler saat aplikasi minta mulai monitoring
    on<WatchWindSpeedStarted>(
      (event, emit) async {
        emit(state.copyWith(isLoading: true));

        // 1. Ambil semua history
        final history = await _repository.getSensorHistory(
            'anemometer/history', (json) => MyWindSpeed.fromJson(json));

        // 2. Petakan ke 24 jam (Harian)
        final List<double> dailyGraph = _mapHistoryToDaily(history);

        emit(state.copyWith(
          dailySpeeds: dailyGraph,
          isLoading: false,
        ));

        // 2. Monitoring Real-time
        await emit.forEach<MyWindSpeed>(
          _repository.getSensorStream(
              'anemometer/realtime', (json) => MyWindSpeed.fromJson(json)),
          onData: (data) {
            // Mengambil list lama dan menambah data baru untuk grafik

            return state.copyWith(
              currentSpeed: data.speed,
              isLoading: false,
            );
          },
          onError: (error, stackTrace) => state.copyWith(isLoading: false),
        ); // emit forEach
      },
      transformer: restartable(),
    );

    on<WindSpeedPeriodChanged>((event, emit) async {
      emit(state.copyWith(selectedPeriod: event.period));
      // Ambil ulang history dari database
      final history = await _repository.getSensorHistory(
          'anemometer/history', (json) => MyWindSpeed.fromJson(json));
      List<double> updatedGraph;

      // Pilih mapper berdasarkan pilihan user
      if (event.period == "Minggu Ini") {
        updatedGraph = _mapHistoryToWeekly(history);
      } else if (event.period == "Bulan Ini") {
        updatedGraph = _mapHistoryToMonthly(history);
      } else {
        updatedGraph = _mapHistoryToDaily(history);
      }

      emit(state.copyWith(
        dailySpeeds: updatedGraph,
        isLoading: false,
      ));
    });
  }

  @override
  Future<void> close() => super.close();
}

List<double> _mapHistoryToDaily(List<MyWindSpeed> history) {
  // Buat list 24 angka nol (representasi jam 00:00 - 23:00)
  List<double> slots = List.generate(24, (_) => 0.0);

  for (var item in history) {
    // Ubah timestamp UTC ke jam lokal
    DateTime date = item.timestamp;

    // Jika data ini adalah data hari ini, masukkan ke slot jamnya
    if (date.day == DateTime.now().day) {
      slots[date.hour] = item.speed;
    }
  }
  return slots;
}

// Mapper Mingguan (7 Slot: Senin - Minggu)
List<double> _mapHistoryToWeekly(List<MyWindSpeed> history) {
  List<double> slots = List.generate(7, (_) => 0.0);
  final now = DateTime.now();

  // Mencari awal minggu ini (Senin)
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  for (var item in history) {
    if (item.timestamp.isAfter(startOfWeek)) {
      // index 0 = Senin, dst.
      slots[item.timestamp.weekday - 1] = item.speed;
    }
  }
  return slots;
}

// Mapper Bulanan (Sesuai jumlah hari di bulan ini)
List<double> _mapHistoryToMonthly(List<MyWindSpeed> history) {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  List<double> slots = List.generate(daysInMonth, (_) => 0.0);

  for (var item in history) {
    if (item.timestamp.month == now.month && item.timestamp.year == now.year) {
      // index 0 = Tanggal 1, dst.
      slots[item.timestamp.day - 1] = item.speed;
    }
  }
  return slots;
}
