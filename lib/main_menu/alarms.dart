import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../alarm_screens/alarm_options.dart';
import '../alarm_screens/edit_alarm.dart';
import '../bloc/alarms/alarms_bloc.dart';
import '../modes/bottom_popup.dart';
import '../database/alarm_database.dart';

int timeToMinutesSinceMidnight(int hour, int minute) => hour * 60 + minute;

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
          '$time $period',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$label - $note'),
        trailing: Switch(
          value: isActive,
          onChanged: onToggle,
        ),
      ),
    );
  }
}

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
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final data = await AlarmDatabase.instance.readAll();
    setState(() {
      alarms = data;
    });
  }

  String formatTime(int minutesSinceMidnight) {
    final hour = minutesSinceMidnight ~/ 60;
    final minute = minutesSinceMidnight % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
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
        title: const Text(
          'Alarms',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Alarm',
            onPressed: () async {
              debugPrint('Add Alarm button pressed');
              alarmsBloc.add(ResetAlarmStateEvent());
              // Initialize time
              final now = TimeOfDay.now();
              final initialMinutes = timeToMinutesSinceMidnight(now.hour, now.minute);
              alarmsBloc.add(TimeUpdatedEvent(initialMinutes));

              // Show popup
              await BottomPopup.show(
                context,
                title: 'Create Alarm',
                content: BlocProvider.value(
                  value: alarmsBloc,
                  child: AlarmOptions(
                    isEdit: false,
                    onSave: () async {
                      await alarmsBloc.saveAlarm();
                      await _loadAlarms(); // refresh list
                    },
                  ),
                ),
                onSave: () async {
                  await alarmsBloc.saveAlarm();
                  await _loadAlarms();
                },
                onCancel: () {
                  log('Alarm creation cancelled, resetting state.');
                  alarmsBloc.add(ResetAlarmStateEvent());
                },
              );

              // Refresh after popup closes
              await _loadAlarms();
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
            isActive: (alarm['isActive'] ?? 1) == 1,
            onToggle: (value) async {
              await AlarmDatabase.instance.update(
                alarm['id'] as int,
                {
                  'minutesSinceMidnight': alarm['minutesSinceMidnight'],
                  'isActive': value ? 1 : 0,
                  'label': alarm['label'],
                  'days': alarm['days'],
                  'music': alarm['music'],

                },
              );
              _loadAlarms();
            },
              onTap: () async {
                final id = alarm['id'] as int;
                final selectedDays = (alarm['days'] is String && (alarm['days'] as String).isNotEmpty)
                    ? (alarm['days'] as String)
                    .split(',')
                    .map((d) => d.trim())
                    .where((d) => d.isNotEmpty)
                    .toList()
                    : <String>[];


                // ✅ Preload values into Bloc BEFORE opening popup
                alarmsBloc.add(AlarmPreloadedEvent(
                  minutesSinceMidnight: alarm['minutesSinceMidnight'] as int,
                  labelText: alarm['label'] ?? '',
                  isActive: (alarm['isActive'] ?? 1) as int,
                  music: alarm['music'] ?? 'songs/alarm.mp3',
                  selectedDays: selectedDays,
                ));

                // ✅ Now open the popup — it’ll display the preloaded values
                AlarmEditorPopup.show(
                  context,
                  alarmId: id,
                  onSave: () async {
                    await alarmsBloc.editAlarm(
                      id,
                      label: alarmsBloc.state.labelText, // ✅ Use BLoC state
                      music: alarmsBloc.state.music,     // ✅ Use BLoC state
                      minutesSinceMidnight: alarmsBloc.state.minutesSinceMidnight!, // ✅ Use BLoC state
                      isActive: alarmsBloc.state.isActive, // ✅ Use BLoC state
                      selectedDays: alarmsBloc.state.selectedDays, // ✅ Use BLoC state
                      notificationKey: alarm['notificationKey'],
                    );
                    await _loadAlarms();
                  },
                  onDelete: () async {
                    await AlarmDatabase.instance.delete(id);
                    log('Alarm deleted');
                    alarmsBloc.add(ResetAlarmStateEvent());
                    await _loadAlarms();
                  },
                );
              }


          );
        },
      ),
    );
  }
}
