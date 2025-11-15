import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubic/timer_cubic_cubit.dart';
import '../modes/time_picker_row.dart';
import '../modes/timer_controls.dart';

class Timers extends StatefulWidget {
  @override
  _TimersState createState() => _TimersState();
}

class _TimersState extends State<Timers> {
  int totalSeconds = 0; // Store selected duration in seconds

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Time picker row: hours, minutes, seconds
          TimePickerRow(
            mode: TimePickerMode.full,
            onChanged: (hours, minutes, seconds) {
              setState(() {
                totalSeconds = hours * 3600 + minutes * 60 + seconds;
              });
            },
          ),
          const SizedBox(height: 20),

          // Button to add a new timer with selected duration
          ElevatedButton(
            onPressed: () =>
                context.read<TimerCubicCubit>().addTimer(totalSeconds),
            child: const Text('Enter'),
          ),

          // Scrollable list of timers
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.40,
              child: SingleChildScrollView(
                child: BlocBuilder<TimerCubicCubit, TimerCubicState>(
                  builder: (context, state) {
                    final timers = switch (state) {
                      TimerCubicListUpdated(:final timers) => timers,
                      _ => const <TimerData>[],
                    };

                    return Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.40,
                        child: ListView.builder(
                          itemCount: timers.length,
                          itemBuilder: (context, index) {
                            final timerData = timers[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: TimerControls(
                                key: ValueKey(timerData.id),
                                timerId: timerData.id,
                                initialDuration: timerData.initialDuration,
                                // Delete timer
                                onDelete: () {
                                  context
                                      .read<TimerCubicCubit>()
                                      .removeTimerAt(index);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
