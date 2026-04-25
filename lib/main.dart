import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimatologiot/simple_bloc_observer.dart';
import 'package:klimatologiot/app.dart';
import 'package:user_repository/user_repository.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
  Bloc.observer = SimpleBlocObserver();
  runApp(MyApp(
    FirebaseUserRepo(),
    FirebaseMonitoringRepo(),
  ));
}
