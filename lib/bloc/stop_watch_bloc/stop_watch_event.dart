part of 'stop_watch_bloc.dart';

/// Base event class for the stopwatch/alarm BLoC
@immutable
sealed class AlarmEvent {}

/// Event to start the timer
class StartTimer extends AlarmEvent {}

/// Event to stop/pause the timer
class StopTimer extends AlarmEvent {}

/// Event to reset the timer to its initial value
class ResetTimer extends AlarmEvent {}

/// Event to update the current timer value (used internally)
class UpdateTime extends AlarmEvent {
  /// Current elapsed/remaining time in seconds
  final int time;

  UpdateTime(this.time);
}

/// Event to record a lap (splits or intermediate time)
class LapTimer extends AlarmEvent {}
