/// Semua model sensor wajib implement ini.
/// Memungkinkan sorting & TimeSeriesMapper yang generik.
abstract class HasTimestamp {
  DateTime get timestamp;
}
