part of 'wind_speed_bloc.dart';

class WindSpeedState extends Equatable {
  final double currentSpeed;
  final String selectedPeriod;
  final List<double> dailySpeeds;
  final List<double> weeklySpeeds;
  final List<double> monthlySpeeds;
  final bool isLoading;
  final List<MyWindSpeed> history;
  final String alertLevel; // "Normal" | "Waspada" | "Bahaya"

  // ── Delete Operation ─────────────────────────────────────────
  final String? deleteMessage; // null = no operation, non-null = feedback

  const WindSpeedState({
    this.currentSpeed = 0.0,
    this.selectedPeriod = "Hari Ini",
    this.dailySpeeds = const [],
    this.isLoading = true,
    this.history = const [],
<<<<<<< Updated upstream
    this.monthlySpeeds = const [],
    this.weeklySpeeds = const [],
    this.alertLevel = "Normal",
=======
    this.filteredHistory = const [],
    this.selectedDate,
    this.deleteMessage,
>>>>>>> Stashed changes
  });

  WindSpeedState copyWith({
    double? currentSpeed,
    String? selectedPeriod,
    List<double>? dailySpeeds,
    List<double>? weeklySpeeds,
    List<double>? monthlySpeeds,
    bool? isLoading,
    List<MyWindSpeed>? history,
<<<<<<< Updated upstream
    String? alertLevel,
=======
    List<MyWindSpeed>? filteredHistory,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    String? deleteMessage,
>>>>>>> Stashed changes
  }) {
    return WindSpeedState(
      currentSpeed: currentSpeed ?? this.currentSpeed,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      dailySpeeds: dailySpeeds ?? this.dailySpeeds,
      weeklySpeeds: weeklySpeeds ?? this.weeklySpeeds,
      monthlySpeeds: monthlySpeeds ?? this.monthlySpeeds,
      isLoading: isLoading ?? this.isLoading,
      history: history ?? this.history,
<<<<<<< Updated upstream
      alertLevel: alertLevel ?? this.alertLevel,
=======
      filteredHistory: filteredHistory ?? this.filteredHistory,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      deleteMessage: deleteMessage ?? this.deleteMessage,
>>>>>>> Stashed changes
    );
  }

  @override
  List<Object> get props => [
        currentSpeed,
        selectedPeriod,
        dailySpeeds,
        weeklySpeeds,
        monthlySpeeds,
        isLoading,
        history,
<<<<<<< Updated upstream
        alertLevel,
=======
        filteredHistory,
        selectedDate,
        deleteMessage,
>>>>>>> Stashed changes
      ];
}
