// lib/core/utils/time_series_mapper.dart

class TimeSeriesMapper {
  // ============================================================
  // FILTER SPIKE
  // ============================================================
  static List<double> _filterSpike(List<double> raw) {
    final valid = raw.where((v) => v > 0).toList()..sort();
    if (valid.isEmpty) return raw;
    final median = valid[valid.length ~/ 2];
    if (median <= 0) return raw;
    return raw.map((v) => (v > 0 && v > median * 3) ? -1.0 : v).toList();
  }

  // ============================================================
  // INTERPOLASI GAP
  // ============================================================
  static List<double> _interpolate(List<double> raw) {
    final result = List<double>.from(raw);
    final n = result.length;
    for (int i = 0; i < n; i++) {
      if (result[i] >= 0) continue;
      double? prev; int prevIdx = -1;
      for (int j = i - 1; j >= 0; j--) {
        if (result[j] >= 0) { prev = result[j]; prevIdx = j; break; }
      }
      double? next; int nextIdx = -1;
      for (int j = i + 1; j < n; j++) {
        if (result[j] >= 0) { next = result[j]; nextIdx = j; break; }
      }
      if (prev != null && next != null) {
        final t = (i - prevIdx) / (nextIdx - prevIdx);
        result[i] = prev + t * (next - prev);
      } else if (prev != null) {
        result[i] = prev;
      } else if (next != null) {
        result[i] = next;
      } else {
        result[i] = 0.0;
      }
    }
    return result;
  }

  // ============================================================
  // DAILY (24 JAM)
  // ============================================================
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
        final hour = time.toLocal().hour;
        if (hour >= 0 && hour < 24) {
          sums[hour] += getValue(item);
          counts[hour]++;
        }
      }
    }
    final raw = List<double>.generate(24, (i) =>
        counts[i] == 0 ? -1.0 : sums[i] / counts[i]);
    return _interpolate(_filterSpike(raw));
  }

  // ============================================================
  // WEEKLY
  // ============================================================
  static List<double> toWeekly<T>({
    required List<T> data,
    required DateTime Function(T) getTime,
    required double Function(T) getValue,
  }) {
    final now = DateTime.now();
    final sums = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    for (final item in data) {
      final time = getTime(item).toLocal();
      if (!time.isBefore(startOfWeek)) {
        final index = time.weekday - 1;
        if (index >= 0 && index < 7) {
          sums[index] += getValue(item);
          counts[index]++;
        }
      }
    }
    final raw = List<double>.generate(7, (i) =>
        counts[i] == 0 ? -1.0 : sums[i] / counts[i]);
    return _interpolate(_filterSpike(raw));
  }

  // ============================================================
  // MONTHLY
  // ============================================================
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
      final time = getTime(item).toLocal();
      if (time.month == now.month && time.year == now.year) {
        final index = time.day - 1;
        if (index >= 0 && index < daysInMonth) {
          sums[index] += getValue(item);
          counts[index]++;
        }
      }
    }
    final raw = List<double>.generate(daysInMonth, (i) =>
        counts[i] == 0 ? -1.0 : sums[i] / counts[i]);
    return _interpolate(_filterSpike(raw));
  }

  // ============================================================
  // SPECIFIC DATE (24 JAM)
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
        final hour = time.toLocal().hour;
        if (hour >= 0 && hour < 24) {
          sums[hour] += getValue(item);
          counts[hour]++;
        }
      }
    }
    final raw = List<double>.generate(24, (i) =>
        counts[i] == 0 ? -1.0 : sums[i] / counts[i]);
    return _interpolate(_filterSpike(raw));
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
    final end   = DateTime(endDate.year,   endDate.month,   endDate.day);

    // Buat list semua hari dalam rentang
    final days = <DateTime>[];
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      days.add(cur);
      cur = cur.add(const Duration(days: 1));
    }

    if (days.isEmpty) return (values: [], labels: []);

    final sums   = List<double>.filled(days.length, 0.0);
    final counts = List<int>.filled(days.length, 0);

    for (final item in data) {
      final time    = getTime(item).toLocal();
      final dayOnly = DateTime(time.year, time.month, time.day);
      for (int i = 0; i < days.length; i++) {
        if (dayOnly == days[i]) {
          sums[i] += getValue(item);
          counts[i]++;
          break;
        }
      }
    }

    final raw = List<double>.generate(days.length, (i) =>
        counts[i] == 0 ? -1.0 : sums[i] / counts[i]);

    final values = _interpolate(_filterSpike(raw));

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
    const b = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return b[m];
  }

  // ============================================================
  // HELPER
  // ============================================================
  static bool _isSameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static List<double> smooth(List<double> data) {
    if (data.length < 3) return data;
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      if (i == 0 || i == data.length - 1) {
        result.add(data[i]);
      } else {
        result.add((data[i - 1] + data[i] + data[i + 1]) / 3);
      }
    }
    return result;
  }
}