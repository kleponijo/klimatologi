part of 'evaporasi_settings_bloc.dart';

enum EvaporasiSettingsStatus { loading, loaded, saving, saved, error }

class EvaporasiSettingsState extends Equatable {
  final double thresholdRendah;
  final double thresholdTinggi;
  final String rumusKalibrasi;
  final double koreksiOffset;
  final int dmax;
  final bool isResettingDmax;

  // Interval (milidetik) — dikirim ke ESP32 via RTDB
  final int intervalRealtime_ms;   // default 300000 = 5 menit
  final int intervalHistory_ms;    // default 600000 = 10 menit
  final int intervalBaca_ms;       // default 10000  = 10 detik

  final EvaporasiSettingsStatus status;
  final String? errorMessage;

  const EvaporasiSettingsState({
    this.thresholdRendah     = 2.0,
    this.thresholdTinggi     = 10.0,
    this.rumusKalibrasi      = 'selisih_max',
    this.koreksiOffset       = 0.0,
    this.intervalRealtime_ms = 300000,
    this.intervalHistory_ms  = 600000,
    this.intervalBaca_ms     = 10000,
    this.status              = EvaporasiSettingsStatus.loading,
    this.errorMessage,
    this.dmax = 0, 
    this.isResettingDmax = false,
  });

  EvaporasiSettingsState copyWith({
    double? thresholdRendah,
    double? thresholdTinggi,
    String? rumusKalibrasi,
    double? koreksiOffset,
    int?    intervalRealtime_ms,
    int?    intervalHistory_ms,
    int?    intervalBaca_ms,
    EvaporasiSettingsStatus? status,
    String? errorMessage,
    int? dmax,
    bool? isResettingDmax,
  }) {
    return EvaporasiSettingsState(
      thresholdRendah:     thresholdRendah     ?? this.thresholdRendah,
      thresholdTinggi:     thresholdTinggi     ?? this.thresholdTinggi,
      rumusKalibrasi:      rumusKalibrasi      ?? this.rumusKalibrasi,
      koreksiOffset:       koreksiOffset       ?? this.koreksiOffset,
      intervalRealtime_ms: intervalRealtime_ms ?? this.intervalRealtime_ms,
      intervalHistory_ms:  intervalHistory_ms  ?? this.intervalHistory_ms,
      intervalBaca_ms:     intervalBaca_ms     ?? this.intervalBaca_ms,
      status:              status              ?? this.status,
      errorMessage:        errorMessage        ?? this.errorMessage,
      dmax:                dmax                ?? this.dmax,
      isResettingDmax:     isResettingDmax     ?? this.isResettingDmax,
    );
  }

  @override
  List<Object?> get props => [
        thresholdRendah, thresholdTinggi, rumusKalibrasi, koreksiOffset,
        intervalRealtime_ms, intervalHistory_ms, intervalBaca_ms,
        status, errorMessage,
        dmax, isResettingDmax,
      ];
}