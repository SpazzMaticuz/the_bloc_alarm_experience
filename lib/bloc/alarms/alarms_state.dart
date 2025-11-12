part of 'alarms_bloc.dart';

enum PopupView { main, repeatSelection }

class AlarmsState {
  final PopupView currentView;
  final String labelText;
  final List<String> selectedDays;
  final int? minutesSinceMidnight;
  final int isActive;
  final String music; // ✅ added

  const AlarmsState({
    this.currentView = PopupView.main,
    this.labelText = "",
    this.selectedDays = const [],
    this.minutesSinceMidnight,
    this.isActive = 1,
    this.music = "songs/alarm.mp3", // ✅ default
  });

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

  static AlarmsState initial() => const AlarmsState();
}
