import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/alarm_database.dart';
import '../../notifications/alarm_notification_controller.dart';

part 'alarms_event.dart';
part 'alarms_state.dart';

/// BLoC responsible for managing alarms:
/// - Tracks UI state (popup view, selected days, label, music, etc.)
/// - Handles CRUD operations (create, edit, delete)
/// - Manages alarm notifications (one-time and repeating)
class AlarmsBloc extends Bloc<AlarmsEvent, AlarmsState> {
  final AlarmNotificationController _notifier = AlarmNotificationController();

  AlarmsBloc() : super(AlarmsState.initial()) {
    // UI-related events
    on<ChangeViewEvent>(_onChangeView);
    on<ToggleDayEvent>(_onToggleDay);
    on<UpdateLabelEvent>(_onUpdateLabel);
    on<UpdateMusicEvent>(_onUpdateMusic);
    on<TimeUpdatedEvent>(_onTimeUpdated);
    on<ResetAlarmStateEvent>(_onResetAlarmState);

    // CRUD-related events
    on<DeleteAlarmEvent>(_onDeleteAlarm);
    on<AlarmPreloadedEvent>(_onAlarmPreloaded);

    // Toggle alarm active/inactive
    on<ToggleAlarmActiveEvent>(_onToggleAlarmActive);
  }

  // -------------------------
  // UI Event Handlers
  // -------------------------

  void _onChangeView(ChangeViewEvent event, Emitter<AlarmsState> emit) {
    emit(state.copyWith(currentView: event.newView));
  }

  void _onToggleDay(ToggleDayEvent event, Emitter<AlarmsState> emit) {
    final updatedDays = List<String>.from(state.selectedDays);
    if (updatedDays.contains(event.day)) {
      updatedDays.remove(event.day);
    } else {
      updatedDays.add(event.day);
    }
    emit(state.copyWith(selectedDays: updatedDays));
  }

  void _onUpdateLabel(UpdateLabelEvent event, Emitter<AlarmsState> emit) {
    emit(state.copyWith(labelText: event.label));
  }

  void _onUpdateMusic(UpdateMusicEvent event, Emitter<AlarmsState> emit) {
    emit(state.copyWith(music: event.musicPath));
  }

  void _onTimeUpdated(TimeUpdatedEvent event, Emitter<AlarmsState> emit) {
    emit(state.copyWith(minutesSinceMidnight: event.minutesSinceMidnight));
  }

  void _onResetAlarmState(ResetAlarmStateEvent event, Emitter<AlarmsState> emit) {
    emit(AlarmsState.initial());
  }

  void _onAlarmPreloaded(AlarmPreloadedEvent event, Emitter<AlarmsState> emit) {
    // Preload alarm values into the state before editing
    emit(state.copyWith(
      minutesSinceMidnight: event.minutesSinceMidnight,
      labelText: event.labelText,
      isActive: event.isActive,
      music: event.music,
      selectedDays: event.selectedDays,
    ));
  }

  // -------------------------
  // CRUD & Notification Logic
  // -------------------------

  /// Saves a new alarm to the database and schedules notifications
  Future<void> saveAlarm() async {
    if (state.minutesSinceMidnight == null) return;

    final alarmData = {
      'minutesSinceMidnight': state.minutesSinceMidnight!,
      'isActive': state.isActive,
      'label': state.labelText.isEmpty ? null : state.labelText,
      'days': state.selectedDays.isEmpty ? null : state.selectedDays.join(','),
      'music': state.music,
    };

    try {
      final id = await AlarmDatabase.instance.create(alarmData);
      await AlarmDatabase.instance.update(id, {'notificationKey': id.toString()});

      // Convert minutesSinceMidnight to hour/minute
      final time = minutesSinceMidnightToTime(state.minutesSinceMidnight!);
      final hour = time['hour']!;
      final minute = time['minute']!;
      final label = state.labelText.isEmpty ? 'Alarm' : state.labelText;

      // Schedule notification
      if (state.selectedDays.isEmpty) {
        final now = DateTime.now();
        final next = DateTime(now.year, now.month, now.day, hour, minute);
        final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;
        await _notifier.scheduleOneTimeAlarm(
          id: id,
          dateTime: target,
          label: label,
          musicPath: state.music,
        );
      } else {
        await _notifier.scheduleRepeatingAlarm(
          id: id,
          label: label,
          hour: hour,
          minute: minute,
          weekdays: state.selectedDays,
          musicPath: state.music,
        );
      }
    } catch (e) {
      // Only log errors
      log('Error saving alarm: $e');
    }

    add(ResetAlarmStateEvent());
  }

  /// Edits an existing alarm and updates notifications
  Future<void> editAlarm(
      int id, {
        required String? label,
        required String? music,
        required int minutesSinceMidnight,
        required int isActive,
        required List<String> selectedDays,
        String? notificationKey,
      }) async {
    try {
      final key = notificationKey ?? id.toString();
      await _notifier.cancelAlarm(int.parse(key));

      final updatedData = {
        'minutesSinceMidnight': minutesSinceMidnight,
        'isActive': isActive,
        'label': label?.isEmpty ?? true ? null : label,
        'days': selectedDays.isEmpty ? null : selectedDays.join(','),
        'music': music,
        'notificationKey': key,
      };

      await AlarmDatabase.instance.update(id, updatedData);

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
            label: labelToUse,
            musicPath: state.music,
          );
        }
      } else {
        await _notifier.scheduleRepeatingAlarm(
          id: int.parse(key),
          label: labelToUse,
          hour: hour,
          minute: minute,
          weekdays: selectedDays,
          musicPath: state.music,
        );
      }
    } catch (e) {
      log('Error editing alarm: $e');
    }

    add(ResetAlarmStateEvent());
  }

  /// Deletes an alarm and cancels its notification
  Future<void> _onDeleteAlarm(DeleteAlarmEvent event, Emitter<AlarmsState> emit) async {
    try {
      final alarm = await AlarmDatabase.instance.read(event.id);
      final idToCancel = alarm != null ? int.tryParse(alarm['notificationKey'] ?? '') ?? event.id : event.id;
      await _notifier.cancelAlarm(idToCancel);
      await AlarmDatabase.instance.delete(event.id);
    } catch (e) {
      log('Error deleting alarm ID ${event.id}: $e');
    }

    add(ResetAlarmStateEvent());
  }

  /// Toggle alarm active/inactive and reschedule notifications
  void _onToggleAlarmActive(
      ToggleAlarmActiveEvent event,
      Emitter<AlarmsState> emit,
      ) async {
    try {
      final alarm = await AlarmDatabase.instance.read(event.alarmId);
      if (alarm == null) return;

      await AlarmDatabase.instance.update(event.alarmId, {
        'isActive': event.isActive ? 1 : 0,
      });

      final minutes = alarm['minutesSinceMidnight'] as int;
      final time = minutesSinceMidnightToTime(minutes);
      final hour = time['hour']!;
      final minute = time['minute']!;
      final label = alarm['label'] ?? 'Alarm';
      final music = alarm['music'] ?? 'songs/alarm.mp3';
      final selectedDays = (alarm['days'] as String?)
          ?.split(',')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList() ??
          [];
      final notifier = AlarmNotificationController();

      if (event.isActive) {
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
      } else {
        await notifier.cancelAlarm(event.alarmId);
      }
    } catch (e) {
      log('Error toggling alarm active: $e');
    }

    event.completer?.complete();
  }
}

// -------------------------
// Helper functions
// -------------------------

/// Converts hour/minute to total minutes since midnight
int timeToMinutesSinceMidnight(int hour, int minute) => hour * 60 + minute;

/// Converts total minutes since midnight to hour and minute
Map<String, int> minutesSinceMidnightToTime(int totalMinutes) {
  int hour = totalMinutes ~/ 60;
  int minute = totalMinutes % 60;
  return {'hour': hour, 'minute': minute};
}
