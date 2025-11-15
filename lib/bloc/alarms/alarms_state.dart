part of 'alarms_bloc.dart';

/// Represents the current view of the alarm popup
enum PopupView { main, repeatSelection }

/// State of the Alarms BLoC
class AlarmsState {
  /// Current view of the popup (main form or repeat selection)
  final PopupView currentView;

  /// Alarm label text
  final String labelText;

  /// List of selected days (short names like 'Mon', 'Tue', etc.)
  final List<String> selectedDays;

  /// Time of the alarm in minutes since midnight
  final int? minutesSinceMidnight;

  /// Whether the alarm is active (1 = active, 0 = inactive)
  final int isActive;

  /// Selected music path for the alarm
  final String music;

  const AlarmsState({
    this.currentView = PopupView.main,
    this.labelText = "",
    this.selectedDays = const [],
    this.minutesSinceMidnight,
    this.isActive = 1,
    this.music = "songs/alarm.mp3",
  });

  /// Creates a copy of the current state with optional overrides
  AlarmsState copyWith({
    PopupView? currentView,
    String? labelText,
    List<String>? selectedDays,
    int? minutesSinceMidnight,
    int? isActive,
    String? music,
  }) {
    return AlarmsState(
      currentView: currentView ?? this.currentView,
      labelText: labelText ?? this.labelText,
      selectedDays: selectedDays ?? this.selectedDays,
      minutesSinceMidnight: minutesSinceMidnight ?? this.minutesSinceMidnight,
      isActive: isActive ?? this.isActive,
      music: music ?? this.music,
    );
  }

  /// Returns the initial default state
  static AlarmsState initial() => const AlarmsState();
}
