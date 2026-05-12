import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

import '../blocs/sign_in_bloc/sign_in_bloc.dart';
import '../blocs/sign_up_bloc/sign_up_bloc.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose(); // FIX: dispose controller agar tidak memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: TabBar(
                controller: tabController,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                labelColor: Theme.of(context).colorScheme.onSurface,
                tabs: const [
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Sign In', style: TextStyle(fontSize: 18)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Sign Up', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
            // FIX: Expanded supaya TabBarView mengisi sisa tinggi layar
            // dengan ini scroll di dalam tab bisa berjalan normal
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  BlocProvider<SignInBloc>(
                    create: (context) =>
                        // FIX: akses UserRepository langsung, bukan via AuthBloc
                        SignInBloc(context.read<UserRepository>()),
                    child: const SignInScreen(),
                  ),
                  BlocProvider<SignUpBloc>(
                    create: (context) =>
                        SignUpBloc(context.read<UserRepository>()),
                    child: SignUpScreen(
                      onSignInTap: () => tabController.animateTo(0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
