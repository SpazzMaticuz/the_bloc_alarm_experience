part of 'timer_cubic_cubit.dart';

// This holds the unique database ID and the initial duration.
class TimerData {
  final int id;
  final int initialDuration;

  TimerData({required this.id, required this.initialDuration});

  // Method to help with logging/debugging
  @override
  String toString() => 'TimerData(id: $id, duration: $initialDuration)';
}

@immutable
sealed class TimerCubicState {}

final class TimerCubicInitial extends TimerCubicState {}

final class TimerCubicListUpdated extends TimerCubicState {
  final List<TimerData> timers;

  TimerCubicListUpdated(this.timers);
}