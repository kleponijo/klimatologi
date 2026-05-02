import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/evaporasi_bloc.dart';

class EvaporasiPeriodSelector extends StatelessWidget {
  const EvaporasiPeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedPeriod =
        context.select((EvaporasiBloc bloc) => bloc.state.selectedPeriod);

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
}

