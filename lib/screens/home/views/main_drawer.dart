import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/authentication_bloc/authentication_bloc.dart';

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
            leading: const Icon(Icons.speed),
            title: const Text("Wind Speed"),
            onTap: () {
              // Navigasi ke Wind Speed
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text("Evaporasi"),
            onTap: () {},
          ),
          ListTile(
            leading: Image.asset(
              'images/atmosfer.png',
              height: 20,
              width: 20,
            ),
            title: const Text("Udara"),
            onTap: () {},
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
