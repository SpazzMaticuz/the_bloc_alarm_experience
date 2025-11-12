import 'dart:async';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
// Assuming globalAudioPlayer is defined here via global_values.dart
import '../../global_values/global_values.dart';
import '../../main.dart';
import '../../splash_screen/stop_overlay.dart';
import '/modes/app_lifecycle.dart';
import 'package:flutter/material.dart';

part 'timer_event.dart';
part 'timer_state.dart';


// Assuming globalAudioPlayer is defined in global_values.dart and is accessible.
// final AudioPlayer globalAudioPlayer = AudioPlayer(); // This should be in global_values.dart


class TimerBloc extends Bloc<TimerEvent, TimerState> {
  static const int _tickDuration = 1;
  Timer? _timer;
  int _currentDuration = 0;

  TimerBloc(int initialDuration) : super(TimerInitial(initialDuration)) {
    on<StartTimer>(_onStarted);
    on<TickedTimer>(_onTicked);
    on<ResetTimer>(_onReset);
    on<StopTimer>(_onStopped);
    on<PlayAlarm>(_onPlayAlarm);
    on<StopAlarm>(_onStopAlarm);
  }


  void _onStarted(StartTimer event, Emitter<TimerState> emit) async{
    _timer?.cancel();
    emit(TimerRunInProgress(event.duration));

    // ⭐ Get the unique ID from the event
    final uniqueTimerId = event.timerId;

    _timer = Timer.periodic(const Duration(seconds: _tickDuration), (timer) {
      final duration = state.duration - _tickDuration;
      if (duration >= 0) {
        add(TickedTimer(duration));
      }
      else {
        timer.cancel();

        final isForeground = AppLifecycleObserver().isInForeground;

        if (isForeground) {
          // ✅ App is open: navigate to StopOverlay
          // Dismiss only the specific notification if it exists
          AwesomeNotifications().cancel(uniqueTimerId);
          add(StopTimer());
          add(PlayAlarm());

          // Use navigator to open the overlay
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => StopOverlay(
                onStopPressed: () async {
                  // This StopOverlay button is only for the foreground case
                  await globalAudioPlayer.stop(); // stop alarm sound
                  AwesomeNotifications().cancel(uniqueTimerId); // Dismiss the specific notification
                },
              ),
            ),
          );

        } else {
          // 🔔 App is background: show notification
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              // ⭐ CRITICAL FIX: Use the unique ID here!
              id: uniqueTimerId,
              channelKey: 'timer_channel',
              title: 'Timer Done',
              body: 'Your countdown has finished!',
              notificationLayout: NotificationLayout.Default,
              autoDismissible: false,
              payload: {'timer_id': uniqueTimerId.toString()}, // Pass ID in payload
            ),
            actionButtons: [
              NotificationActionButton(
                key: 'STOP',
                label: 'Stop',
                // autoDismissible: true, // Should be false if you want the handler to manually stop the sound
                autoDismissible: false,
              )
            ],
          );
          add(StopTimer());
          add(PlayAlarm()); // Starts the alarm sound in the background isolate
        }}
    });}


  void _onTicked(TickedTimer event, Emitter<TimerState> emit) {
    _currentDuration = event.duration;
    emit(TimerRunInProgress(event.duration));
  }

// ⭐ UPDATED: Only cancels timer and resets state. Alarm sound logic is moved.
  void _onStopped(StopTimer event, Emitter<TimerState> emit) async {
    _timer?.cancel();
    emit(TimerInitial(_currentDuration));
  }

  // ⭐ NEW HANDLER: Plays the alarm sound.
  void _onPlayAlarm(PlayAlarm event, Emitter<TimerState> emit) async {
    await globalAudioPlayer.setReleaseMode(ReleaseMode.loop);
    await globalAudioPlayer.setVolume(1.0);
    await globalAudioPlayer.play(AssetSource('songs/alarm.mp3'));
    log('Timer Alarm Sound Started');
  }

  // ⭐ NEW HANDLER: Stops the alarm sound and dismisses notification.
  void _onStopAlarm(StopAlarm event, Emitter<TimerState> emit) async {
    await globalAudioPlayer.stop();
    // In a multi-timer environment, we cannot dismiss ALL notifications here
    // without knowing the ID. This handler is mostly used by the foreground
    // StopOverlay, which should use its own ID-aware dismissal if needed.
    // For now, keep the general dismiss as a fallback, but a targeted cancel is safer.
    AwesomeNotifications().dismissAllNotifications();
    log('Timer Alarm Sound Stopped via event');
  }

  void _onReset(ResetTimer event, Emitter<TimerState> emit) {
    _timer?.cancel();
    emit(TimerInitial(event.initTime));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

