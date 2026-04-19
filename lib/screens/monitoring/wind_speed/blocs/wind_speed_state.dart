part of 'wind_speed_bloc.dart';

class WindSpeedState extends Equatable {
  final double currentSpeed;
  final String selectedPeriod;
  final List<double> dailySpeeds; // Untuk grafik
  final bool isLoading;
  final List<MyWindSpeed> history;

  const WindSpeedState({
    this.currentSpeed = 0.0,
    this.selectedPeriod = "Hari Ini",
    this.dailySpeeds = const [],
    this.isLoading = true,
    this.history = const [],
  });

  WindSpeedState copyWith({
    double? currentSpeed,
    String? selectedPeriod,
    List<double>? dailySpeeds,
    bool? isLoading,
    List<MyWindSpeed>? history,
  }) {
    return WindSpeedState(
      currentSpeed: currentSpeed ?? this.currentSpeed,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      dailySpeeds: dailySpeeds ?? this.dailySpeeds,
      isLoading: isLoading ?? this.isLoading,
      history: history ?? this.history,
    );
  }

  @override
  List<Object> get props =>
      [currentSpeed, selectedPeriod, dailySpeeds, isLoading, history];
}
