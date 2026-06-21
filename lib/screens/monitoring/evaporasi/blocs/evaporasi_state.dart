// lib/screens/monitoring/evaporasi/blocs/evaporasi_state.dart
part of 'evaporasi_bloc.dart';

class EvaporasiState extends Equatable {
  final double currentValue;
  final double temperature;
  final double waterLevel;
  final double batasKritisCm;

  // Rentang tanggal aktif untuk grafik
  final DateTime startDate;
  final DateTime endDate;

  // Data grafik
  final List<double> chartValues;
  final List<double> chartTemperatures;
  final List<String> chartLabels;

  // Data list
  final List<Evaporasi> history;
  final List<Evaporasi> filteredHistory;

  // Filter list
  final DateTime? selectedDateFilter;

  final String weatherStatus;
  final bool willRain;
  final Evaporasi? currentData;
  final bool isLoading;

  EvaporasiState({
    this.currentValue = 0.0,
    this.temperature = 0.0,
    this.waterLevel = 0.0,
    this.batasKritisCm = 15.0,
    DateTime? startDate,
    DateTime? endDate,
    this.chartValues = const [],
    this.chartTemperatures = const [],
    this.chartLabels = const [],
    this.history = const [],
    this.filteredHistory = const [],
    this.selectedDateFilter,
    this.weatherStatus = 'Rendah',
    this.willRain = false,
    this.currentData,
    this.isLoading = true,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now();

  EvaporasiState copyWith({
    double? currentValue,
    double? temperature,
    double? waterLevel,
    double? batasKritisCm,
    DateTime? startDate,
    DateTime? endDate,
    List<double>? chartValues,
    List<double>? chartTemperatures,
    List<String>? chartLabels,
    List<Evaporasi>? history,
    List<Evaporasi>? filteredHistory,
    DateTime? selectedDateFilter,
    bool clearSelectedDateFilter = false,
    String? weatherStatus,
    bool? willRain,
    Evaporasi? currentData,
    bool? isLoading,
  }) {
    return EvaporasiState(
      currentValue: currentValue ?? this.currentValue,
      temperature: temperature ?? this.temperature,
      waterLevel: waterLevel ?? this.waterLevel,
      batasKritisCm: batasKritisCm ?? this.batasKritisCm,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      chartValues: chartValues ?? this.chartValues,
      chartTemperatures: chartTemperatures ?? this.chartTemperatures,
      chartLabels: chartLabels ?? this.chartLabels,
      history: history ?? this.history,
      filteredHistory: filteredHistory ?? this.filteredHistory,
      selectedDateFilter: clearSelectedDateFilter
          ? null
          : (selectedDateFilter ?? this.selectedDateFilter),
      weatherStatus: weatherStatus ?? this.weatherStatus,
      willRain: willRain ?? this.willRain,
      currentData: currentData ?? this.currentData,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // 1 hari = tampil per jam, > 1 hari = tampil per hari
  bool get isSingleDay {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return s == e;
  }

  @override
  List<Object?> get props => [
        currentValue, temperature, waterLevel, batasKritisCm,
        startDate, endDate,
        chartValues, chartTemperatures, chartLabels,
        history, filteredHistory, selectedDateFilter,
        weatherStatus, willRain, currentData, isLoading,
      ];
}