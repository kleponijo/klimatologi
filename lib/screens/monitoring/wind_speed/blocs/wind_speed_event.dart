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

// ═══════════════════════════════════════════════════════════
//  DELETE EVENTS
// ═══════════════════════════════════════════════════════════

/// Hapus SEMUA riwayat dari Firebase
class WindSpeedDeleteAllRequested extends WindSpeedEvent {
  const WindSpeedDeleteAllRequested();
}

/// Hapus riwayat pada tanggal tertentu
class WindSpeedDeleteByDateRequested extends WindSpeedEvent {
  final DateTime date;
  const WindSpeedDeleteByDateRequested(this.date);

  @override
  List<Object?> get props => [date];
}

/// Hapus riwayat dalam rentang tanggal (inklusif)
class WindSpeedDeleteByDateRangeRequested extends WindSpeedEvent {
  final DateTime start;
  final DateTime end;
  const WindSpeedDeleteByDateRangeRequested({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

/// Hapus riwayat dalam rentang jam pada tanggal tertentu
class WindSpeedDeleteByHourRangeRequested extends WindSpeedEvent {
  final DateTime date;
  final int startHour; // 0–23
  final int endHour; // 0–23, harus >= startHour
  const WindSpeedDeleteByHourRangeRequested({
    required this.date,
    required this.startHour,
    required this.endHour,
  });

  @override
  List<Object?> get props => [date, startHour, endHour];
}

class _WindSpeedHistoryUpdated extends WindSpeedEvent {
  final Map<String, MyWindSpeed> historyMap;
  const _WindSpeedHistoryUpdated(this.historyMap);
  @override
  List<Object?> get props => [historyMap];
}
