part of 'wind_speed_bloc.dart';

sealed class WindSpeedEvent extends Equatable {
  const WindSpeedEvent();
  @override
  List<Object> get props => [];
}

// Perintah untuk mulai dengerin data Firebase
class WatchWindSpeedStarted extends WindSpeedEvent {}

// Perintah kalau user ganti filter (Hari Ini, Minggu Ini, dll)
class WindSpeedPeriodChanged extends WindSpeedEvent {
  final String period;
  const WindSpeedPeriodChanged(this.period);
}

// Event internal: saat data baru masuk dari Firebase
class _WindSpeedUpdated extends WindSpeedEvent {
  final MyWindSpeed data;
  const _WindSpeedUpdated(this.data);
  @override
  List<Object> get props => [data];
}
