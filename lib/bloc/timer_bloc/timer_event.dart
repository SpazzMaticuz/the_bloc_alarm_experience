part of 'timer_bloc.dart';

@immutable
sealed class TimerEvent {}

// ⭐ UPDATED: StartTimer now requires the unique timerId
class StartTimer extends TimerEvent {
  final int duration;
  final int timerId; // Unique ID from TimerCubicCubit/Database
  StartTimer(this.duration, this.timerId);
}

class StopTimer extends TimerEvent {}

class ResetTimer extends TimerEvent {
  final int initTime;
  ResetTimer(this.initTime);
}

class UpdateTime extends TimerEvent {
  final int time;
  UpdateTime(this.time);
}

class TickedTimer extends TimerEvent {
  final int duration;
  TickedTimer(this.duration);
}

class TimerCompleted extends TimerEvent {}

// ⭐ NEW: Event to explicitly start the alarm sound
class PlayAlarm extends TimerEvent {}

// ⭐ NEW: Event to explicitly stop the alarm sound and dismiss notification
class StopAlarm extends TimerEvent {}