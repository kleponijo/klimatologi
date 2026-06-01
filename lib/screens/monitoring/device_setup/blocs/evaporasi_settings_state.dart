part of 'evaporasi_settings_bloc.dart';

enum EvaporasiSettingsStatus { loading, loaded, saving, saved, error }

class EvaporasiSettingsState extends Equatable {
  final double thresholdRendah;
  final double thresholdTinggi;
  final String rumusKalibrasi;
  final double koreksiOffset;
  final String pumpStartTime;
  final String pumpEndTime;
  final int d0;
  final int dmaxManual;
  final int dmax;
  final bool isResettingDmax;
  final String firmwareVersion;
  final bool wifiConnected;
  final bool firebaseConnected;
  final int activeD0;
  final int activeDmax;
  final DateTime? lastUpdate;

  // Interval (milidetik) — dikirim ke ESP32 via RTDB
  final int intervalRealtime_ms;   // default 300000 = 5 menit
  final int intervalHistory_ms;    // default 600000 = 10 menit
  final int intervalBaca_ms;       // default 10000  = 10 detik

  final double standarTinggiCm;
  final double batasKritisCm;
  final bool tempCompActive;
  final double tempCompCoef;
  final double tempRefC;
  final bool sensorError;
  final bool ntpSync;
  final double snapshotCm;
  final bool otaTrigger;
  final bool relayAktif;
  final String otaStatus;
  final int historyCount;
  final DateTime? lastRealtime;

  final EvaporasiSettingsStatus status;
  final String? errorMessage;

  const EvaporasiSettingsState({
    this.thresholdRendah     = 2.0,
    this.thresholdTinggi     = 10.0,
    this.rumusKalibrasi      = 'selisih_max',
    this.koreksiOffset       = 0.0,
    this.pumpStartTime       = '06:00',
    this.pumpEndTime         = '18:00',
    this.d0                 = 0,
    this.dmaxManual         = 0,
    this.intervalRealtime_ms = 300000,
    this.intervalHistory_ms  = 600000,
    this.intervalBaca_ms     = 10000,
    this.standarTinggiCm     = 18.0,
    this.batasKritisCm       = 15.0,
    this.tempCompActive      = true,
    this.tempCompCoef        = 500.0,
    this.tempRefC            = 25.0,
    this.sensorError         = false,
    this.ntpSync             = false,
    this.snapshotCm          = 0.0,
    this.otaTrigger          = false,
    this.relayAktif          = false,
    this.otaStatus           = '--',
    this.historyCount        = 0,
    this.lastRealtime,
    this.status              = EvaporasiSettingsStatus.loading,
    this.errorMessage,
    this.dmax = 0,
    this.isResettingDmax = false,
    this.firmwareVersion = '--',
    this.wifiConnected = false,
    this.firebaseConnected = false,
    this.activeD0 = 0,
    this.activeDmax = 0,
    this.lastUpdate,
  });

  EvaporasiSettingsState copyWith({
    double? thresholdRendah,
    double? thresholdTinggi,
    String? rumusKalibrasi,
    double? koreksiOffset,
    String? pumpStartTime,
    String? pumpEndTime,
    int? d0,
    int? dmaxManual,
    int?    intervalRealtime_ms,
    int?    intervalHistory_ms,
    int?    intervalBaca_ms,
    double? standarTinggiCm,
    double? batasKritisCm,
    bool? tempCompActive,
    double? tempCompCoef,
    double? tempRefC,
    bool? sensorError,
    bool? ntpSync,
    double? snapshotCm,
    bool? otaTrigger,
    bool? relayAktif,
    String? otaStatus,
    int? historyCount,
    DateTime? lastRealtime,
    EvaporasiSettingsStatus? status,
    String? errorMessage,
    int? dmax,
    bool? isResettingDmax,
    String? firmwareVersion,
    bool? wifiConnected,
    bool? firebaseConnected,
    int? activeD0,
    int? activeDmax,
    DateTime? lastUpdate,
  }) {
    return EvaporasiSettingsState(
      thresholdRendah:     thresholdRendah     ?? this.thresholdRendah,
      thresholdTinggi:     thresholdTinggi     ?? this.thresholdTinggi,
      rumusKalibrasi:      rumusKalibrasi      ?? this.rumusKalibrasi,
      koreksiOffset:       koreksiOffset       ?? this.koreksiOffset,
      pumpStartTime:       pumpStartTime       ?? this.pumpStartTime,
      pumpEndTime:         pumpEndTime         ?? this.pumpEndTime,
      d0:                  d0                  ?? this.d0,
      dmaxManual:          dmaxManual          ?? this.dmaxManual,
      standarTinggiCm:     standarTinggiCm     ?? this.standarTinggiCm,
      batasKritisCm:       batasKritisCm       ?? this.batasKritisCm,
      tempCompActive:      tempCompActive      ?? this.tempCompActive,
      tempCompCoef:        tempCompCoef        ?? this.tempCompCoef,
      tempRefC:            tempRefC            ?? this.tempRefC,
      sensorError:         sensorError         ?? this.sensorError,
      ntpSync:             ntpSync             ?? this.ntpSync,
      snapshotCm:          snapshotCm          ?? this.snapshotCm,
      otaTrigger:          otaTrigger          ?? this.otaTrigger,
      relayAktif:          relayAktif          ?? this.relayAktif,
      otaStatus:           otaStatus           ?? this.otaStatus,
      historyCount:        historyCount        ?? this.historyCount,
      lastRealtime:        lastRealtime        ?? this.lastRealtime,
      firmwareVersion:     firmwareVersion     ?? this.firmwareVersion,
      wifiConnected:       wifiConnected       ?? this.wifiConnected,
      firebaseConnected:   firebaseConnected   ?? this.firebaseConnected,
      activeD0:            activeD0            ?? this.activeD0,
      activeDmax:          activeDmax          ?? this.activeDmax,
      lastUpdate:          lastUpdate          ?? this.lastUpdate,
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
        pumpStartTime, pumpEndTime, d0, dmaxManual,
        intervalRealtime_ms, intervalHistory_ms, intervalBaca_ms,
        standarTinggiCm, batasKritisCm, tempCompActive, tempCompCoef, tempRefC,
        sensorError, ntpSync, snapshotCm, otaTrigger, relayAktif, historyCount, lastRealtime,
        firmwareVersion, wifiConnected, firebaseConnected, activeD0, activeDmax, lastUpdate,
        status, errorMessage,
        dmax, isResettingDmax,
      ];
}