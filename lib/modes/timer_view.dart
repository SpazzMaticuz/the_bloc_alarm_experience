import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/timer_bloc/timer_bloc.dart';

// A single timer row with Start/Stop, Reset, and Delete controls
class TimerView extends StatelessWidget {
  final int timerId; // Unique ID for this timer
  final int initialDuration; // Initial countdown seconds
  final VoidCallback onDelete; // Callback to remove the timer

  const TimerView({
    super.key,
    required this.timerId,
    required this.initialDuration,
    required this.onDelete,
  });

  // Format seconds to HH:MM:SS
  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {

        // Current remaining duration (updates every second in progress)
        final duration = switch (state) {
          TimerRunInProgress(:final duration) => duration,
          TimerRunComplete(:final duration) => duration,
          TimerInitial(:final duration) => duration,
        };

        // Duration used when starting or restarting
        final durationToStart = switch (state) {
          TimerInitial(:final duration) => duration,
          TimerRunComplete(:final duration) => duration,
          TimerRunInProgress(:final duration) => duration,
        };

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Countdown display
            Text(
              _formatDuration(duration),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),

            // Start / Stop button
            ElevatedButton(
              onPressed: () {
                if (state is TimerInitial || state is TimerRunComplete) {
                  context.read<TimerBloc>().add(StartTimer(durationToStart, timerId));
                } else if (state is TimerRunInProgress) {
                  context.read<TimerBloc>().add(StopTimer());
                }
              },
              child: Text(state is TimerRunInProgress ? 'Stop' : 'Start'),
            ),

            // Reset button
            ElevatedButton(
              onPressed: () {
                context.read<TimerBloc>().add(ResetTimer(initialDuration));
              },
              child: const Text('Reset'),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        );
      },
    );
  }
}
