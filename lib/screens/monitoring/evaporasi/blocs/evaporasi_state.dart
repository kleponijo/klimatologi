part of 'evaporasi_bloc.dart';

enum EvaporasiViewMode { period, customDate }

class EvaporasiState extends Equatable {
  final double currentValue;
  final double temperature;
  final double waterLevel;
  final String selectedPeriod;
  final DateTime? selectedDate;
  final EvaporasiViewMode viewMode;

  final List<double> dailyValues;
  final List<double> weeklyValues;
  final List<double> monthlyValues;

  final List<double> dailyTemperatures;
  final List<double> weeklyTemperatures;
  final List<double> monthlyTemperatures;

  final List<String> chartLabels;
  final List<Evaporasi> listData;
  final List<Evaporasi> history;
  final String weatherStatus;
  final bool willRain;
  final Evaporasi? currentData; // data realtime terbaru
  final bool isLoading;

  const EvaporasiState({
    this.currentValue = 0.0,
    this.temperature = 0.0,
    this.waterLevel = 0.0,
    this.selectedPeriod = 'Hari Ini',
    this.selectedDate,
    this.viewMode = EvaporasiViewMode.period,
    this.dailyValues = const [],
    this.weeklyValues = const [],
    this.monthlyValues = const [],
    this.dailyTemperatures = const [],
    this.weeklyTemperatures = const [],
    this.monthlyTemperatures = const [],
    this.chartLabels = const [],
    this.listData = const [],
    this.history = const [],
    this.weatherStatus = 'Baik',
    this.willRain = false,
    this.currentData,
    this.isLoading = true,
  });

  // ✅ FIX: Tambah clearSelectedDate flag agar selectedDate bisa di-null-kan
  EvaporasiState copyWith({
    double? currentValue,
    double? temperature,
    double? waterLevel,
    String? selectedPeriod,
    DateTime? selectedDate,
    bool clearSelectedDate = false, // ✅ tambahan flag reset
    EvaporasiViewMode? viewMode,
    List<double>? dailyValues,
    List<double>? weeklyValues,
    List<double>? monthlyValues,
    List<double>? dailyTemperatures,
    List<double>? weeklyTemperatures,
    List<double>? monthlyTemperatures,
    List<String>? chartLabels,
    List<Evaporasi>? listData,
    List<Evaporasi>? history,
    String? weatherStatus,
    bool? willRain,
    Evaporasi? currentData,
    bool? isLoading,
  }) {
    return EvaporasiState(
      currentValue: currentValue ?? this.currentValue,
      temperature: temperature ?? this.temperature,
      waterLevel: waterLevel ?? this.waterLevel,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      // ✅ FIX: jika clearSelectedDate=true, set null; jika selectedDate diberikan, pakai itu;
      //         jika tidak, pertahankan yang lama
      selectedDate: clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      viewMode: viewMode ?? this.viewMode,
      dailyValues: dailyValues ?? this.dailyValues,
      weeklyValues: weeklyValues ?? this.weeklyValues,
      monthlyValues: monthlyValues ?? this.monthlyValues,
      dailyTemperatures: dailyTemperatures ?? this.dailyTemperatures,
      weeklyTemperatures: weeklyTemperatures ?? this.weeklyTemperatures,
      monthlyTemperatures: monthlyTemperatures ?? this.monthlyTemperatures,
      chartLabels: chartLabels ?? this.chartLabels,
      listData: listData ?? this.listData,
      history: history ?? this.history,
      weatherStatus: weatherStatus ?? this.weatherStatus,
      willRain: willRain ?? this.willRain,
      currentData: currentData ?? this.currentData,
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
        weeklyValues,
        monthlyValues,
        dailyTemperatures,
        weeklyTemperatures,
        monthlyTemperatures,
        chartLabels,
        listData,
        history,
        weatherStatus,
        willRain,
        currentData,
        isLoading,
      ];
}
