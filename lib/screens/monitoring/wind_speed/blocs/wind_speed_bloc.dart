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

        await emit.forEach<MyWindSpeed>(
          _repository.getSensorStream(
              'anemometer/realtime', (json) => MyWindSpeed.fromJson(json)),
          onData: (data) {
            // Mengambil list lama dan menambah data baru untuk grafik
            final updatedSpeeds = List<double>.from(state.dailySpeeds)
              ..add(data.speed);
            // Batasi jumlah data di grafik (misal cuma simpan 20 data terakhir agar tidak berat)
            if (updatedSpeeds.length > 20) {
              updatedSpeeds.removeAt(0);
            }

            return state.copyWith(
              currentSpeed: data.speed,
              dailySpeeds: updatedSpeeds, // Update list grafik
              isLoading: false,
            );
          },
          onError: (error, stackTrace) => state.copyWith(isLoading: false),
        ); // emit forEach
      },
      transformer: restartable(),
    );

    on<WindSpeedPeriodChanged>((event, emit) {
      emit(state.copyWith(selectedPeriod: event.period));
    });
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
