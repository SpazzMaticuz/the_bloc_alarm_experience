import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../global_values/global_values.dart';
import '../../main.dart';
import '../../splash_screen/stop_overlay.dart';
import '/modes/app_lifecycle.dart';
import 'package:flutter/material.dart';

part 'timer_event.dart';
part 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  static const int _tickDuration = 1; // Tick interval in seconds
  Timer? _timer; // Internal periodic timer
  int _currentDuration = 0; // Tracks current remaining seconds

  TimerBloc(int initialDuration) : super(TimerInitial(initialDuration)) {
    on<StartTimer>(_onStarted);
    on<TickedTimer>(_onTicked);
    on<ResetTimer>(_onReset);
    on<StopTimer>(_onStopped);
    on<PlayAlarm>(_onPlayAlarm);
    on<StopAlarm>(_onStopAlarm);
  }

  /// Starts the countdown timer
  void _onStarted(StartTimer event, Emitter<TimerState> emit) async {
    _timer?.cancel();
    emit(TimerRunInProgress(event.duration));

    final uniqueTimerId = event.timerId;

    _timer = Timer.periodic(const Duration(seconds: _tickDuration), (timer) {
      final duration = state.duration - _tickDuration;

      if (duration >= 0) {
        add(TickedTimer(duration)); // Update timer every tick
      } else {
        timer.cancel(); // Stop timer when finished

        final isForeground = AppLifecycleObserver().isInForeground;

        if (isForeground) {
          // App is in foreground: navigate to StopOverlay
          AwesomeNotifications().cancel(uniqueTimerId);
          add(StopTimer());
          add(PlayAlarm());

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => StopOverlay(
                onStopPressed: () async {
                  await globalAudioPlayer.stop();
                  AwesomeNotifications().cancel(uniqueTimerId);
                },
              ),
            ),
          );
        } else {
          // App in background: send notification
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: uniqueTimerId,
              channelKey: 'timer_channel',
              title: 'Timer Done',
              body: 'Your countdown has finished!',
              notificationLayout: NotificationLayout.Default,
              autoDismissible: false,
              payload: {'timer_id': uniqueTimerId.toString()},
            ),
            actionButtons: [
              NotificationActionButton(
                key: 'STOP',
                label: 'Stop',
                autoDismissible: false,
              )
            ],
          );
          add(StopTimer());
          add(PlayAlarm());
        }
      }
    });
  }

  /// Updates the state with new remaining time each tick
  void _onTicked(TickedTimer event, Emitter<TimerState> emit) {
    _currentDuration = event.duration;
    emit(TimerRunInProgress(event.duration));
  }

  /// Stops the timer and keeps the current duration for potential restart
  void _onStopped(StopTimer event, Emitter<TimerState> emit) async {
    _timer?.cancel();
    emit(TimerInitial(_currentDuration));
  }

  /// Plays the alarm sound in loop
  void _onPlayAlarm(PlayAlarm event, Emitter<TimerState> emit) async {
    await globalAudioPlayer.setReleaseMode(ReleaseMode.loop);
    await globalAudioPlayer.setVolume(1.0);
    await globalAudioPlayer.play(AssetSource('songs/alarm.mp3'));
  }

  /// Stops the alarm sound and dismisses notifications
  void _onStopAlarm(StopAlarm event, Emitter<TimerState> emit) async {
    await globalAudioPlayer.stop();
    AwesomeNotifications().dismissAllNotifications();
  }

  /// Resets the timer to the initial duration
  void _onReset(ResetTimer event, Emitter<TimerState> emit) {
    _timer?.cancel();
    emit(TimerInitial(event.initTime));
  }

  /// Cancel timer when bloc is closed to avoid memory leaks
  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
