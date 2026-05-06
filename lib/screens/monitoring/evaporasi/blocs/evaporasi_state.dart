part of 'evaporasi_bloc.dart';

class EvaporasiState extends Equatable {
  final double currentValue; // nilai evaporasi realtime
  final double temperature; // suhu (opsional dari firebase)
  final double waterLevel; // tinggi air
  final String selectedPeriod;

  final List<double> dailyValues; // untuk grafik evaporasi
  final List<double> weeklyValues;
  final List<double> monthlyValues;

  final List<double> dailyTemperatures; // untuk grafik suhu
  final List<double> weeklyTemperatures;
  final List<double> monthlyTemperatures;

  final List<Evaporasi> history;

  final String weatherStatus;
  final bool willRain;
  final bool isLoading;

  const EvaporasiState({
    this.currentValue = 0.0,
    this.temperature = 0.0,
    this.waterLevel = 0.0,
    this.selectedPeriod = "Hari Ini",
    this.dailyValues = const [],
    this.weeklyValues = const [],
    this.monthlyValues = const [],
    this.dailyTemperatures = const [],
    this.weeklyTemperatures = const [],
    this.monthlyTemperatures = const [],
    this.history = const [],
    this.weatherStatus = "Baik",
    this.willRain = false,
    this.isLoading = true,
  });

  EvaporasiState copyWith({
    double? currentValue,
    double? temperature,
    double? waterLevel,
    String? selectedPeriod,
    List<double>? dailyValues,
    List<double>? weeklyValues,
    List<double>? monthlyValues,
    List<double>? dailyTemperatures,
    List<double>? weeklyTemperatures,
    List<double>? monthlyTemperatures,
    List<Evaporasi>? history,
    String? weatherStatus,
    bool? willRain,
    bool? isLoading,
  }) {
    return EvaporasiState(
      currentValue: currentValue ?? this.currentValue,
      temperature: temperature ?? this.temperature,
      waterLevel: waterLevel ?? this.waterLevel,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      dailyValues: dailyValues ?? this.dailyValues,
      weeklyValues: weeklyValues ?? this.weeklyValues,
      monthlyValues: monthlyValues ?? this.monthlyValues,
      dailyTemperatures: dailyTemperatures ?? this.dailyTemperatures,
      weeklyTemperatures: weeklyTemperatures ?? this.weeklyTemperatures,
      monthlyTemperatures: monthlyTemperatures ?? this.monthlyTemperatures,
      history: history ?? this.history,
      weatherStatus: weatherStatus ?? this.weatherStatus,
      willRain: willRain ?? this.willRain,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [
        currentValue,
        temperature,
        waterLevel,
        selectedPeriod,
        dailyValues,
        weeklyValues,
        monthlyValues,
        dailyTemperatures,
        weeklyTemperatures,
        monthlyTemperatures,
        history,
        weatherStatus,
        willRain,
        isLoading,
      ];
}
