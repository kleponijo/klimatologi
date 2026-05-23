import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash/views/splash_screen.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klimatologi',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.light(
            surface: Colors.grey.shade100,
            onSurface: Colors.black,
            primary: Colors.blue,
            onPrimary: Colors.white),
      ),
      home: const SplashScreen(),
    );
  }
}
