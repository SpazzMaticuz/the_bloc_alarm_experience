import 'package:stop_watch_timer/stop_watch_timer.dart';

class TimerLap {
  final int lapNumber;
  final StopWatchTimer? _lapStopwatch;
  final int? initialTime; // Used for first lap
  final bool isFirstLap;

  TimerLap({
    required this.lapNumber,
    this.initialTime,
    this.isFirstLap = false,
  }) : _lapStopwatch =
  isFirstLap ? null : StopWatchTimer() {
    if (!isFirstLap) {
      _lapStopwatch?.onStartTimer();
    }
  }

  /// Stream for lap time
  Stream<int> get timeStream {
    if (isFirstLap) {
      // Return a stream that emits the initial time once
      return Stream.value(initialTime ?? 0);
    } else {
      return _lapStopwatch!.rawTime;
    }
  }

  void start() {
    _lapStopwatch?.onStartTimer();
  }

  void stop() {
    _lapStopwatch?.onStopTimer();
  }

  void dispose() {
    _lapStopwatch?.dispose();
  }

  String get displayTime {
    if (isFirstLap) {
      return StopWatchTimer.getDisplayTime(initialTime ?? 0);
    } else {
      return StopWatchTimer.getDisplayTime(_lapStopwatch!.rawTime.value);
    }
  }
}
