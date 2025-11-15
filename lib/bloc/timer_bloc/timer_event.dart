part of 'timer_bloc.dart';

@immutable
sealed class TimerEvent {}

/// Start the countdown timer.
/// Requires a unique [timerId] to handle notifications and overlays properly.
class StartTimer extends TimerEvent {
  final int duration; // Countdown duration in seconds
  final int timerId;  // Unique ID for notifications or overlays
  StartTimer(this.duration, this.timerId);
}

/// Stop the timer immediately, keeping the current remaining time.
class StopTimer extends TimerEvent {}

/// Reset the timer to the given initial time.
class ResetTimer extends TimerEvent {
  final int initTime; // Initial time to reset the timer to
  ResetTimer(this.initTime);
}

/// Update the timer duration manually (not used by the periodic timer).
class UpdateTime extends TimerEvent {
  final int time;
  UpdateTime(this.time);
}

/// Internal event triggered on each tick of the countdown.
class TickedTimer extends TimerEvent {
  final int duration; // Remaining duration after the tick
  TickedTimer(this.duration);
}

/// Event signaling that the timer has completed.
/// Can be used for additional handling if needed.
class TimerCompleted extends TimerEvent {}

/// Event to play the alarm sound when the timer finishes.
class PlayAlarm extends TimerEvent {}

/// Event to stop the alarm sound and dismiss notifications.
class StopAlarm extends TimerEvent {}
