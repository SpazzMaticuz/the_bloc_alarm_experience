part of 'stop_watch_bloc.dart';

@immutable
sealed class AlarmEvent {}

class StartTimer extends AlarmEvent {}
class StopTimer extends AlarmEvent {}
class ResetTimer extends AlarmEvent {}
class UpdateTime extends AlarmEvent {
  final int time;
  UpdateTime(this.time);
}
class LapTimer extends AlarmEvent {}
