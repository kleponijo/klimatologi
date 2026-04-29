import 'package:flutter/foundation.dart';

/// Global notifier untuk peringatan cuaca di dashboard
/// Di-update dari EvaporasiBloc, di-listen di HomeScreen
final ValueNotifier<bool> hasWeatherAlert = ValueNotifier<bool>(false);

/// Pesan peringatan yang akan ditampilkan
final ValueNotifier<String> weatherAlertMessage = ValueNotifier<String>('');

