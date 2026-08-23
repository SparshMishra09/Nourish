import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import '../models/user_profile.dart';

class NotificationScheduleResult {
  const NotificationScheduleResult({
    required this.notificationsAllowed,
    required this.exactTiming,
  });

  final bool notificationsAllowed;
  final bool exactTiming;
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const _alarmBaseId = 4100;
  static const _advanceBaseId = 4200;
  static const _testId = 4300;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // The device clock is still used by in-app labels if its zone cannot be
      // resolved. UTC is a safe scheduler fallback instead of failing startup.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_nourish'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<NotificationScheduleResult> scheduleWorkoutReminders({
    required UserProfile profile,
    required ReminderSettings settings,
    bool requestPermissions = false,
  }) async {
    await initialize();
    await _cancelWorkoutReminders();
    if (!settings.anyEnabled) {
      return const NotificationScheduleResult(
        notificationsAllowed: true,
        exactTiming: false,
      );
    }

    var notificationsAllowed = true;
    var exactTiming = false;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (requestPermissions) {
        notificationsAllowed =
            await android?.requestNotificationsPermission() ?? true;
        if (notificationsAllowed && settings.alarmEnabled) {
          exactTiming = await android?.requestExactAlarmsPermission() ?? true;
        }
      } else {
        notificationsAllowed = await android?.areNotificationsEnabled() ?? true;
        exactTiming = await android?.canScheduleExactNotifications() ?? false;
      }
    }

    if (!notificationsAllowed) {
      return const NotificationScheduleResult(
        notificationsAllowed: false,
        exactTiming: false,
      );
    }

    final mode = exactTiming
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final firstName = profile.name.trim().split(RegExp(r'\s+')).first;
    final days = profile.availableWorkoutDays
        .map(_weekdayForLabel)
        .whereType<int>()
        .toSet();

    for (final weekday in days) {
      if (settings.alarmEnabled) {
        final scheduled = _nextWeekdayTime(
          weekday,
          settings.hour,
          settings.minute,
        );
        await _plugin.zonedSchedule(
          id: _alarmBaseId + weekday,
          title: 'It’s workout time, $firstName 💪',
          body:
              'Your ${profile.sessionMinutes}-minute Nourish session is ready. Let’s get moving.',
          scheduledDate: scheduled,
          notificationDetails: _details(
            channelId: 'nourish_workout_alarm',
            channelName: 'Workout alarms',
            channelDescription: 'Alerts at your chosen workout time',
          ),
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'workout',
        );
      }

      if (settings.advanceEnabled) {
        final workoutTime = _nextWeekdayTime(
          weekday,
          settings.hour,
          settings.minute,
        );
        var scheduled = workoutTime.subtract(
          Duration(minutes: settings.advanceMinutes),
        );
        if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
          scheduled = scheduled.add(const Duration(days: 7));
        }
        await _plugin.zonedSchedule(
          id: _advanceBaseId + weekday,
          title: 'Workout in ${settings.advanceMinutes} minutes',
          body: 'Hydrate, clear a little space, and get ready to feel good.',
          scheduledDate: scheduled,
          notificationDetails: _details(
            channelId: 'nourish_workout_reminders',
            channelName: 'Workout reminders',
            channelDescription: 'Gentle reminders before scheduled workouts',
            alarmLike: false,
          ),
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'workout',
        );
      }
    }

    return NotificationScheduleResult(
      notificationsAllowed: true,
      exactTiming: exactTiming,
    );
  }

  Future<bool> showTestNotification() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final allowed = await android?.requestNotificationsPermission() ?? true;
      if (!allowed) return false;
    }
    await _plugin.show(
      id: _testId,
      title: 'Nourish reminders are ready 🌿',
      body: 'Your workout alerts will look just like this.',
      notificationDetails: _details(
        channelId: 'nourish_workout_reminders',
        channelName: 'Workout reminders',
        channelDescription: 'Gentle reminders before scheduled workouts',
        alarmLike: false,
      ),
      payload: 'reminders',
    );
    return true;
  }

  Future<void> _cancelWorkoutReminders() async {
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(id: _alarmBaseId + weekday);
      await _plugin.cancel(id: _advanceBaseId + weekday);
    }
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDescription,
    bool alarmLike = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        icon: 'ic_stat_nourish',
        largeIcon: const DrawableResourceAndroidBitmap('nourish_logo'),
        color: const Color(0xFFB9F227),
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        category: alarmLike ? AndroidNotificationCategory.alarm : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int? _weekdayForLabel(String label) => switch (label.toUpperCase()) {
    'MON' => DateTime.monday,
    'TUE' => DateTime.tuesday,
    'WED' => DateTime.wednesday,
    'THU' => DateTime.thursday,
    'FRI' => DateTime.friday,
    'SAT' => DateTime.saturday,
    'SUN' => DateTime.sunday,
    _ => null,
  };
}
