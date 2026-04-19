part of 'atmospheric_conditions_bloc.dart';

class AtmosphericConditionsState extends Equatable {
  final double temperature;
  final double humidity;
  final double pressure;
  final double altitude;

  final bool isLoading;

  const AtmosphericConditionsState({
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.pressure = 0.0,
    this.altitude = 0.0,
    this.isLoading = true,
  });

  AtmosphericConditionsState copyWith({
    double? temperature,
    double? humidity,
    double? pressure,
    double? altitude,
    bool? isLoading,
  }) {
    return AtmosphericConditionsState(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      altitude: altitude ?? this.altitude,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [
        temperature,
        humidity,
        pressure,
        altitude,
        isLoading,
      ];
}
