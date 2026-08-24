import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart' show Color, debugPrint, debugPrintStack;
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
    required this.scheduledCount,
  });

  final bool notificationsAllowed;
  final bool exactTiming;
  final int scheduledCount;
}

class NotificationPermissionState {
  const NotificationPermissionState({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
  });

  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;
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
  Future<void>? _initializing;

  Future<void> initialize() async {
    if (_initialized) return;
    final activeInitialization = _initializing;
    if (activeInitialization != null) {
      await activeInitialization;
      return;
    }

    final initialization = _initialize();
    _initializing = initialization;
    try {
      await initialization;
    } catch (error, stackTrace) {
      developer.log(
        'Notification initialization failed',
        name: 'nourish.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('Nourish notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
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
  }) async {
    await initialize();
    await _cancelWorkoutReminders();
    await _plugin.cancel(id: _testId);
    if (!settings.anyEnabled) {
      return const NotificationScheduleResult(
        notificationsAllowed: true,
        exactTiming: false,
        scheduledCount: 0,
      );
    }

    final permissions = await getPermissionState();
    final notificationsAllowed = permissions.notificationsAllowed;
    final exactTiming = permissions.exactAlarmsAllowed;

    if (!notificationsAllowed) {
      return const NotificationScheduleResult(
        notificationsAllowed: false,
        exactTiming: false,
        scheduledCount: 0,
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
    var scheduledCount = 0;

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
            channelId: 'nourish_workout_alarm_v2',
            channelName: 'Workout alarms',
            channelDescription: 'Alerts at your chosen workout time',
          ),
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'workout',
        );
        scheduledCount++;
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
        scheduledCount++;
      }
    }

    return NotificationScheduleResult(
      notificationsAllowed: true,
      exactTiming: exactTiming,
      scheduledCount: scheduledCount,
    );
  }

  Future<NotificationPermissionState> getPermissionState() async {
    await initialize();
    if (!Platform.isAndroid) {
      return const NotificationPermissionState(
        notificationsAllowed: true,
        exactAlarmsAllowed: true,
      );
    }

    final android = _androidImplementation;
    var notificationsAllowed = true;
    var exactAlarmsAllowed = false;
    try {
      notificationsAllowed = await android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      notificationsAllowed = false;
    }
    try {
      exactAlarmsAllowed =
          await android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      exactAlarmsAllowed = false;
    }
    return NotificationPermissionState(
      notificationsAllowed: notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed,
    );
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();
    if (!Platform.isAndroid) return true;
    await _androidImplementation?.requestNotificationsPermission();
    return await _androidImplementation?.areNotificationsEnabled() ?? true;
  }

  Future<bool> requestExactAlarmPermission() async {
    await initialize();
    if (!Platform.isAndroid) return true;
    await _androidImplementation?.requestExactAlarmsPermission();
    return await _androidImplementation?.canScheduleExactNotifications() ??
        false;
  }

  Future<bool> openNotificationSettings() async {
    await initialize();
    if (!Platform.isAndroid) return true;
    return await _plugin.openAppNotificationSettings() ?? false;
  }

  Future<int> pendingWorkoutReminderCount() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.where((request) {
      final alarm = request.id >= _alarmBaseId && request.id < _alarmBaseId + 8;
      final advance =
          request.id >= _advanceBaseId && request.id < _advanceBaseId + 8;
      return alarm || advance;
    }).length;
  }

  Future<bool> showTestNotification() async {
    await initialize();
    if (!await requestNotificationPermission()) return false;
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

  AndroidFlutterLocalNotificationsPlugin? get _androidImplementation => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

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
        groupKey: alarmLike ? 'nourish_alarm' : 'nourish_reminders',
        groupAlertBehavior: GroupAlertBehavior.all,
        audioAttributesUsage: alarmLike
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
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
