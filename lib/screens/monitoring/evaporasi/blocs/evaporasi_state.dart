part of 'evaporasi_bloc.dart';

class EvaporasiState extends Equatable {
  final double currentValue; // nilai evaporasi realtime
  final double temperature; // suhu (opsional dari firebase)
  final double waterLevel; // tinggi air
  final String selectedPeriod;

  final List<double> dailyValues; // untuk grafik evaporasi
  final List<double> dailyTemperatures; // untuk grafik suhu
  final List<Evaporasi> history;

  final String weatherStatus; // Baik / Sedang / Buruk
  final bool willRain; // true jika status Sedang/Buruk

  final bool isLoading;

  const EvaporasiState({
    this.currentValue = 0.0,
    this.temperature = 0.0,
    this.waterLevel = 0.0,
    this.selectedPeriod = "Hari Ini",
    this.dailyValues = const [],
    this.dailyTemperatures = const [],
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
    List<double>? dailyTemperatures,
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
      dailyTemperatures: dailyTemperatures ?? this.dailyTemperatures,
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
        dailyTemperatures,
        history,
        weatherStatus,
        willRain,
        isLoading,
      ];
}
