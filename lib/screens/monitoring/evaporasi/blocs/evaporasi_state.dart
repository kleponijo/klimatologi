part of 'evaporasi_bloc.dart';

class EvaporasiState extends Equatable {
  final double currentValue; // nilai evaporasi realtime
  final double temperature; // suhu (opsional dari firebase)
  final double waterLevel; // tinggi air
  final String selectedPeriod;

  final List<double> dailyValues; // untuk grafik
  final List<Evaporasi> history;

  final bool isLoading;

  const EvaporasiState({
    this.currentValue = 0.0,
    this.temperature = 0.0,
    this.waterLevel = 0.0,
    this.selectedPeriod = "Hari Ini",
    this.dailyValues = const [],
    this.history = const [],
    this.isLoading = true,
  });

  EvaporasiState copyWith({
    double? currentValue,
    double? temperature,
    double? waterLevel,
    String? selectedPeriod,
    List<double>? dailyValues,
    List<Evaporasi>? history,
    bool? isLoading,
  }) {
    return EvaporasiState(
      currentValue: currentValue ?? this.currentValue,
      temperature: temperature ?? this.temperature,
      waterLevel: waterLevel ?? this.waterLevel,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      dailyValues: dailyValues ?? this.dailyValues,
      history: history ?? this.history,
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
        history,
        isLoading,
      ];
}
