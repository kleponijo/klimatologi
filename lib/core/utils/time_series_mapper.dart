import 'package:monitoring_repository/monitoring_repository.dart';

class TimeSeriesMapper {
<<<<<<< Updated upstream
  /// =========================
  /// 📅 DAILY (24 JAM)
  /// =========================
=======
  // ============================================================
  // NOTE: Removed _filterSpike() and _interpolate()
  // Reason: Trust Firebase data from ESP, don't double-process
  // ============================================================

  // ============================================================
  // DAILY (24 JAM) - Trust Firebase data, just aggregate by hour
  // ============================================================
>>>>>>> Stashed changes
  static List<double> toDaily<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
  }) {
    final now = DateTime.now();
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
    final sums = List<double>.filled(24, 0.0);
    final counts = List<int>.filled(24, 0);

    for (final item in data) {
      final time = getTime(item);

      if (_isSameDay(time, now)) {
<<<<<<< Updated upstream
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
=======
        final localTime = time.toLocal();
        final hour = localTime.hour;
        if (hour >= 0 && hour < 24) {
          sums[hour] += getValue(item);
          counts[hour]++;
        }
      }
    }

    // Average per hour, return as-is (no filtering/interpolation)
    return List<double>.generate(
        24, (i) => counts[i] == 0 ? 0.0 : sums[i] / counts[i]);
  }

  // ============================================================
  // WEEKLY - Trust Firebase data, just aggregate by day
  // ============================================================
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
    return List.generate(7, (i) {
      if (counts[i] == 0) return 0;
      return sums[i] / counts[i];
    });
  }

  /// =========================
  /// 📅 MONTHLY
  /// =========================
=======
    // Average per day, return as-is (no filtering/interpolation)
    return List<double>.generate(
        7, (i) => counts[i] == 0 ? 0.0 : sums[i] / counts[i]);
  }

  // ============================================================
  // MONTHLY - Trust Firebase data, just aggregate by day
  // ============================================================
>>>>>>> Stashed changes
  static List<double> toMonthly<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
  }) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final sums = List<double>.filled(daysInMonth, 0.0);
    final counts = List<int>.filled(daysInMonth, 0);
<<<<<<< Updated upstream

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
=======

    for (final item in data) {
      final time = getTime(item).toLocal();
      if (time.month == now.month && time.year == now.year) {
        final index = time.day - 1;
        if (index >= 0 && index < daysInMonth) {
          sums[index] += getValue(item);
          counts[index]++;
        }
      }
    }

    // Average per day, return as-is (no filtering/interpolation)
    return List<double>.generate(
        daysInMonth, (i) => counts[i] == 0 ? 0.0 : sums[i] / counts[i]);
  }

  // ============================================================
  // SPECIFIC DATE (24 JAM) - Trust Firebase data, just aggregate
  // ============================================================
  static List<double> toSpecificDate<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
    required DateTime targetDate,
  }) {
    final sums = List<double>.filled(24, 0.0);
    final counts = List<int>.filled(24, 0);

    for (final item in data) {
      final time = getTime(item);
      if (_isSameDay(time, targetDate)) {
        final localTime = time.toLocal();
        final hour = localTime.hour;
        if (hour >= 0 && hour < 24) {
          sums[hour] += getValue(item);
          counts[hour]++;
        }
      }
    }

    // Average per hour, return as-is (no filtering/interpolation)
    return List<double>.generate(
        24, (i) => counts[i] == 0 ? 0.0 : sums[i] / counts[i]);
  }

  // ============================================================
  // DATE RANGE — rentang tanggal bebas, agregasi per hari
  // Return: values (satu titik per hari) + labels (dd/MM atau dd MMM)
  // ============================================================
  static ({List<double> values, List<String> labels}) toDateRange<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    // Buat list semua hari dalam rentang
    final days = <DateTime>[];
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      days.add(cur);
      cur = cur.add(const Duration(days: 1));
    }

    if (days.isEmpty) return (values: [], labels: []);

    final sums = List<double>.filled(days.length, 0.0);
    final counts = List<int>.filled(days.length, 0);

    for (final item in data) {
      final time = getTime(item).toLocal();
      final dayOnly = DateTime(time.year, time.month, time.day);
      for (int i = 0; i < days.length; i++) {
        if (dayOnly == days[i]) {
          sums[i] += getValue(item);
          counts[i]++;
          break;
        }
      }
    }

    // Average per day, return as-is (no filtering/interpolation)
    final values = List<double>.generate(
        days.length, (i) => counts[i] == 0 ? 0.0 : sums[i] / counts[i]);

    // Label: "dd MMM" jika <= 14 hari, "dd/MM" jika lebih
    final labels = days.map((d) {
      if (days.length <= 14) {
        return '${d.day} ${_bulan(d.month)}';
      }
      return '${d.day}/${d.month}';
    }).toList();

    return (values: values, labels: labels);
  }

  static String _bulan(int m) {
    const b = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return b[m];
  }

  // ============================================================
  // HELPER
  // ============================================================
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream

  // ── Tambahkan ini setelah method smooth() ──────────────────────

  /// Shortcut untuk model yang implement HasTimestamp.
  /// Dari: TimeSeriesMapper.toDaily(data: h, getTime: (e) => e.timestamp, getValue: (e) => e.speed)
  /// Ke:  TimeSeriesMapper.dailyFrom(h, (e) => e.speed)
  static List<double> dailyFrom<T extends HasTimestamp>(
    List<T> data,
    double Function(T) getValue,
  ) =>
      smooth(
          toDaily(data: data, getTime: (e) => e.timestamp, getValue: getValue));

  static List<double> weeklyFrom<T extends HasTimestamp>(
    List<T> data,
    double Function(T) getValue,
  ) =>
      smooth(toWeekly(
          data: data, getTime: (e) => e.timestamp, getValue: getValue));

  static List<double> monthlyFrom<T extends HasTimestamp>(
    List<T> data,
    double Function(T) getValue,
  ) =>
      smooth(toMonthly(
          data: data, getTime: (e) => e.timestamp, getValue: getValue));
=======
>>>>>>> Stashed changes
}
