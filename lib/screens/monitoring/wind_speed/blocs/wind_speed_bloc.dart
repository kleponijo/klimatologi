import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

part 'wind_speed_event.dart';
part 'wind_speed_state.dart';

class WindSpeedBloc extends Bloc<WindSpeedEvent, WindSpeedState> {
  final MonitoringRepository _repository;
  StreamSubscription? _subscription;

  WindSpeedBloc({required MonitoringRepository repository})
      : _repository = repository,
        super(const WindSpeedState()) {
    // Handler saat aplikasi minta mulai monitoring
    on<WatchWindSpeedStarted>((event, emit) {
      _subscription?.cancel();
      _subscription = _repository
          .getSensorStream(
              'anemometer/realtime', (json) => MyWindSpeed.fromJson(json))
          .listen((data) => add(_WindSpeedUpdated(data)));
    });

    // Handler saat ada data baru masuk (Pindahan logika dari Screen)
    on<_WindSpeedUpdated>((event, emit) {
      // Di sini kamu bisa tambahkan logika hitung rata-rata/grafik harian
      emit(state.copyWith(
        currentSpeed: event.data.speed,
        isLoading: false,
      ));
    });

    on<WindSpeedPeriodChanged>((event, emit) {
      emit(state.copyWith(selectedPeriod: event.period));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel(); // Supaya tidak bocor memorinya
    return super.close();
  }
}
