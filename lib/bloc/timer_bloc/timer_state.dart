part of 'timer_bloc.dart';

@immutable
sealed class TimerState {
  final int duration; // Current countdown duration in seconds
  const TimerState(this.duration);
}

/// Initial state of the timer before it starts or after a stop/reset.
/// Holds the last set duration.
class TimerInitial extends TimerState {
  const TimerInitial(super.duration);
}

/// State when the timer is actively counting down.
/// The [duration] decreases every tick.
class TimerRunInProgress extends TimerState {
  const TimerRunInProgress(super.duration);
}

/// State when the timer has completed its countdown.
/// Duration is always 0 in this state.
class TimerRunComplete extends TimerState {
  const TimerRunComplete() : super(0);
}
