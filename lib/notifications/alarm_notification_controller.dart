import 'dart:async';
import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart'; // Import AudioPlayers
import '../database/alarm_database.dart';
import '../global_values/global_values.dart';
import '../main.dart';
import '../splash_screen/random_stop_overlay.dart';
// Removed: import '../global_values/global_values.dart';

class AlarmNotificationController {
  static final AlarmNotificationController _instance = AlarmNotificationController._internal();
  factory AlarmNotificationController() => _instance;
  AlarmNotificationController._internal();

  final AwesomeNotifications _notifications = AwesomeNotifications();

  // ✅ FIX: Internal static manager for the AudioPlayer instance
  // This replaces the external globalAudioPlayer and keeps state internal.
  static AudioPlayer? _currentAlarmPlayer;
  static final Set<int> _activeOverlays = {};

  // --- NEW STATIC HELPER: Plays the selected audio in a loop ---
  @pragma('vm:entry-point')
  static Future<void> _playAlarmSound(String musicPath) async {
    log('[AlarmNotifications] Starting audio playback for: $musicPath (Local Player)');
    try {
      // 1. Dispose of any previous player to free resources
      await _currentAlarmPlayer?.dispose();

      // 2. Create a new local instance for the alarm
      _currentAlarmPlayer = AudioPlayer();

      await _currentAlarmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _currentAlarmPlayer!.setVolume(1.0);
      await _currentAlarmPlayer!.play(AssetSource(musicPath));
    } catch (e) {
      log('[AlarmNotifications] Error playing audio in background: $e');
    }
  }

  // --- NEW STATIC HELPER: Stops audio and dismisses notification ---
  @pragma('vm:entry-point')
  static Future<void> _stopAlarmAndDismiss(int? id) async {
    await _currentAlarmPlayer?.stop();
    await _currentAlarmPlayer?.dispose(); // CRITICAL: Dispose the resource
    _currentAlarmPlayer = null; // Clear the reference

    if (id != null) {
      await AwesomeNotifications().dismiss(id);
    }
    log('[AlarmNotifications] Alarm sound stopped and notification dismissed.');
  }

  // --- Static method to register all channels ---
  static Future<void> initializeChannels() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AwesomeNotifications().initialize(
      null,
      [
        // 🔔 Timer channel
        NotificationChannel(
          channelKey: 'timer_channel',
          channelName: 'Timer Notifications',
          channelDescription: 'Notification channel for timer alerts',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: false, // Flutter controls sound via TimerBloc
        ),

        // ⏰ Alarm channel - NO CUSTOM SOUND, Flutter will play via payload
        NotificationChannel(
          channelKey: 'alarm_channel',
          channelName: 'Alarm Notifications',
          channelDescription: 'Notification channel for scheduled alarms',
          defaultColor: Colors.redAccent,
          ledColor: Colors.red,
          importance: NotificationImportance.Max,
          playSound: true, // Use default system sound as a backup, but audio will be played via Flutter
          enableVibration: true,
          criticalAlerts: true,
        ),
      ],
    );
  }

  // --- Initialization (listeners only) ---
  Future<void> initialize() async {
    log('[AlarmNotifications] Initializing listeners...');
    await _notifications.setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationDisplayedMethod: onDisplayed, // <-- We will use this now
      onNotificationCreatedMethod: onCreated,
      onDismissActionReceivedMethod: onDismissed,
    );
  }

  // --- Event listeners ---
  @pragma('vm:entry-point')
  static Future<void> onCreated(ReceivedNotification notification) async {
    log('[AlarmNotifications] Created: ${notification.id}');
  }

  // 🔔 CRITICAL: When the scheduled alarm is displayed (even in background)
  // @pragma('vm:entry-point')
  // static Future<void> onDisplayed(ReceivedNotification notification) async {
  //   log('[AlarmNotifications] Displayed: ${notification.id}');
  //
  //   if (notification.channelKey == 'alarm_channel') {
  //     final musicPath = notification.payload?['musicPath'];
  //
  //     if (musicPath != null) {
  //       log('[AlarmNotifications] Alarm displayed, playing sound from payload: $musicPath');
  //       await _playAlarmSound(musicPath);
  //     } else {
  //       log('[AlarmNotifications] Alarm displayed, but no musicPath found in payload.');
  //     }
  //   }
  // }

  @pragma('vm:entry-point')
  static Future<void> onDisplayed(ReceivedNotification notification) async {
    log('[AlarmNotifications] Displayed: ${notification.id} (${notification.channelKey})');

    final id = notification.id;
    final channel = notification.channelKey;

    // 🕒 Timer notifications: don't play alarm audio
    if (channel == 'timer_channel') {
      log('[AlarmNotifications] Timer notification displayed (id=$id). No sound will be played here.');
      return;
    }

    // ⏰ Alarm notifications
    if (channel == 'alarm_channel') {
      final musicPath = notification.payload?['musicPath'];
      if (musicPath != null) {
        log('[AlarmNotifications] Alarm displayed, playing sound from payload: $musicPath');
        await _playAlarmSound(musicPath);
      }

      // 🔥 If app is in foreground, open RandomStopOverlay directly
      if (!_activeOverlays.contains(id)) {
        _activeOverlays.add(id!);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => RandomStopOverlay(
                  onStopPressed: () async {
                    await _stopAlarmAndDismiss(id);
                    _activeOverlays.remove(id); // allow next alarms again
                  },
                ),
              ),
            );
          } catch (e) {
            log('[AlarmNotifications] ❌ Failed to open RandomStopOverlay: $e');
            _activeOverlays.remove(id);
          }
        });
      } else {
        log('[AlarmNotifications] ⚠️ Overlay for ID $id already active, skipping duplicate.');
      }

    }
  }



  @pragma('vm:entry-point')
  static Future<void> onDismissed(ReceivedAction action) async {
    log('[AlarmNotifications] Dismissed: ${action.id}');
  }


  // @pragma('vm:entry-point')
  // static Future<void> onActionReceivedMethod(ReceivedAction action) async {
  //   await initializeChannels();
  //   log('[AlarmNotifications] Action pressed: ${action.buttonKeyPressed}, Channel: ${action.channelKey}');
  //
  //   final isTimerAction = action.channelKey == 'timer_channel';
  //   final isAlarmAction = action.channelKey == 'alarm_channel';
  //   final isStopButtonPress = action.buttonKeyPressed == 'STOP';
  //
  //   if ((isTimerAction || isAlarmAction) && isStopButtonPress) {
  //     // Handles STOP button for both Timer and Alarm (using audiocontrol)
  //     await _stopAlarmAndDismiss(action.id);
  //   } else if (isAlarmAction) {
  //     // Handles body tap for alarm: stop sound, dismiss notification
  //     await _stopAlarmAndDismiss(action.id);
  //   } else if (isTimerAction) {
  //     // Handles body tap for timer: stop sound, dismiss notification
  //     await _stopAlarmAndDismiss(action.id);
  //     // The TimerBloc will handle navigation after the app opens.
  //   }
  // }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    await initializeChannels();
    final id = action.id;
    final channel = action.channelKey;
    final button = action.buttonKeyPressed;

    log('[AlarmNotifications] Action pressed (id=$id, channel=$channel, button=$button)');

    // 🕒 TIMER CHANNEL HANDLING
    if (channel == 'timer_channel') {
      // ✅ Stop the timer sound (uses global player, not _currentAlarmPlayer)
      try {
        await globalAudioPlayer.stop();
        log('[AlarmNotifications] Timer audio stopped.');
      } catch (e) {
        log('[AlarmNotifications] ❌ Error stopping timer audio: $e');
      }

      // Dismiss this timer notification only
      if (id != null) {
        await AwesomeNotifications().dismiss(id);
      }

      log('[AlarmNotifications] Timer action handled and dismissed (id=$id)');
      return;
    }

    // ⏰ ALARM CHANNEL HANDLING
    if (channel == 'alarm_channel') {
      // ❌ REMOVE THIS LINE — it stops the sound too early
      // await _stopAlarmAndDismiss(id);

      if (!_activeOverlays.contains(id)) {
        _activeOverlays.add(id!);

        log('[AlarmNotifications] Alarm body tapped — opening RandomStopOverlay');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => RandomStopOverlay(
                  onStopPressed: () async {
                    await _stopAlarmAndDismiss(id); // ✅ stop only here
                    _activeOverlays.remove(id);
                  },
                ),
              ),
            );
          } catch (e) {
            log('[AlarmNotifications] ❌ Failed to open RandomStopOverlay: $e');
            _activeOverlays.remove(id);
          }
        });
      } else {
        log('[AlarmNotifications] ⚠️ Overlay for ID $id already active, skipping duplicate.');
      }
    }
  }



  // --- Create one-time alarm ---
  Future<void> scheduleOneTimeAlarm({
    required int id,
    required DateTime dateTime,
    required String label,
    required String musicPath, // Still required to pass to payload
  }) async {
    log('[AlarmNotifications] Scheduling one-time alarm: $label at $dateTime, music: $musicPath');
    if (dateTime.isBefore(DateTime.now())) {
      log('[AlarmNotifications] Skipping past date');
      return;
    }

    // ❌ Removed soundFileName extraction and customSound property
    await _notifications.createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alarm_channel',
        title: '⏰ $label',
        body: 'Your alarm is ringing!',
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        // ✅ CRITICAL: Pass the music path in the payload
        payload: {'musicPath': musicPath, 'isAlarm': 'true'},
      ),
      schedule: NotificationCalendar(
        hour: dateTime.hour,
        minute: dateTime.minute,
        second: 0,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
      // actionButtons: [
      //   NotificationActionButton(
      //     key: 'STOP',
      //     label: 'Stop',
      //     color: Colors.red,
      //   ),
      // ],
    );
  }

  // --- Create repeating alarm ---
  Future<void> scheduleRepeatingAlarm({
    required int id,
    required String label,
    required int hour,
    required int minute,
    required List<String> weekdays,
    required String musicPath, // Still required to pass to payload
  }) async {
    final tz = await _notifications.getLocalTimeZoneIdentifier();
    final days = weekdays.join(',');
    final cron = '0 $minute $hour ? * $days *';

    log('[AlarmNotifications] Scheduling repeating alarm: $label ($cron), music: $musicPath');
    // ❌ Removed soundFileName extraction and customSound property
    await _notifications.createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alarm_channel',
        title: '⏰ $label',
        body: 'It\'s time!',
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        // ✅ CRITICAL: Pass the music path in the payload
        payload: {'musicPath': musicPath, 'isAlarm': 'true'},
      ),
      schedule: NotificationAndroidCrontab(
        crontabExpression: cron,
        timeZone: tz,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
      // actionButtons: [
      //   NotificationActionButton(
      //     key: 'STOP',
      //     label: 'Stop',
      //     color: Colors.red,
      //   ),
      // ],
    );
  }

  // --- Cancel specific alarm ---
  // Future<void> cancelAlarm(int id) async {
  //   log('[AlarmNotifications] Cancel alarm id=$id');
  //   await _notifications.cancel(id);
  // }

  // --- Cancel specific alarm (FIXED LOGIC) ---
  Future<void> cancelAlarm(int id) async {
    log('[AlarmNotifications] Cancel/Dismiss alarm id=$id');

    // 1. Attempt to dismiss the notification (removes it from the display if currently ringing).
    await _notifications.dismiss(id);

    // 2. Attempt to cancel any future schedules.
    await _notifications.cancel(id);

    // 3. CRITICAL: Manually stop the static audio player instance
    // since dismissing via code doesn't always trigger the audio stop listener.
    // We pass null for the ID to _stopAlarmAndDismiss because we already handled dismiss/cancel above.
    await AlarmNotificationController._stopAlarmAndDismiss(null);
    log('[AlarmNotifications] Forced audio stop and dismissal complete for id=$id');
  }

  // --- Cancel all alarms ---
  Future<void> cancelAllAlarms() async {
    log('[AlarmNotifications] Cancel all alarms');
    await _notifications.cancelNotificationsByChannelKey('alarm_channel');
  }

  // --- Load alarms from DB and schedule ---
  Future<void> createFromDatabase() async {
    log('[AlarmNotifications] Creating alarms from DB...');
    final db = await AlarmDatabase.instance.readAll();

    for (var alarm in db) {
      final id = alarm['id'] as int;
      final label = alarm['label'] ?? 'Alarm';
      final isActive = (alarm['isActive'] ?? 1) == 1;
      final minutes = alarm['minutesSinceMidnight'] as int;
      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      final music = alarm['music'] ?? 'songs/alarm.mp3'; // Default sound

      if (!isActive) continue;

      final daysString = alarm['days'] ?? '';
      if (daysString.isEmpty) {
        final now = DateTime.now();
        final next = DateTime(now.year, now.month, now.day, hour, minute);
        final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;

        await scheduleOneTimeAlarm(
          id: id,
          dateTime: target,
          label: label,
          musicPath: music,
        );
      } else {
        final days = daysString.split(',');
        await scheduleRepeatingAlarm(
          id: id,
          label: label,
          hour: hour,
          minute: minute,
          weekdays: days,
          musicPath: music,
        );
      }
    }
  }
}