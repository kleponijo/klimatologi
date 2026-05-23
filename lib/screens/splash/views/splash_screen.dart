import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimatologiot/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:klimatologiot/screens/auth/views/welcome_screen.dart';
import 'package:klimatologiot/screens/home/views/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Tunggu minimal 3 detik (efek splash)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final bloc = context.read<AuthenticationBloc>();

    // Kalau auth state masih unknown (Firebase belum resolve), tunggu dulu
    AuthenticationState state = bloc.state;
    if (state.status == AuthenticationStatus.unknown) {
      state = await bloc.stream
          .firstWhere((s) => s.status != AuthenticationStatus.unknown)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => const AuthenticationState.unauthenticated(),
          );
    }
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => state.status == AuthenticationStatus.authenticated
            ? HomeScreen()
            : WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/logo_klimatologi.png',
              width: 140,
            ),
            const SizedBox(height: 24),
            const Text(
              'Klimatologi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
