import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarms/alarms_bloc.dart';
import '../modes/time_picker_row.dart';

/// Converts a time in hours and minutes to total minutes since midnight.
int timeToMinutesSinceMidnight(int hour, int minute) {
  return (hour * 60) + minute;
}

/// Widget for setting the time when creating or editing an alarm.
/// Uses the [AlarmsBloc] to update the state when time changes.
class AlarmOptions extends StatelessWidget {
  final bool isEdit; // Indicates if this is editing an existing alarm
  final VoidCallback onSave; // Callback when the user saves the alarm

  const AlarmOptions({
    super.key,
    required this.isEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmsBloc, AlarmsState>(
      builder: (context, state) {
        final alarmsBloc = context.read<AlarmsBloc>();

        // Convert minutesSinceMidnight to a DateTime for the TimePickerRow
        final initialTime = DateTime(
          0, 0, 0,
          state.minutesSinceMidnight != null
              ? (state.minutesSinceMidnight! ~/ 60)
              : 0,
          state.minutesSinceMidnight != null
              ? (state.minutesSinceMidnight! % 60)
              : 0,
        );

        return Column(
          children: [
            const SizedBox(height: 26),

            /// Time picker row allows user to select hours and minutes
            /// Updates the bloc when the time changes
            TimePickerRow(
              mode: TimePickerMode.ampm,
              initialTime: initialTime,
              onChanged: (hours24, minutes, _) {
                final minutesSinceMidnight = timeToMinutesSinceMidnight(hours24, minutes);

                // Log only important state changes
                log('Time Updated to: $minutesSinceMidnight');

                // Dispatch event to update the bloc state
                alarmsBloc.add(TimeUpdatedEvent(minutesSinceMidnight));
              },
            ),
          ],
        );
      },
    );
  }
}
