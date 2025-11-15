part of 'alarms_bloc.dart';

/// Base class for all Alarms BLoC events
sealed class AlarmsEvent {}

/// Changes the current view of the alarm popup (e.g., main form or repeat selection)
class ChangeViewEvent extends AlarmsEvent {
  final PopupView newView;
  ChangeViewEvent(this.newView);
}

/// Toggles a day in the selected days list
class ToggleDayEvent extends AlarmsEvent {
  final String day;
  ToggleDayEvent(this.day);
}

/// Updates the label of the alarm
class UpdateLabelEvent extends AlarmsEvent {
  final String label;
  UpdateLabelEvent(this.label);
}

/// Updates the time of the alarm in minutes since midnight
class TimeUpdatedEvent extends AlarmsEvent {
  final int minutesSinceMidnight;
  TimeUpdatedEvent(this.minutesSinceMidnight);
}

/// Resets the alarm state in the BLoC to initial
class ResetAlarmStateEvent extends AlarmsEvent {}

/// Deletes an alarm from the database
class DeleteAlarmEvent extends AlarmsEvent {
  final int id;
  DeleteAlarmEvent(this.id);
}

/// Updates the selected music path for the alarm
class UpdateMusicEvent extends AlarmsEvent {
  final String musicPath;
  UpdateMusicEvent(this.musicPath);

  // For equality checks if needed
  List<Object> get props => [musicPath];
}

/// Preloads an existing alarm's data into the BLoC state before editing
class AlarmPreloadedEvent extends AlarmsEvent {
  final int minutesSinceMidnight;
  final String labelText;
  final int isActive; // 1 = active, 0 = inactive
  final String music;
  final List<String> selectedDays;

  AlarmPreloadedEvent({
    required this.minutesSinceMidnight,
    required this.labelText,
    required this.isActive,
    required this.music,
    required this.selectedDays,
  });
}

/// Toggles an alarm's active/inactive state
/// Optionally provides a Completer to wait until the toggle operation is done
class ToggleAlarmActiveEvent extends AlarmsEvent {
  final int alarmId;
  final bool isActive;
  final Completer<void>? completer;

  ToggleAlarmActiveEvent({
    required this.alarmId,
    required this.isActive,
    this.completer,
  });
}
