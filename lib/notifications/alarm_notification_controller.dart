import 'dart:async';
import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/alarm_database.dart';
import '../global_values/global_values.dart';
import '../main.dart';
import '../splash_screen/random_stop_overlay.dart';

class AlarmNotificationController {
  // Singleton instance
  static final AlarmNotificationController _instance = AlarmNotificationController._internal();
  factory AlarmNotificationController() => _instance;
  AlarmNotificationController._internal();

  final AwesomeNotifications _notifications = AwesomeNotifications();

  // Current active alarm audio player
  static AudioPlayer? _currentAlarmPlayer;

  // Tracks active overlays to prevent duplicates
  static final Set<int> _activeOverlays = {};

  // --- Audio control ---

  // Play alarm sound in loop
  @pragma('vm:entry-point')
  static Future<void> _playAlarmSound(String musicPath) async {
    try {
      await _currentAlarmPlayer?.dispose();
      _currentAlarmPlayer = AudioPlayer();
      await _currentAlarmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _currentAlarmPlayer!.setVolume(1.0);
      await _currentAlarmPlayer!.play(AssetSource(musicPath));
    } catch (e) {
      // Keep log if audio fails
      log('[AlarmNotifications] Error playing audio: $e');
    }
  }

  // Stop alarm audio and dismiss notification
  @pragma('vm:entry-point')
  static Future<void> _stopAlarmAndDismiss(int? id) async {
    await _currentAlarmPlayer?.stop();
    await _currentAlarmPlayer?.dispose();
    _currentAlarmPlayer = null;

    if (id != null) await AwesomeNotifications().dismiss(id);
  }

  // --- Notification setup ---

  // Initialize notification channels for timers and alarms
  static Future<void> initializeChannels() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AwesomeNotifications().initialize(
      null,
      [
        // Timer channel (no sound)
        NotificationChannel(
          channelKey: 'timer_channel',
          channelName: 'Timer Notifications',
          channelDescription: 'Notification channel for timer alerts',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: false,
        ),
        // Alarm channel (sound, vibration, full-screen)
        NotificationChannel(
          channelKey: 'alarm_channel',
          channelName: 'Alarm Notifications',
          channelDescription: 'Notification channel for scheduled alarms',
          defaultColor: Colors.redAccent,
          ledColor: Colors.red,
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          criticalAlerts: true,
        ),
      ],
    );
  }

  // Attach listeners for notification events
  Future<void> initialize() async {
    await _notifications.setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationDisplayedMethod: onDisplayed,
      onNotificationCreatedMethod: onCreated,
      onDismissActionReceivedMethod: onDismissed,
    );
  }

  // Called when a notification is created
  @pragma('vm:entry-point')
  static Future<void> onCreated(ReceivedNotification notification) async {}

  // Called when notification appears on screen
  @pragma('vm:entry-point')
  static Future<void> onDisplayed(ReceivedNotification notification) async {
    final id = notification.id;
    final channel = notification.channelKey;

    // Skip timer notifications
    if (channel == 'timer_channel') return;

    // Alarm notification: play sound and show overlay
    if (channel == 'alarm_channel') {
      final musicPath = notification.payload?['musicPath'];
      if (musicPath != null) await _playAlarmSound(musicPath);

      // Prevent duplicate overlays
      if (!_activeOverlays.contains(id)) {
        _activeOverlays.add(id!);

        // Open overlay for stopping alarm
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => RandomStopOverlay(
                  onStopPressed: () async {
                    await _stopAlarmAndDismiss(id);
                    _activeOverlays.remove(id);
                  },
                ),
              ),
            );
          } catch (e) {
            // Keep log if overlay fails
            log('[AlarmNotifications] Failed to open overlay: $e');
            _activeOverlays.remove(id);
          }
        });
      }
    }
  }

  // Called when notification is dismissed
  @pragma('vm:entry-point')
  static Future<void> onDismissed(ReceivedAction action) async {}

  // Handles button presses or notification taps
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final id = action.id;
    final channel = action.channelKey;

    // Timer action: stop audio and dismiss
    if (channel == 'timer_channel') {
      try {
        await globalAudioPlayer.stop();
      } catch (_) {}
      if (id != null) await AwesomeNotifications().dismiss(id);
      return;
    }

    // Alarm action: open overlay if not already active
    if (channel == 'alarm_channel') {
      if (!_activeOverlays.contains(id)) {
        _activeOverlays.add(id!);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => RandomStopOverlay(
                  onStopPressed: () async {
                    await _stopAlarmAndDismiss(id);
                    _activeOverlays.remove(id);
                  },
                ),
              ),
            );
          } catch (e) {
            log('[AlarmNotifications] Failed to open overlay: $e');
            _activeOverlays.remove(id);
          }
        });
      }
    }
  }

  // --- Alarm scheduling ---

  // One-time alarm
  Future<void> scheduleOneTimeAlarm({
    required int id,
    required DateTime dateTime,
    required String label,
    required String musicPath,
  }) async {
    if (dateTime.isBefore(DateTime.now())) return;

    await _notifications.createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alarm_channel',
        title: '⏰ $label',
        body: 'Your alarm is ringing.',
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        payload: {'musicPath': musicPath, 'isAlarm': 'true'},
      ),
      schedule: NotificationCalendar(
        hour: dateTime.hour,
        minute: dateTime.minute,
        second: 0,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  // Repeating alarm using weekdays
  Future<void> scheduleRepeatingAlarm({
    required int id,
    required String label,
    required int hour,
    required int minute,
    required List<String> weekdays,
    required String musicPath,
  }) async {
    final tz = await _notifications.getLocalTimeZoneIdentifier();
    final cron = '0 $minute $hour ? * ${weekdays.join(',')} *';

    await _notifications.createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alarm_channel',
        title: '⏰ $label',
        body: 'It\'s time.',
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        payload: {'musicPath': musicPath, 'isAlarm': 'true'},
      ),
      schedule: NotificationAndroidCrontab(
        crontabExpression: cron,
        timeZone: tz,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  // Cancel a specific alarm
  Future<void> cancelAlarm(int id) async {
    await _notifications.dismiss(id);
    await _notifications.cancel(id);
    await _stopAlarmAndDismiss(null);
  }

  // Cancel all alarms
  Future<void> cancelAllAlarms() async {
    await _notifications.cancelNotificationsByChannelKey('alarm_channel');
  }

  // Load alarms from DB and schedule them
  Future<void> createFromDatabase() async {
    final db = await AlarmDatabase.instance.readAll();

    for (var alarm in db) {
      final id = alarm['id'] as int;
      final label = alarm['label'] ?? 'Alarm';
      final isActive = (alarm['isActive'] ?? 1) == 1;
      final minutes = alarm['minutesSinceMidnight'] as int;
      if (!isActive) continue;

      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      final music = alarm['music'] ?? 'songs/alarm.mp3';
      final daysString = alarm['days'] ?? '';

      // One-time alarm if no weekdays set
      if (daysString.isEmpty) {
        final now = DateTime.now();
        final next = DateTime(now.year, now.month, now.day, hour, minute);
        final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;
        await scheduleOneTimeAlarm(id: id, dateTime: target, label: label, musicPath: music);
      } else {
        // Repeating alarm
        final days = daysString.split(',');
        await scheduleRepeatingAlarm(id: id, label: label, hour: hour, minute: minute, weekdays: days, musicPath: music);
      }
    }
  }
}
