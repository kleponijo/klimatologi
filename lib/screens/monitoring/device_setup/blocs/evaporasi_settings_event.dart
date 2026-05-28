part of 'evaporasi_settings_bloc.dart';

abstract class EvaporasiSettingsEvent extends Equatable {
  const EvaporasiSettingsEvent();
  @override
  List<Object?> get props => [];
}

class EvaporasiSettingsStarted extends EvaporasiSettingsEvent {}

class EvaporasiThresholdRendahChanged extends EvaporasiSettingsEvent {
  final double value;
  const EvaporasiThresholdRendahChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiThresholdTinggiChanged extends EvaporasiSettingsEvent {
  final double value;
  const EvaporasiThresholdTinggiChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiRumusKalibrasiChanged extends EvaporasiSettingsEvent {
  final String rumus;
  const EvaporasiRumusKalibrasiChanged(this.rumus);
  @override List<Object?> get props => [rumus];
}

class EvaporasiKoreksiOffsetChanged extends EvaporasiSettingsEvent {
  final double value;
  const EvaporasiKoreksiOffsetChanged(this.value);
  @override List<Object?> get props => [value];
}

// ── Interval baru ──────────────────────────────────────────
class EvaporasiIntervalRealtimeChanged extends EvaporasiSettingsEvent {
  final int value; // ms
  const EvaporasiIntervalRealtimeChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiIntervalHistoryChanged extends EvaporasiSettingsEvent {
  final int value; // ms
  const EvaporasiIntervalHistoryChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiIntervalBacaChanged extends EvaporasiSettingsEvent {
  final int value; // ms
  const EvaporasiIntervalBacaChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiSettingsSaved extends EvaporasiSettingsEvent {}

class EvaporasiDmaxResetRequested extends EvaporasiSettingsEvent {}