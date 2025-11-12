import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarms/alarms_bloc.dart';
import '../modes/time_picker_row.dart';

int timeToMinutesSinceMidnight(int hour, int minute) {
  return (hour * 60) + minute;
}

class AlarmOptions extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onSave;

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

        // 🕓 Build the initial time from state.minutesSinceMidnight (if any)
        final initialTime = DateTime(
          0,
          0,
          0,
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
            // ✅ Pass initialTime to your TimePickerRow
            TimePickerRow(
              mode: TimePickerMode.ampm,
              initialTime: initialTime,
              onChanged: (hours24, minutes, _) {
                final minutesSinceMidnight = timeToMinutesSinceMidnight(hours24, minutes);
                log('Time Updated to: $minutesSinceMidnight');
                alarmsBloc.add(TimeUpdatedEvent(minutesSinceMidnight));
              },
            ),
          ],
        );
      },
    );
  }
}
