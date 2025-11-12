part of 'timer_bloc.dart';

@immutable
sealed class TimerState {
  final int duration;
  const TimerState(this.duration);
}

class TimerInitial extends TimerState {
  const TimerInitial(super.duration);
}

class TimerRunInProgress extends TimerState {
  const TimerRunInProgress(super.duration);
}

class TimerRunComplete extends TimerState {
  const TimerRunComplete() : super(0);
}
