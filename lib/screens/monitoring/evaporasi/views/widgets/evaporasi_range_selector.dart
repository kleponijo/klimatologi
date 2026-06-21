// lib/screens/monitoring/evaporasi/views/widgets/evaporasi_range_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/evaporasi_bloc.dart';

class EvaporasiRangeSelector extends StatelessWidget {
  const EvaporasiRangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EvaporasiBloc>().state;
    final start = state.startDate;
    final end   = state.endDate;
    final isSingle = state.isSingleDay;

    final label = isSingle
        ? _formatSingle(start)
        : '${_fmt(start)}  →  ${_fmt(end)}';

    return GestureDetector(
      onTap: () => _pickDate(context, start),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Label rentang ──────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSingle ? 'Tampil per Jam' : 'Tampil per Hari',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // ── Tombol pilih ───────────────────────────────
            Row(
              children: [
                // Shortcut: Hari Ini
                _ShortcutChip(
                  label: 'Hari Ini',
                  isActive: isSingle && _isToday(start),
                  onTap: () {
                    final today = DateTime.now();
                    context.read<EvaporasiBloc>().add(
                          EvaporasiDateRangeChanged(
                            startDate: DateTime(today.year, today.month, today.day),
                            endDate: DateTime(today.year, today.month, today.day),
                          ),
                        );
                  },
                ),
                const SizedBox(width: 6),
                // Tombol pilih tanggal harian
                GestureDetector(
                  onTap: () => _pickDate(context, start),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Pilih Tanggal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
      BuildContext context, DateTime date) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final selected = DateTime(picked.year, picked.month, picked.day);
      context.read<EvaporasiBloc>().add(
            EvaporasiDateRangeChanged(
              startDate: selected,
              endDate: selected,
            ),
          );
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _fmt(DateTime d) => DateFormat('dd MMM yyyy', 'id_ID').format(d);

  String _formatSingle(DateTime d) {
    if (_isToday(d)) return 'Hari Ini — ${_fmt(d)}';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Kemarin — ${_fmt(d)}';
    }
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(d);
  }
}

class _ShortcutChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ShortcutChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.blue.shade400
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}