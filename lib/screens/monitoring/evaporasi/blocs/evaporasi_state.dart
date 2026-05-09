part of 'evaporasi_bloc.dart';

enum EvaporasiViewMode { period, customDate }

class EvaporasiState extends Equatable {
  final double currentValue; // nilai evaporasi realtime
  final double temperature; // suhu (opsional dari firebase)
  final double waterLevel; // tinggi air
  final String selectedPeriod;
  final DateTime? selectedDate; // tanggal spesifik untuk custom date
  final EvaporasiViewMode viewMode; // period vs custom date

  final List<double> dailyValues; // untuk grafik
  final List<Evaporasi> history;

  final bool isLoading;

  const EvaporasiState({
    this.currentValue = 0.0,
    this.temperature = 0.0,
    this.waterLevel = 0.0,
    this.selectedPeriod = "Hari Ini",
    this.selectedDate,
    this.viewMode = EvaporasiViewMode.period,
    this.dailyValues = const [],
    this.history = const [],
    this.isLoading = true,
  });

EvaporasiState copyWith({
    double? currentValue,
    double? temperature,
    double? waterLevel,
    String? selectedPeriod,
    DateTime? selectedDate,
    EvaporasiViewMode? viewMode,
    List<double>? dailyValues,
    List<Evaporasi>? history,
    bool? isLoading,
  }) {
    return EvaporasiState(
      currentValue: currentValue ?? this.currentValue,
      temperature: temperature ?? this.temperature,
      waterLevel: waterLevel ?? this.waterLevel,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      dailyValues: dailyValues ?? this.dailyValues,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        currentValue,
        temperature,
        waterLevel,
        selectedPeriod,
        selectedDate,
        viewMode,
        dailyValues,
        history,
        isLoading,
      ];
}
