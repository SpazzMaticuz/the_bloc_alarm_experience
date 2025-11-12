part of 'stop_watch_bloc.dart';

@immutable
sealed class AlarmState {}

final class AlarmInitial extends AlarmState {}

class TimerRunning extends AlarmState {
  final int time;
  TimerRunning(this.time);
}

class TimerStopped extends AlarmState {
  final int time;
  TimerStopped(this.time);
}

class LapAddedState extends AlarmState {
  final List<TimerLap> laps;
  LapAddedState(this.laps);
}