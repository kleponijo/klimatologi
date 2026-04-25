/// === Tombol Filter Jam/Hari/Minggu === ///
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/wind_speed_bloc.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Kita ambil state saat ini untuk tahu periode mana yang aktif
    final selectedPeriod =
        context.select((WindSpeedBloc bloc) => bloc.state.selectedPeriod);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(context, "Hari Ini", selectedPeriod),
          _buildTab(context, "Minggu Ini", selectedPeriod),
          _buildTab(context, "Bulan Ini", selectedPeriod),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, String current) {
    bool isActive = label == current;

    return GestureDetector(
      onTap: () {
        // Kirim event ke Bloc saat tombol diklik
        context.read<WindSpeedBloc>().add(WindSpeedPeriodChanged(label));
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
}
