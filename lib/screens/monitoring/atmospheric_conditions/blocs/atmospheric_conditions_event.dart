part of 'atmospheric_conditions_bloc.dart';

abstract class AtmosphericConditionsEvent extends Equatable {
  const AtmosphericConditionsEvent();

  @override
  List<Object> get props => [];
}

class WatchAtmosphericConditionsStarted extends AtmosphericConditionsEvent {}
