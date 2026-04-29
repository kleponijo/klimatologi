import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimatologiot/screens/monitoring/evaporasi/blocs/evaporasi_bloc.dart';
import 'package:klimatologiot/screens/monitoring/wind_speed/blocs/wind_speed_bloc.dart';
import 'package:klimatologiot/screens/monitoring/atmospheric_conditions/blocs/atmospheric_conditions_bloc.dart';
import 'package:klimatologiot/screens/monitoring/evaporasi/views/widgets/evaporasi_chart_widget.dart';
import 'package:klimatologiot/screens/monitoring/wind_speed/views/widgets/wind_speed_chart_widget.dart';
import 'package:klimatologiot/screens/monitoring/atmospheric_conditions/views/widgets/atmospheric_chart_widget.dart';

class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            /// TOP: 3 Live Value Cards
            _buildTopMetricsRow(context),
            const SizedBox(height: 30),

            /// GRAPHS SECTION
            const Text(
              "Live Streaming Graphs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            /// 1. Evaporasi Graph
            const Text("Evaporasi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            BlocBuilder<EvaporasiBloc, EvaporasiState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return Container(height: 220, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)));
                }
                return EvaporasiChartWidget(
                  dailyValues: state.dailyValues,
                  dailyTemperatures: state.dailyTemperatures,
                  period: "Hari Ini",
                );
              },
            ),
            const SizedBox(height: 25),

            /// 2. Wind Speed Graph
            const Text("Wind Speed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            BlocBuilder<WindSpeedBloc, WindSpeedState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return Container(height: 220, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)));
                }
                return WindSpeedChartWidget(
                  dailySpeeds: state.dailySpeeds,
                  period: "Hari Ini",
                );
              },
            ),
            const SizedBox(height: 25),

            /// 3. Atmospheric Graph
            const Text("Atmosfer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            BlocBuilder<AtmosphericConditionsBloc, AtmosphericConditionsState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return Container(height: 220, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)));
                }
                return AtmosphericChartWidget(
                  dailyTemperatures: state.dailyTemperatures,
                  period: "Hari Ini",
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      );
  }

  Widget _buildTopMetricsRow(BuildContext context) {
    return Row(
      children: [
        /// Evaporasi Card
        Expanded(
          child: BlocBuilder<EvaporasiBloc, EvaporasiState>(
            builder: (context, state) {
              return _metricCard(
                title: "Evaporasi",
                value: state.currentValue.toStringAsFixed(1),
                unit: "mm",
                icon: Icons.water_drop,
                color: Colors.blue,
                isLoading: state.isLoading,
              );
            },
          ),
        ),
        const SizedBox(width: 15),

        /// Wind Speed Card
        Expanded(
          child: BlocBuilder<WindSpeedBloc, WindSpeedState>(
            builder: (context, state) {
              return _metricCard(
                title: "Angin",
                value: state.currentSpeed.toStringAsFixed(1),
                unit: "m/s",
                icon: Icons.air,
                color: Colors.indigo,
                isLoading: state.isLoading,
              );
            },
          ),
        ),

        /// Temp Card
        Expanded(
          child: BlocBuilder<AtmosphericConditionsBloc, AtmosphericConditionsState>(
            builder: (context, state) {
              return _metricCard(
                title: "Suhu",
                value: state.temperature.toStringAsFixed(1),
                unit: "°C",
                icon: Icons.thermostat,
                color: Colors.orange,
                isLoading: state.isLoading,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: isLoading 
        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
    );
  }
}

