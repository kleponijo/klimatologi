// ===========================================================
//  wind_speed_history_list.dart
//  Lokasi: lib/screens/monitoring/wind_speed/views/widgets/
// ===========================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monitoring_repository/monitoring_repository.dart';

class WindSpeedHistoryList extends StatelessWidget {
  final List<MyWindSpeed> history;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onDeleteTap;
  final bool isDeleting;

  const WindSpeedHistoryList({
    super.key,
    required this.history,
    required this.selectedDate,
    required this.onPickDate,
    required this.onClearDate,
    required this.onDeleteTap,
    this.isDeleting = false,
  });

  // ── Grouping per tanggal ─────────────────────────────────────
  Map<String, List<MyWindSpeed>> _groupByDate(List<MyWindSpeed> list) {
    final map = <String, List<MyWindSpeed>>{};
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
        // ── Header bar ──────────────────────────────────────────
        _HeaderBar(
          selectedDate: selectedDate,
          totalCount: history.length,
          onPickDate: onPickDate,
          onClearDate: onClearDate,
          onDeleteTap: onDeleteTap, // ← baru
          isDeleting: isDeleting,
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

              return _DateGroup(
                label: label,
                items: items,
              );
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
//  Header dengan date picker & counter
// ════════════════════════════════════════════════════════════
class _HeaderBar extends StatelessWidget {
  final DateTime? selectedDate;
  final int totalCount;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onDeleteTap;
  final bool isDeleting;

  const _HeaderBar({
    required this.selectedDate,
    required this.totalCount,
    required this.onPickDate,
    required this.onClearDate,
    required this.onDeleteTap,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedDate != null;

    return Row(
      children: [
        // Judul + badge jumlah
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

        // Tombol filter tanggal
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
        const SizedBox(width: 4),

        // ── DELETE BUTTON ← baru ──────────────────────────────
        isDeleting
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Colors.redAccent),
                tooltip: 'Hapus riwayat',
                onPressed: totalCount == 0 ? null : onDeleteTap,
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
class _DateGroup extends StatefulWidget {
  final String label;
  final List<MyWindSpeed> items;

  const _DateGroup({required this.label, required this.items});

  @override
  State<_DateGroup> createState() => _DateGroupState();
}

class _DateGroupState extends State<_DateGroup> {
  bool _expanded = true; // default terbuka

  double get _avgSpeed {
    if (widget.items.isEmpty) return 0;
    return widget.items.map((e) => e.speed).reduce((a, b) => a + b) /
        widget.items.length;
  }

  double get _maxSpeed {
    if (widget.items.isEmpty) return 0;
    return widget.items.map((e) => e.speed).reduce((a, b) => a > b ? a : b);
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
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // ── Group header ──────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                        Text(widget.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.items.length} data  •  rata-rata ${_avgSpeed.toStringAsFixed(2)} m/s  •  maks ${_maxSpeed.toStringAsFixed(2)} m/s',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),

          // ── Item list ─────────────────────────────────────
          if (_expanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) =>
                  _HistoryItemTile(item: widget.items[i]),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Satu baris data history
// ════════════════════════════════════════════════════════════
class _HistoryItemTile extends StatelessWidget {
  final MyWindSpeed item;

  const _HistoryItemTile({required this.item});

  String get _alertLevel {
    if (item.speed >= 12.5) return 'Bahaya';
    if (item.speed >= 8.0) return 'Waspada';
    return 'Normal';
  }

  Color get _alertColor {
    switch (_alertLevel) {
      case 'Bahaya':
        return Colors.red.shade600;
      case 'Waspada':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  IconData get _alertIcon {
    switch (_alertLevel) {
      case 'Bahaya':
        return Icons.warning_rounded;
      case 'Waspada':
        return Icons.info_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kmh = item.speed * 3.6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Jam
          SizedBox(
            width: 52,
            child: Text(
              DateFormat('HH:mm:ss').format(item.timestamp),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace'),
            ),
          ),

          // Speed m/s
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: item.speed.toStringAsFixed(3),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: ' m/s',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${kmh.toStringAsFixed(2)} km/h',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Badge status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _alertColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _alertColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_alertIcon, size: 12, color: _alertColor),
                const SizedBox(width: 4),
                Text(
                  _alertLevel,
                  style: TextStyle(
                      fontSize: 11,
                      color: _alertColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
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
