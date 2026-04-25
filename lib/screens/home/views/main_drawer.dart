import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimatologiot/screens/monitoring/evaporasi/blocs/evaporasi_bloc.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import '../../../blocs/authentication_bloc/authentication_bloc.dart';
import '../../monitoring/wind_speed/views/wind_speed_screen.dart';
import '../../monitoring/wind_speed/blocs/wind_speed_bloc.dart';
import '../../monitoring/evaporasi/views/evaporasi_screen.dart';
import '../../monitoring/atmospheric_conditions/blocs/atmospheric_conditions_bloc.dart';
import '../../monitoring/atmospheric_conditions/views/atmospheric_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Bagian Header (Tempat Nama/Email)
          BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              // Mengambil email user dari Bloc Global
              String userEmail = state.user?.email ?? "Guest";
              String userName =
                  userEmail.split('@')[0]; // Ambil depan email saja

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(userEmail),
              );
            },
          ),

          // Daftar Menu
          ListTile(
            leading: Image.asset(
              'images/windy.png',
              height: 20,
              width: 20,
            ),
            title: const Text("Wind Speed"),
            onTap: () {
              // Navigasi ke Wind Speed
              // 1. Tutup Drawer dulu supaya tidak menghalangi transisi
              Navigator.pop(context);

              // 2. Pindah ke halaman WindSpeedScreen sambil membawa Bloc
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider<WindSpeedBloc>(
                    create: (context) => WindSpeedBloc(
                      // AMBIL MonitoringRepository
                      repository: context.read<MonitoringRepository>(),
                    )..add(
                        WatchWindSpeedStarted()), // Langsung mulai monitoring
                    child: const WindSpeedScreen(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text("Evaporasi"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider<EvaporasiBloc>(
                    create: (context) => EvaporasiBloc(
                      repository: context.read<MonitoringRepository>(),
                    )..add(WatchEvaporasiStarted()),
                    child: const EvaporasiScreen(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'images/atmosfer.png',
              height: 20,
              width: 20,
            ),
            title: const Text("Kondisi Atmosfer"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider<AtmosphericConditionsBloc>(
                    create: (context) => AtmosphericConditionsBloc(
                      repository: context.read<MonitoringRepository>(),
                    )..add(WatchAtmosphericConditionsStarted()),
                    child: AtmosphericScreen(),
                  ),
                ),
              );
            },
          ),
          const Spacer(), // Dorong menu logout ke paling bawah
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              context
                  .read<AuthenticationBloc>()
                  .add(AuthenticationLogoutRequested());
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
