import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/authentication_bloc/authentication_bloc.dart';
import 'main_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5, // Kasih sedikit bayangan tipis agar elegan
        centerTitle: false,
        leading: Builder(
            builder: (context) => IconButton(
                  icon: const Icon(Icons.menu,
                      color: Colors.black), // Ikon garis 3 horizontal
                  onPressed: () {
                    // ini kodenya untuk membuka:
                    Scaffold.of(context).openDrawer();
                  },
                )),
        title: Row(
          children: [
            // Ganti dengan Image.asset jika sudah ada logo
            Image.asset(
              'images/logo_klimatologi.png',
              height: 90,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // Aksi notifikasi
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              // Trigger Logout di AuthenticationBloc kamu
              context
                  .read<AuthenticationBloc>()
                  .add(AuthenticationLogoutRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const Center(
        child: Text("body home page"),
      ),
    );
  }
}
