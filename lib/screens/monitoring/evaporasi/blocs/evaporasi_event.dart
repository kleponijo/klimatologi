// lib/screens/monitoring/evaporasi/blocs/evaporasi_event.dart
part of 'evaporasi_bloc.dart';

abstract class EvaporasiEvent extends Equatable {
  const EvaporasiEvent();

  @override
  List<Object?> get props => [];
}

/// Mulai monitoring
class WatchEvaporasiStarted extends EvaporasiEvent {}

/// Pilih rentang tanggal untuk grafik
/// startDate == endDate → tampilkan per jam (1 hari)
/// startDate != endDate → tampilkan per hari (range)
class EvaporasiDateRangeChanged extends EvaporasiEvent {
  final DateTime startDate;
  final DateTime endDate;

  const EvaporasiDateRangeChanged({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Filter list history berdasarkan tanggal
/// Kirim date = null untuk reset
class EvaporasiDateFilterChanged extends EvaporasiEvent {
  final DateTime? date;
  const EvaporasiDateFilterChanged(this.date);

  @override
  List<Object?> get props => [date];
}