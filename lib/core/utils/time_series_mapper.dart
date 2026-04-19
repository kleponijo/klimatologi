class TimeSeriesMapper {
  /// =========================
  /// 📅 DAILY (24 JAM)
  /// =========================
  static List<double> toDaily<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
  }) {
    final now = DateTime.now();
    final slots = List<double>.filled(24, 0.0);

    for (final item in data) {
      final time = getTime(item);

      if (_isSameDay(time, now)) {
        slots[time.hour] = getValue(item);
      }
    }

    return slots;
  }

  /// =========================
  /// 📅 WEEKLY (7 HARI)
  /// =========================
  static List<double> toWeekly<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
  }) {
    final now = DateTime.now();
    final slots = List<double>.filled(7, 0.0);

    DateTime startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (final item in data) {
      final time = getTime(item);

      if (time.isAfter(startOfWeek)) {
        slots[time.weekday - 1] = getValue(item);
      }
    }

    return slots;
  }

  /// =========================
  /// 📅 MONTHLY
  /// =========================
  static List<double> toMonthly<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
  }) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final slots = List<double>.filled(daysInMonth, 0.0);

    for (final item in data) {
      final time = getTime(item);

      if (time.month == now.month && time.year == now.year) {
        slots[time.day - 1] = getValue(item);
      }
    }

    return slots;
  }

  /// =========================
  /// 🧠 HELPER
  /// =========================
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}