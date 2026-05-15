part of 'wind_speed_bloc.dart';

abstract class WindSpeedEvent extends Equatable {
  const WindSpeedEvent();

  @override
  List<Object?> get props => [];
}

/// Mulai watch stream realtime + ambil history
class WatchWindSpeedStarted extends WindSpeedEvent {
  const WatchWindSpeedStarted();
}

/// Ganti periode grafik: "Hari Ini" | "Minggu Ini" | "Bulan Ini"
class WindSpeedPeriodChanged extends WindSpeedEvent {
  final String period;
  const WindSpeedPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

/// Filter history berdasarkan tanggal.
/// Kirim [date] = null untuk reset (tampilkan semua)
class WindSpeedDateFilterChanged extends WindSpeedEvent {
  final DateTime? date;
  const WindSpeedDateFilterChanged(this.date);

  @override
  List<Object?> get props => [date];
}
