// ===========================================================
//  evaporasi_history_list.dart
//  Lokasi: lib/screens/monitoring/evaporasi/views/widgets/
// ===========================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

class EvaporasiHistoryList extends StatelessWidget {
  final List<Evaporasi> history;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const EvaporasiHistoryList({
    super.key,
    required this.history,
    required this.selectedDate,
    required this.onPickDate,
    required this.onClearDate,
  });

  Map<String, List<Evaporasi>> _groupByDate(List<Evaporasi> list) {
    final map = <String, List<Evaporasi>>{};
    for (final item in list) {
      final key = DateFormat('yyyy-MM-dd').format(item.timestamp);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(history);
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // terbaru di atas

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderBar(
          selectedDate: selectedDate,
          totalCount: history.length,
          onPickDate: onPickDate,
          onClearDate: onClearDate,
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          _EmptyState(hasFilter: selectedDate != null)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedKeys.length,
            itemBuilder: (context, idx) {
              final dateKey = sortedKeys[idx];
              final items = grouped[dateKey]!
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
              final label = _formatDateLabel(dateKey);
              return _DateGroup(label: label, items: items);
            },
          ),
      ],
    );
  }

  String _formatDateLabel(String key) {
    final dt = DateTime.parse(key);
    final today = DateTime.now();
    if (dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day) {
      return 'Hari Ini — ${DateFormat('dd MMMM yyyy', 'id_ID').format(dt)}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Kemarin — ${DateFormat('dd MMMM yyyy', 'id_ID').format(dt)}';
    }
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dt);
  }
}

// ════════════════════════════════════════════════════════════
//  Header bar
// ════════════════════════════════════════════════════════════
class _HeaderBar extends StatelessWidget {
  final DateTime? selectedDate;
  final int totalCount;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const _HeaderBar({
    required this.selectedDate,
    required this.totalCount,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedDate != null;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Data',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            Text(
              filtered
                  ? '${DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate!)} • $totalCount data'
                  : '$totalCount data tersimpan',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const Spacer(),
        if (filtered)
          _ChipButton(
            label: DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate!),
            icon: Icons.close_rounded,
            color: Colors.blue.shade700,
            onTap: onClearDate,
          )
        else
          _ChipButton(
            label: 'Filter Tanggal',
            icon: Icons.calendar_month_rounded,
            color: Colors.blue.shade700,
            onTap: onPickDate,
          ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Group per tanggal
// ════════════════════════════════════════════════════════════
class _DateGroup extends StatelessWidget {
  final String label;
  final List<Evaporasi> items;

  const _DateGroup({required this.label, required this.items});

  double get _avgEvap {
    if (items.isEmpty) return 0;
    return items.map((e) => e.evaporasi).reduce((a, b) => a + b) / items.length;
  }

  double get _maxEvap {
    if (items.isEmpty) return 0;
    return items.map((e) => e.evaporasi).reduce((a, b) => a > b ? a : b);
  }

  double get _avgTemp {
    if (items.isEmpty) return 0;
    final validTemps =
        items.where((e) => e.suhu >= -50 && e.suhu <= 100).toList();
    if (validTemps.isEmpty) return 0;
    return validTemps.map((e) => e.suhu).reduce((a, b) => a + b) /
        validTemps.length;
  }

  double get _maxTemp {
    if (items.isEmpty) return 0;
    return items.map((e) => e.suhu).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'rata-rata ${_avgEvap.toStringAsFixed(2)} mm',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'rata-rata suhu ${_avgTemp.toStringAsFixed(1)} °C',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Empty state
// ════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            hasFilter ? Icons.search_off_rounded : Icons.inbox_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'Tidak ada data untuk tanggal ini'
                : 'Belum ada data history',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
