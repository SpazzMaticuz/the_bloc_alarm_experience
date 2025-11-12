import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import '/modes/timerLap.dart';

part 'stop_watch_event.dart';
part 'stop_watch_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  // Stopwatch timer instance
  final StopWatchTimer _stopWatchTimer = StopWatchTimer();

  // Subscription to the stopwatch's rawTime stream
  StreamSubscription<int>? _timerSubscription;
  final List<TimerLap> _laps = [];

  List<TimerLap> get laps => List.unmodifiable(_laps);

  AlarmBloc() : super(AlarmInitial()) {
    // Start timer event
    on<StartTimer>((event, emit) {
      // Start the stopwatch
      _stopWatchTimer.onStartTimer();

      // Cancel any previous stream subscriptions
      _timerSubscription?.cancel();

      // Listen to raw time updates and dispatch UpdateTime events
      _timerSubscription = _stopWatchTimer.rawTime.listen((time) {
        add(UpdateTime(time));
      });

      if (_laps.isNotEmpty) {
        // Start the latest lap stopwatch if it exists
        _laps.last.start();
      }
    });

    // Stop timer event
    on<StopTimer>((event, emit) async {
      // Stop the main stopwatch.
      _stopWatchTimer.onStopTimer();

      // Stop the latest lap stopwatch if it exists
      if (_laps.isNotEmpty) {
        _laps.last.stop();
      }

      // Cancel stream subscription
      _timerSubscription?.cancel();

      // Emit the final time in the stopped state
      final time = await _stopWatchTimer.rawTime.first;
      emit(TimerStopped(time));
    });

    // Reset timer event
    on<ResetTimer>((event, emit) {
      // Reset the stopwatch to 0
      _stopWatchTimer.onResetTimer();

      _laps.clear();

      // Emit state showing 0 time
      emit(TimerRunning(0));
    });

    // Time update event (fired frequently as the timer runs)
    on<UpdateTime>((event, emit) {
      // Emit the current running time
      emit(TimerRunning(event.time));
    });

    on<LapTimer>((event, emit) {
      final currentState = state;
      if (currentState is TimerRunning) {
        final currentMainTime = currentState.time;

        if (_laps.isEmpty) {
          // First lap: Record the current main timer value
          const lapNumber = 1;
          final firstLap = TimerLap(
            lapNumber: lapNumber,
            initialTime: currentMainTime,
            isFirstLap: true,
          );

          _laps.add(firstLap);
          final newLap = TimerLap(lapNumber: lapNumber + 1);
          _laps.add(newLap);
        } else {
          // Stop previous lap
          _laps.last.stop();

          // Create a new lap (starting from 0)
          final lapNumber = _laps.length + 1;
          final newLap = TimerLap(lapNumber: lapNumber);
          _laps.add(newLap);
        }

        // Re-emit current state to update the UI
        emit(TimerRunning(currentMainTime));
      }
    });
  }

  @override
  Future<void> close() {
    // Dispose the timer and cancel subscriptions to free resources
    _stopWatchTimer.dispose();
    _timerSubscription?.cancel();
    return super.close();
  }
}
