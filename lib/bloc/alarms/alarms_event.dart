part of 'alarms_bloc.dart';

sealed class AlarmsEvent {}

class ChangeViewEvent extends AlarmsEvent {
  final PopupView newView;
  ChangeViewEvent(this.newView);
}

class ToggleDayEvent extends AlarmsEvent {
  final String day;
  ToggleDayEvent(this.day);
}

class UpdateLabelEvent extends AlarmsEvent {
  final String label;
  UpdateLabelEvent(this.label);
}

// ✅ New Event to update the time
class TimeUpdatedEvent extends AlarmsEvent {
  final int minutesSinceMidnight;
  TimeUpdatedEvent(this.minutesSinceMidnight);
}

// ✅ New Event to reset all alarm-specific data
class ResetAlarmStateEvent extends AlarmsEvent {}

class DeleteAlarmEvent extends AlarmsEvent {
  final int id; // ID of the alarm to delete
  DeleteAlarmEvent(this.id);
}

class UpdateMusicEvent extends AlarmsEvent {
  final String musicPath;
   UpdateMusicEvent(this.musicPath); // ✅ FIX: Added 'const' keyword
  List<Object> get props => [musicPath];
}

class AlarmPreloadedEvent extends AlarmsEvent {
  final int minutesSinceMidnight;
  final String labelText;
  final int isActive;
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

