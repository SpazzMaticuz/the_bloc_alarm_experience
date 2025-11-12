import 'dart:developer'; // For logging
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // For cancelling notifications
// ⭐ NEW: Import the TimerDatabase class
import '../../database/timer_database.dart';

part 'timer_cubic_state.dart';


class TimerCubicCubit extends Cubit<TimerCubicState> {

  // ⭐ UPDATED: Initialize and load existing timers immediately
  TimerCubicCubit() : super(TimerCubicInitial()) {
    _loadTimers();
  }

  // Helper to get the current list of TimerData from the state
  List<TimerData> get _currentTimers {
    return switch (state) {
      TimerCubicListUpdated(:final timers) => timers,
      _ => const <TimerData>[],
    };
  }

  // --- Database Loading ---
  Future<void> _loadTimers() async {
    final dbData = await TimerDatabase.instance.readAll();

    // Convert database maps into TimerData objects
    final loadedTimers = dbData.map((map) {
      return TimerData(
        id: map['id'] as int,
        initialDuration: map['durationSeconds'] as int,
      );
    }).toList();

    emit(TimerCubicListUpdated(loadedTimers));
    log('TimerCubit: Loaded ${loadedTimers.length} timers from DB.');
  }

  // --- Add Timer (Create) ---
  Future<void> addTimer(int durationSeconds) async {
    if (durationSeconds <= 0) {
      log('TimerCubit: Cannot add timer with non-positive duration.');
      return;
    }

    // ⭐ 1. Insert into DB and get the unique ID
    final id = await TimerDatabase.instance.create(durationSeconds);

    // 2. Create the new model object
    final newTimer = TimerData(id: id, initialDuration: durationSeconds);

    // 3. Update the state
    final updatedList = List<TimerData>.from(_currentTimers)..add(newTimer);
    emit(TimerCubicListUpdated(updatedList));

    log('TimerCubit: Added new timer with ID: $id');
  }

  // --- Remove Timer (Delete) ---
  Future<void> removeTimerAt(int index) async {
    if (index < 0 || index >= _currentTimers.length) {
      log('TimerCubit: Invalid index for removal: $index');
      return;
    }

    final timerToRemove = _currentTimers[index];

    // ⭐ 1. Delete from DB
    await TimerDatabase.instance.delete(timerToRemove.id);

    // ⭐ 2. Cancel the associated notification (using the unique ID)
    await AwesomeNotifications().cancel(timerToRemove.id);

    // 3. Remove from the local list and update state
    final updatedList = List<TimerData>.from(_currentTimers)..removeAt(index);
    emit(TimerCubicListUpdated(updatedList));

    log('TimerCubit: Removed timer with ID: ${timerToRemove.id}');
  }

  // ⭐ UPDATED: Getter to return the list of TimerData
  List<TimerData> get currentTimers => List.unmodifiable(_currentTimers);
}