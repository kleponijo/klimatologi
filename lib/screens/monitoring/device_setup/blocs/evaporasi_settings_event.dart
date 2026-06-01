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

class EvaporasiPumpStartChanged extends EvaporasiSettingsEvent {
  final String value; // HH:mm
  const EvaporasiPumpStartChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiPumpEndChanged extends EvaporasiSettingsEvent {
  final String value; // HH:mm
  const EvaporasiPumpEndChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiStandarTinggiChanged extends EvaporasiSettingsEvent {
  final double value;
  const EvaporasiStandarTinggiChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiBatasKritisChanged extends EvaporasiSettingsEvent {
  final double value;
  const EvaporasiBatasKritisChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiD0Changed extends EvaporasiSettingsEvent {
  final int value;
  const EvaporasiD0Changed(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiDmaxManualChanged extends EvaporasiSettingsEvent {
  final int value;
  const EvaporasiDmaxManualChanged(this.value);
  @override List<Object?> get props => [value];
}

class EvaporasiSettingsSaved extends EvaporasiSettingsEvent {}

class EvaporasiDmaxResetRequested extends EvaporasiSettingsEvent {}