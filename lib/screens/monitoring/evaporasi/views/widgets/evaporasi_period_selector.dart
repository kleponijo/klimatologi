import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/evaporasi_bloc.dart';
import 'evaporasi_date_picker.dart';

class EvaporasiPeriodSelector extends StatelessWidget {
  const EvaporasiPeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select((EvaporasiBloc bloc) => bloc.state);
    final selectedPeriod = state.selectedPeriod;
    final viewMode = state.viewMode;
    final selectedDate = state.selectedDate;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(context, "Hari Ini", selectedPeriod, viewMode),
          _buildTab(context, "Minggu Ini", selectedPeriod, viewMode),
          _buildTab(context, "Bulan Ini", selectedPeriod, viewMode),
          const SizedBox(width: 8),
          // Date picker button
          _buildDatePickerButton(context, viewMode, selectedDate),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, String current, EvaporasiViewMode viewMode) {
    // If in customDate mode, show period tabs as inactive
    bool isActive = viewMode == EvaporasiViewMode.period && label == current;

    return GestureDetector(
      onTap: () {
        context.read<EvaporasiBloc>().add(EvaporasiPeriodChanged(label));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

Widget _buildDatePickerButton(BuildContext context, EvaporasiViewMode viewMode, DateTime? selectedDate) {
    final isActive = viewMode == EvaporasiViewMode.customDate;

    return GestureDetector(
      onTap: () {
        // Set mode ke customDate SEBELUM membuka date picker
        context.read<EvaporasiBloc>().add(
              const EvaporasiViewModeChanged(EvaporasiViewMode.customDate),
            );

        // Penting: pastikan bottom sheet masih punya context yang memiliki EvaporasiBloc
        final bloc = context.read<EvaporasiBloc>();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return BlocProvider.value(
              value: bloc,
              child: const EvaporasiDatePicker(),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              isActive && selectedDate != null
                  ? _formatDateShort(selectedDate)
                  : "Pilih Tanggal",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return "${date.day}/${date.month}";
  }
}

