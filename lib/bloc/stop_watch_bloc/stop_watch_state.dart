part of 'stop_watch_bloc.dart';

/// Base state class for the stopwatch/alarm BLoC
@immutable
sealed class AlarmState {}

/// Initial state of the timer before it starts
final class AlarmInitial extends AlarmState {}

/// State when the timer is running
class TimerRunning extends AlarmState {
  /// Current elapsed/remaining time in seconds
  final int time;

  TimerRunning(this.time);
}

/// State when the timer is stopped/paused
class TimerStopped extends AlarmState {
  /// Time at the moment the timer was stopped
  final int time;

  TimerStopped(this.time);
}

/// State representing a lap added to the timer
class LapAddedState extends AlarmState {
  /// List of recorded laps
  final List<TimerLap> laps;

  LapAddedState(this.laps);
}
