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

    final sums = List<double>.filled(24, 0.0);
    final counts = List<int>.filled(24, 0);

    for (final item in data) {
      final time = getTime(item);

      if (_isSameDay(time, now)) {
        final hour = time.hour;
        sums[hour] += getValue(item);
        counts[hour]++;
      }
    }

    return List.generate(24, (i) {
      if (counts[i] == 0) return 0;
      return sums[i] / counts[i]; // 🔥 average, bukan overwrite
    });
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

    final sums = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);

    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (final item in data) {
      final time = getTime(item);

      if (time.isAfter(startOfWeek)) {
        final index = time.weekday - 1;
        sums[index] += getValue(item);
        counts[index]++;
      }
    }

    return List.generate(7, (i) {
      if (counts[i] == 0) return 0;
      return sums[i] / counts[i];
    });
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

    final sums = List<double>.filled(daysInMonth, 0.0);
    final counts = List<int>.filled(daysInMonth, 0);

    for (final item in data) {
      final time = getTime(item);

      if (time.month == now.month && time.year == now.year) {
        final index = time.day - 1;
        sums[index] += getValue(item);
        counts[index]++;
      }
    }

    return List.generate(daysInMonth, (i) {
      if (counts[i] == 0) return 0;
      return sums[i] / counts[i];
    });
  }

  /// =========================
  /// 🧠 HELPER
  /// =========================
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<double> smooth(List<double> data) {
    if (data.length < 3) return data;

    List<double> result = [];

    for (int i = 0; i < data.length; i++) {
      if (i == 0 || i == data.length - 1) {
        result.add(data[i]);
      } else {
        final avg = (data[i - 1] + data[i] + data[i + 1]) / 3;
        result.add(avg);
      }
    }

    return result;
  }
}
