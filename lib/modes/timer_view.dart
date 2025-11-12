import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/timer_bloc/timer_bloc.dart';

class TimerView extends StatelessWidget {
  // ⭐ NEW: Accept the unique ID
  final int timerId;
  final int initialDuration;
  final VoidCallback onDelete;

  const TimerView({
    super.key,
    required this.timerId, // ⭐ MUST be required
    required this.initialDuration,
    required this.onDelete,
  });

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

        // ⭐ FIX: Removed redundant switch case. All TimerState objects
        // contain the 'duration' property due to the base class, but
        // matching the sealed subtypes is cleaner.
        final duration = switch (state) {
          TimerRunInProgress(:final duration) => duration,
          TimerRunComplete(:final duration) => duration,
          TimerInitial(:final duration) => duration,
        };

        final durationToStart = switch (state) {
          TimerInitial(:final duration) => duration,
          TimerRunComplete(:final duration) => duration,
          TimerRunInProgress(:final duration) => duration, // Can be used for pause/resume if implemented
        };

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(duration),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                if (state is TimerInitial || state is TimerRunComplete) {
                  // ⭐ CRITICAL FIX: Pass both duration AND the unique ID
                  context.read<TimerBloc>().add(StartTimer(durationToStart, timerId));
                } else if (state is TimerRunInProgress) {
                  // NOTE: For true pause, you'd add a PauseTimer event.
                  // StopTimer here cancels and resets the state.
                  context.read<TimerBloc>().add(StopTimer());
                }
              },
              child: Text(state is TimerRunInProgress ? 'Stop' : 'Start'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TimerBloc>().add(ResetTimer(initialDuration));
              },
              child: const Text('Reset'),
            ),
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