import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../monitoring/wind_speed/blocs/wind_speed_bloc.dart';
import '../../monitoring/atmospheric_conditions/blocs/atmospheric_conditions_bloc.dart';

class SensorGrid extends StatelessWidget {
  const SensorGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lebar card: 2 kolom dengan gap 12
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // --- ANEMOMETER ---
            BlocBuilder<WindSpeedBloc, WindSpeedState>(
              builder: (context, state) => SensorCard(
                width: cardWidth,
                icon: Icons.air,
                iconColor: Colors.blue.shade600,
                iconBgColor: Colors.blue.shade50,
                label: 'Kecepatan Angin',
                value: state.isLoading
                    ? '—'
                    : state.currentSpeed.toStringAsFixed(1),
                unit: 'm/s',
                isLoading: state.isLoading,
              ),
            ),

<<<<<<< Updated upstream
            // --- EVAPORASI ---
            BlocBuilder<EvaporasiBloc, EvaporasiState>(
              builder: (context, state) => SensorCard(
                width: cardWidth,
                icon: Icons.water_drop_outlined,
                iconColor: Colors.teal.shade600,
                iconBgColor: Colors.teal.shade50,
                label: 'Evaporasi',
                value: state.isLoading
                    ? '—'
                    : state.currentValue.toStringAsFixed(1),
                unit: 'mm',
                isLoading: state.isLoading,
              ),
            ),

=======
>>>>>>> Stashed changes
            // --- TEKANAN UDARA ---
            BlocBuilder<AtmosphericConditionsBloc, AtmosphericConditionsState>(
              builder: (context, state) => SensorCard(
                width: cardWidth,
                icon: Icons.compress,
                iconColor: Colors.purple.shade400,
                iconBgColor: Colors.purple.shade50,
                label: 'Tekanan Udara',
                value:
                    state.isLoading ? '—' : state.pressure.toStringAsFixed(1),
                unit: 'hPa',
                isLoading: state.isLoading,
              ),
            ),
          ],
        );
      },
    );
  }
}

class SensorCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;
  final String unit;
  final bool isLoading;

  const SensorCard({
    super.key,
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.unit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            // Nilai + satuan
            isLoading
                ? Container(
                    height: 24,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
<<<<<<< Updated upstream
=======
            if (status != null && !isLoading) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (status == 'Tinggi'
                          ? Colors.red.shade50
                          : (status == 'Rendah'
                              ? Colors.blue.shade50
                              : Colors.green.shade50)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: (status == 'Tinggi'
                            ? Colors.red.shade600
                            : (status == 'Rendah'
                                ? Colors.blue.shade600
                                : Colors.green.shade600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
>>>>>>> Stashed changes
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
