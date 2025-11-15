import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../alarm_screens/alarm_options.dart';
import '../alarm_screens/edit_alarm.dart';
import '../bloc/alarms/alarms_bloc.dart';
import '../modes/bottom_popup.dart';
import '../database/alarm_database.dart';

// Convert hour & minute to total minutes since midnight
int timeToMinutesSinceMidnight(int hour, int minute) => hour * 60 + minute;

// Individual alarm card widget
class AlarmCard extends StatelessWidget {
  final String time, period, label, note;
  final bool isActive;
  final Function(bool) onToggle;
  final VoidCallback onTap;

  const AlarmCard({
    super.key,
    required this.time,
    required this.period,
    required this.label,
    required this.note,
    required this.isActive,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          '$time $period', // e.g., 07:30 AM
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$label - $note'), // Shows label and selected days
        trailing: Switch(value: isActive, onChanged: onToggle),
      ),
    );
  }
}

// Main alarm list screen
class Alarms extends StatefulWidget {
  const Alarms({super.key});

  @override
  State<Alarms> createState() => _AlarmsState();
}

class _AlarmsState extends State<Alarms> {
  late final AlarmsBloc alarmsBloc;
  List<Map<String, dynamic>> alarms = [];

  @override
  void initState() {
    super.initState();
    alarmsBloc = context.read<AlarmsBloc>();
    _loadAlarms(); // Load alarms from database on startup
  }

  // Load alarms from DB
  Future<void> _loadAlarms() async {
    final data = await AlarmDatabase.instance.readAll();
    setState(() => alarms = data);
  }

  // Format minutes into hh:mm 12-hour format
  String formatTime(int minutesSinceMidnight) {
    final hour = minutesSinceMidnight ~/ 60;
    final minute = minutesSinceMidnight % 60;
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // Add alarm button
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Alarm',
            onPressed: () async {
              alarmsBloc.add(ResetAlarmStateEvent()); // Reset state before creating new alarm

              // Set initial time to current time
              final now = TimeOfDay.now();
              final initialMinutes = timeToMinutesSinceMidnight(now.hour, now.minute);
              alarmsBloc.add(TimeUpdatedEvent(initialMinutes));

              // Show BottomPopup to create alarm
              await BottomPopup.show(
                context,
                title: 'Create Alarm',
                content: BlocProvider.value(
                  value: alarmsBloc,
                  child: AlarmOptions(
                    isEdit: false,
                    onSave: () async {
                      await alarmsBloc.saveAlarm();
                      await _loadAlarms();
                    },
                  ),
                ),
                onSave: () async {
                  await alarmsBloc.saveAlarm();
                  await _loadAlarms();
                },
                onCancel: () => alarmsBloc.add(ResetAlarmStateEvent()),
              );

              await _loadAlarms(); // Refresh after popup closes
            },
          ),
        ],
      ),
      body: alarms.isEmpty
          ? const Center(child: Text('No alarms yet'))
          : ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          final minutes = alarm['minutesSinceMidnight'] as int;
          final formattedTime = formatTime(minutes);
          final hour = minutes ~/ 60;
          final period = hour >= 12 ? 'PM' : 'AM';

          return AlarmCard(
            time: formattedTime,
            period: period,
            label: alarm['label'] ?? 'Alarm',
            note: alarm['days'] ?? 'Never',
            isActive: alarm['isActive'] == 1,

            // Toggle activation state
            onToggle: (value) async {
              final alarmId = alarm['id'] as int;

              // Completer ensures BLoC finishes before refreshing
              final completer = Completer<void>();
              alarmsBloc.add(ToggleAlarmActiveEvent(alarmId: alarmId, isActive: value, completer: completer));
              await completer.future;

              await _loadAlarms(); // Refresh after toggle
            },

            // Tap to edit alarm
            onTap: () async {
              final id = alarm['id'] as int;
              final selectedDays = (alarm['days'] is String && (alarm['days'] as String).isNotEmpty)
                  ? (alarm['days'] as String).split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList()
                  : <String>[];

              // Preload current alarm values into BLoC
              alarmsBloc.add(AlarmPreloadedEvent(
                minutesSinceMidnight: alarm['minutesSinceMidnight'] as int,
                labelText: alarm['label'] ?? '',
                isActive: (alarm['isActive'] ?? 1) as int,
                music: alarm['music'] ?? 'songs/alarm.mp3',
                selectedDays: selectedDays,
              ));

              // Open popup editor
              AlarmEditorPopup.show(
                context,
                alarmId: id,
                onSave: () async {
                  await alarmsBloc.editAlarm(
                    id,
                    label: alarmsBloc.state.labelText,
                    music: alarmsBloc.state.music,
                    minutesSinceMidnight: alarmsBloc.state.minutesSinceMidnight!,
                    isActive: alarmsBloc.state.isActive,
                    selectedDays: alarmsBloc.state.selectedDays,
                    notificationKey: alarm['notificationKey'],
                  );
                  await _loadAlarms();
                },
                onDelete: () async {
                  await AlarmDatabase.instance.delete(id);
                  alarmsBloc.add(ResetAlarmStateEvent());
                  await _loadAlarms();
                },
              );
            },
          );
        },
      ),
    );
  }
}
