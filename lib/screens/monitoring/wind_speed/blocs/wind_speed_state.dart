part of 'wind_speed_bloc.dart';

class WindSpeedState extends Equatable {
  final bool isLoading;
  final double currentSpeed;
  final String alertLevel;
  final String selectedPeriod;

  // ── Graf ─────────────────────────────────────────────────────
  final List<double> dailySpeeds;
  final List<double> weeklySpeeds;
  final List<double> monthlySpeeds;

  // ── History ──────────────────────────────────────────────────
  final List<MyWindSpeed> history; // semua data mentah
  final List<MyWindSpeed> filteredHistory; // setelah difilter tanggal
  final DateTime? selectedDate; // null = tampilkan semua

  const WindSpeedState({
    this.isLoading = false,
    this.currentSpeed = 0.0,
    this.alertLevel = 'Normal',
    this.selectedPeriod = 'Hari Ini',
    this.dailySpeeds = const [],
    this.weeklySpeeds = const [],
    this.monthlySpeeds = const [],
    this.history = const [],
    this.filteredHistory = const [],
    this.selectedDate,
  });

  WindSpeedState copyWith({
    bool? isLoading,
    double? currentSpeed,
    String? alertLevel,
    String? selectedPeriod,
    List<double>? dailySpeeds,
    List<double>? weeklySpeeds,
    List<double>? monthlySpeeds,
    List<MyWindSpeed>? history,
    List<MyWindSpeed>? filteredHistory,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
  }) {
    return WindSpeedState(
      isLoading: isLoading ?? this.isLoading,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      alertLevel: alertLevel ?? this.alertLevel,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      dailySpeeds: dailySpeeds ?? this.dailySpeeds,
      weeklySpeeds: weeklySpeeds ?? this.weeklySpeeds,
      monthlySpeeds: monthlySpeeds ?? this.monthlySpeeds,
      history: history ?? this.history,
      filteredHistory: filteredHistory ?? this.filteredHistory,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        currentSpeed,
        alertLevel,
        selectedPeriod,
        dailySpeeds,
        weeklySpeeds,
        monthlySpeeds,
        history,
        filteredHistory,
        selectedDate,
      ];
}
