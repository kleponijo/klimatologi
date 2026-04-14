import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimatologiot/app_view.dart';
import 'package:user_repository/user_repository.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import 'blocs/authentication_bloc/authentication_bloc.dart';

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final MonitoringRepository monitoringRepository;
  const MyApp(this.userRepository, this.monitoringRepository, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
        providers: [
          // 1. Daftarkan UserRepository
          RepositoryProvider<UserRepository>.value(value: userRepository),
          RepositoryProvider<MonitoringRepository>.value(
              value: monitoringRepository),
        ],
        child: BlocProvider<AuthenticationBloc>(
          create: (context) => AuthenticationBloc(
            userRepository: userRepository,
          ),
          child: const MyAppView(),
        ));
  }
}
