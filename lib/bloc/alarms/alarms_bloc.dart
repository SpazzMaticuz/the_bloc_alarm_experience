import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/alarm_database.dart';
import '../../notifications/alarm_notification_controller.dart';

part 'alarms_event.dart';
part 'alarms_state.dart';

class AlarmsBloc extends Bloc<AlarmsEvent, AlarmsState> {
  final AlarmNotificationController _notifier = AlarmNotificationController();

  AlarmsBloc() : super(AlarmsState.initial()) {
    on<ChangeViewEvent>(_onChangeView);
    on<ToggleDayEvent>(_onToggleDay);
    on<UpdateLabelEvent>(_onUpdateLabel);
    on<UpdateMusicEvent>(_onUpdateMusic);
    on<TimeUpdatedEvent>(_onTimeUpdated);
    on<ResetAlarmStateEvent>(_onResetAlarmState);
    on<DeleteAlarmEvent>(_onDeleteAlarm);
    on<AlarmPreloadedEvent>((event, emit) {
      emit(state.copyWith(
        minutesSinceMidnight: event.minutesSinceMidnight,
        labelText: event.labelText,
        isActive: event.isActive,
        music: event.music,
        selectedDays: event.selectedDays,
      ));
    });
    on<ToggleAlarmActiveEvent>(_onToggleAlarmActive);
  }

  void _onChangeView(ChangeViewEvent event, Emitter<AlarmsState> emit) {
    log('[AlarmsBloc] Change view: ${event.newView}');
    emit(state.copyWith(currentView: event.newView));
  }

  void _onToggleDay(ToggleDayEvent event, Emitter<AlarmsState> emit) {
    final updatedDays = List<String>.from(state.selectedDays);
    if (updatedDays.contains(event.day)) {
      updatedDays.remove(event.day);
      log('[AlarmsBloc] Day removed: ${event.day}');
    } else {
      updatedDays.add(event.day);
      log('[AlarmsBloc] Day added: ${event.day}');
    }
    emit(state.copyWith(selectedDays: updatedDays));
  }

  void _onUpdateLabel(UpdateLabelEvent event, Emitter<AlarmsState> emit) {
    log('[AlarmsBloc] Label updated: ${event.label}');
    emit(state.copyWith(labelText: event.label));
  }

  void _onUpdateMusic(UpdateMusicEvent event, Emitter<AlarmsState> emit) {
    log('[AlarmsBloc] Music updated: ${event.musicPath}');
    emit(state.copyWith(music: event.musicPath));
  }

  void _onTimeUpdated(TimeUpdatedEvent event, Emitter<AlarmsState> emit) {
    log('[AlarmsBloc] Time updated (minutesSinceMidnight): ${event.minutesSinceMidnight}');
    emit(state.copyWith(minutesSinceMidnight: event.minutesSinceMidnight));
  }

  void _onResetAlarmState(ResetAlarmStateEvent event, Emitter<AlarmsState> emit) {
    log('[AlarmsBloc] Resetting alarm state');
    emit(AlarmsState.initial());
  }


  /// Save new alarm to DB and schedule its notification
  Future<void> saveAlarm() async {

    if (state.minutesSinceMidnight == null) {
      log('[AlarmsBloc] ❌ Error: minutesSinceMidnight is null.');
      return;
    }

    final alarmData = {
      'minutesSinceMidnight': state.minutesSinceMidnight!,
      'isActive': state.isActive,
      'label': state.labelText.isEmpty ? null : state.labelText,
      'days': state.selectedDays.isEmpty ? null : state.selectedDays.join(','),
      'music': state.music,
    };

    try {
      // 1️⃣ Insert DB to get ID
      final id = await AlarmDatabase.instance.create(alarmData);

      // 2️⃣ Update DB with notificationKey = id
      await AlarmDatabase.instance.update(id, {'notificationKey': id.toString()});

      log('[AlarmsBloc] ✅ Alarm saved with ID: $id, data: $alarmData');

      final time = minutesSinceMidnightToTime(state.minutesSinceMidnight!);
      final hour = time['hour']!;
      final minute = time['minute']!;
      final label = state.labelText.isEmpty ? 'Alarm' : state.labelText;

      if (state.selectedDays.isEmpty) {
        // One-time alarm
        final now = DateTime.now();
        final next = DateTime(now.year, now.month, now.day, hour, minute);
        final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;

        log('[AlarmsBloc] Scheduling one-time alarm for $label at $hour:$minute');
        await _notifier.scheduleOneTimeAlarm(
          id: id,
          dateTime: target,
          label: label, musicPath: state.music,
        );
      } else {
        // Repeating alarm
        log('[AlarmsBloc] Scheduling repeating alarm for $label at $hour:$minute on days: ${state.selectedDays.join(',')}');

        final daysString = state.selectedDays.join(',');
        log('[AlarmsBloc] Cron schedule placeholder: * $minute $hour ? * $daysString *');

        await _notifier.scheduleRepeatingAlarm(
          id: id,
          label: label,
          hour: hour,
          minute: minute,
          weekdays: state.selectedDays, musicPath: state.music,
        );
      }
      log('[AlarmsBloc] 💾 Alarm created with data: $alarmData');
      log('[AlarmsBloc] 🔔 Alarm scheduled successfully.');
    } catch (e) {
      log('[AlarmsBloc] ❌ Error saving alarm: $e');
    }

    add(ResetAlarmStateEvent());
  }


  Future<void> editAlarm(
      int id, {
        required String? label,
        required String? music,
        required int minutesSinceMidnight,
        required int isActive, // 0 or 1 from the card
        required List<String> selectedDays,
        String? notificationKey,
      }) async {
    try {
      final key = notificationKey ?? id.toString();

      // Cancel old notification
      await _notifier.cancelAlarm(int.parse(key));

      // Prepare updated data for DB
      final updatedData = {
        'minutesSinceMidnight': minutesSinceMidnight,
        'isActive': isActive, // directly from card
        'label': label?.isEmpty ?? true ? null : label,
        'days': selectedDays.isEmpty ? null : selectedDays.join(','),
        'music': music,
        'notificationKey': key,
      };

      // Update DB
      await AlarmDatabase.instance.update(id, updatedData);
      log('[AlarmsBloc] ✏️ Alarm updated with ID: $id, data: $updatedData');

      // Re-schedule notification
      final time = minutesSinceMidnightToTime(minutesSinceMidnight);
      final hour = time['hour']!;
      final minute = time['minute']!;
      final labelToUse = label?.isEmpty ?? true ? 'Alarm' : label!;

      if (selectedDays.isEmpty || isActive == 0) {
        if (isActive == 1) {
          final now = DateTime.now();
          final next = DateTime(now.year, now.month, now.day, hour, minute);
          final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;

          await _notifier.scheduleOneTimeAlarm(
            id: int.parse(key),
            dateTime: target,
            label: labelToUse, musicPath: state.music,
          );
          log('[AlarmsBloc] 🔁 Re-scheduled one-time alarm');
        } else {
          log('[AlarmsBloc] Alarm inactive, skipping schedule');
        }
      } else {
        await _notifier.scheduleRepeatingAlarm(
          id: int.parse(key),
          label: labelToUse,
          hour: hour,
          minute: minute,
          weekdays: selectedDays, musicPath: state.music,
        );
        log('[AlarmsBloc] 🔁 Re-scheduled repeating alarm');
      }
    } catch (e) {
      log('[AlarmsBloc] ❌ Error editing alarm: $e');
    }

    add(ResetAlarmStateEvent());
  }




  /// Delete alarm from DB and cancel its notification
  Future<void> _onDeleteAlarm(DeleteAlarmEvent event, Emitter<AlarmsState> emit) async {
    int? notificationIdFromDb;
    final alarmId = event.id;

    try {
      // 1. Attempt to read the alarm data. This can fail if the alarm was already deleted.
      final alarm = await AlarmDatabase.instance.read(alarmId);

      if (alarm != null) {
        final notificationKeyString = alarm['notificationKey'];
        notificationIdFromDb = int.tryParse(notificationKeyString ?? '');
      }

      // 2. Cancellation Attempt
      // Use the notification ID from DB if available, otherwise, use the primary alarm ID
      // as a fail-safe, since Awesome Notifications IDs are often mapped directly to DB IDs.
      final idToCancel = notificationIdFromDb ?? alarmId;

      log('[AlarmsBloc] Cancelling notification with ID $idToCancel (DB ID: $alarmId, Found in DB: ${alarm != null})');

      // The cancelAlarm method in the controller is already fixed to handle
      // dismissing a displayed notification and stopping the audio.
      await _notifier.cancelAlarm(idToCancel);

      if (alarm == null) {
        log('[AlarmsBloc] ⚠️ Warning: Alarm ID $alarmId not found in database for read attempt, but cancellation was attempted using ID $idToCancel.');
      }


      // 3. Delete the alarm from the database (harmless if already gone)
      await AlarmDatabase.instance.delete(alarmId);
      log('[AlarmsBloc] 🗑️ Alarm deleted with ID: $alarmId');

    } catch (e) {
      log('[AlarmsBloc] ❌ Error deleting alarm ID $alarmId: $e');
    }

    add(ResetAlarmStateEvent());
  }


// File: alarms_bloc.dart (Inside AlarmsBloc class)

  void _onToggleAlarmActive(
      ToggleAlarmActiveEvent event,
      Emitter<AlarmsState> emit,
      ) async {
    try {
      // 1. Read existing alarm data from DB
      final alarm = await AlarmDatabase.instance.read(event.alarmId);
      if (alarm == null) {
        log('[AlarmsBloc] ❌ Alarm ID ${event.alarmId} not found for toggling.');
        return;
      }

      // 2. Update the isActive status in the database
      await AlarmDatabase.instance.update(event.alarmId, {
        'isActive': event.isActive ? 1 : 0,
      });
      log('[AlarmsBloc] Toggled alarm ${event.alarmId} to active: ${event.isActive}');

      // 3. Schedule or cancel the notification (Your existing logic)
      final minutes = alarm['minutesSinceMidnight'] as int;
      final time = minutesSinceMidnightToTime(minutes);
      final hour = time['hour']!;
      final minute = time['minute']!;
      final label = alarm['label'] ?? 'Alarm';
      final music = alarm['music'] ?? 'songs/alarm.mp3';
      final selectedDays = (alarm['days'] as String?)?.split(',')?.map((d) => d.trim()).where((d) => d.isNotEmpty).toList() ?? [];
      final notifier = AlarmNotificationController();

      if (event.isActive) {
        // Logic to schedule one-time or repeating alarm...
        if (selectedDays.isEmpty) {
          final now = DateTime.now();
          final next = DateTime(now.year, now.month, now.day, hour, minute);
          final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;
          await notifier.scheduleOneTimeAlarm(
            id: event.alarmId,
            dateTime: target,
            label: label,
            musicPath: music,
          );
        } else {
          await notifier.scheduleRepeatingAlarm(
            id: event.alarmId,
            label: label,
            hour: hour,
            minute: minute,
            weekdays: selectedDays,
            musicPath: music,
          );
        }
        log('[AlarmsBloc] 🔔 Alarm rescheduled/activated.');
      } else {
        // Cancel logic...
        await notifier.cancelAlarm(event.alarmId);
        log('[AlarmsBloc] 🔕 Alarm cancelled/deactivated.');
      }

    } catch (e) {
      log('[AlarmsBloc] ❌ Error toggling alarm active: $e');
    }

    // ➡️ SIGNAL COMPLETION
    event.completer?.complete();
  }
}

// --- Utility functions for conversion ---

/// Converts hour/minute → minutes since midnight
int timeToMinutesSinceMidnight(int hour, int minute) => hour * 60 + minute;

/// Converts minutes since midnight → hour/minute
Map<String, int> minutesSinceMidnightToTime(int totalMinutes) {
  int hour = totalMinutes ~/ 60;
  int minute = totalMinutes % 60;
  return {'hour': hour, 'minute': minute};
}

