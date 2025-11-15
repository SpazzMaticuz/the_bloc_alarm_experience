import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import '../bloc/stop_watch_bloc//stop_watch_bloc.dart';

class Stopwatch extends StatelessWidget {
  const Stopwatch({super.key});

  // Helper method to format milliseconds into a readable time string (e.g., 00:01:23.45)
  String _formatTime(int milliseconds) {
    final displayTime = StopWatchTimer.getDisplayTime(milliseconds);
    return displayTime;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Provide a new instance of AlarmBloc to thi s widget tree
      create: (_) => StopWatchBloc(),
      child: Scaffold(
        body: BlocBuilder<StopWatchBloc, AlarmState>(
          // BlocBuilder listens for state changes and rebuilds the UI accordingly
          builder: (context, state) {
            final laps = context.watch<StopWatchBloc>().laps;

            // Extract the current timer value from the state
            final time = switch (state) {
              TimerRunning(:final time) => time,
              TimerStopped(:final time) => time,
              _ => 0, // Default value when timer hasn't started yet
            };

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display the formatted time
                Text(
                  _formatTime(time),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 20),

                // Timer control buttons: Start, Stop, Reset
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Start button dispatches StartTimer event
                    ElevatedButton(
                      onPressed: () =>
                          context.read<StopWatchBloc>().add(StartTimer()),
                      child: const Text('Start'),
                    ),
                    const SizedBox(width: 10),

                    // Stop button dispatches StopTimer event
                    ElevatedButton(
                      onPressed: () =>
                          context.read<StopWatchBloc>().add(StopTimer()),
                      child: const Text('Stop'),
                    ),
                    const SizedBox(width: 10),

                    // Reset button dispatches ResetTimer event
                    ElevatedButton(
                      onPressed: () =>
                          context.read<StopWatchBloc>().add(ResetTimer()),
                      child: const Text('Reset'),
                    ),

                    const SizedBox(width: 10),

                    // Reset button dispatches ResetTimer event
                    ElevatedButton(
                      onPressed: () =>
                          context.read<StopWatchBloc>().add(LapTimer()),
                      child: const Text('Lap'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    itemCount: laps.length,
                    itemBuilder: (context, index) {
                      final lap = laps[index];
                      return StreamBuilder<int>(
                        stream: lap.timeStream,
                        builder: (context, snapshot) {
                          final time = snapshot.data ?? 0;
                          final display = StopWatchTimer.getDisplayTime(time);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Center(
                              child: Text(
                                'Lap ${lap.lapNumber}: $display',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),


              ],
            );
          },
        ),
      ),
    );
  }
}
