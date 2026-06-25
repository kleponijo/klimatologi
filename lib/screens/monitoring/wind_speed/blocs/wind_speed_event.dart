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

// ════════════════════════════════════════════════════════════
//  DELETE HISTORY EVENTS
// ════════════════════════════════════════════════════════════
/// Hapus semua history
class WindSpeedHistoryDeleteAll extends WindSpeedEvent {
  const WindSpeedHistoryDeleteAll();
}

/// Hapus history untuk tanggal tertentu
class WindSpeedHistoryDeleteByDate extends WindSpeedEvent {
  final DateTime date;
  const WindSpeedHistoryDeleteByDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// Hapus history untuk range tanggal
class WindSpeedHistoryDeleteByDateRange extends WindSpeedEvent {
  final DateTime startDate;
  final DateTime endDate;
  const WindSpeedHistoryDeleteByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Hapus history untuk jam tertentu dalam sehari
class WindSpeedHistoryDeleteByHourRange extends WindSpeedEvent {
  final DateTime date;
  final int hourFrom;
  final int hourTo;
  const WindSpeedHistoryDeleteByHourRange(
    this.date,
    this.hourFrom,
    this.hourTo,
  );

  @override
  List<Object?> get props => [date, hourFrom, hourTo];
}
