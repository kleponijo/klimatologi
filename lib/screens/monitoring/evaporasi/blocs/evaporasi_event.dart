part of 'evaporasi_bloc.dart';

abstract class EvaporasiEvent extends Equatable {
  const EvaporasiEvent();

  @override
  List<Object> get props => [];
}

/// 🚀 START MONITORING
class WatchEvaporasiStarted extends EvaporasiEvent {}

/// 📊 GANTI PERIODE (Harian / Mingguan / Bulanan)
class EvaporasiPeriodChanged extends EvaporasiEvent {
  final String period;

  const EvaporasiPeriodChanged(this.period);

  @override
  List<Object> get props => [period];
}

/// 📅 PILIH TANGGAL KHUSUS (Custom Date Picker)
class EvaporasiDateSelected extends EvaporasiEvent {
  final DateTime date;

  const EvaporasiDateSelected(this.date);

  @override
  List<Object> get props => [date];
}

/// 🔄 KEMBALI KE MODE PERIOD
class EvaporasiViewModeChanged extends EvaporasiEvent {
  final EvaporasiViewMode mode;

  const EvaporasiViewModeChanged(this.mode);

  @override
  List<Object> get props => [mode];
}
