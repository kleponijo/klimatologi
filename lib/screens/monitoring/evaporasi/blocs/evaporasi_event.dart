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
