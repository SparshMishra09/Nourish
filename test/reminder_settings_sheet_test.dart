import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/core/app_theme.dart';
import 'package:nourish/models/reminder_settings.dart';
import 'package:nourish/models/user_profile.dart';
import 'package:nourish/services/notification_service.dart';
import 'package:nourish/widgets/reminder_settings_sheet.dart';

const _profile = UserProfile(
  uid: 'qa-user',
  name: 'Nourish QA',
  email: 'qa@example.com',
  age: 29,
  gender: 'Female',
  heightCm: 165,
  weightKg: 60,
  goal: 'Maintain weight',
  dietType: 'Vegetarian',
  activityLevel: 'Moderately active',
  workoutDays: 3,
  availableWorkoutDays: ['MON', 'WED', 'FRI'],
  sessionMinutes: 30,
  equipment: ['Bodyweight'],
  avoidFoods: [],
  onboardingComplete: true,
);

void main() {
  test('schedule confirmation explains the eight-alert breakdown', () {
    const result = NotificationScheduleResult(
      notificationsAllowed: true,
      exactTiming: true,
      alarmCount: 4,
      advanceCount: 4,
    );
    const settings = ReminderSettings(
      alarmEnabled: true,
      advanceEnabled: true,
      hour: 15,
      minute: 8,
      advanceMinutes: 30,
    );

    expect(result.scheduledCount, 8);
    expect(
      result.confirmationMessage(settings: settings, workoutDayCount: 4),
      'Active on 4 workout days: 4 workout-time alarms at 3:08 PM + 4 get-ready notifications 30 min before.',
    );
  });

  testWidgets('blocked notification test explains how to enable access', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReminderSettingsSheet(
            initialSettings: const ReminderSettings(),
            profile: _profile,
            onGetPermissionState: () async => const NotificationPermissionState(
              notificationsAllowed: false,
              exactAlarmsAllowed: false,
            ),
            onRequestNotificationPermission: () async {
              requests++;
              return false;
            },
            onRequestExactAlarmPermission: () async => false,
            onOpenNotificationSettings: () async => true,
            onTestNotification: () async => false,
            onTestAlarm: () async => false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications are off'), findsOneWidget);
    await tester.ensureVisible(find.text('Send a test notification'));
    await tester.tap(find.text('Send a test notification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(requests, 1);
    expect(find.text('Allow Nourish notifications'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
  });

  testWidgets('enabling an alarm requests both Android permissions', (
    tester,
  ) async {
    var notificationsAllowed = false;
    var exactAlarmsAllowed = false;
    var notificationRequests = 0;
    var exactAlarmRequests = 0;

    NotificationPermissionState state() => NotificationPermissionState(
      notificationsAllowed: notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReminderSettingsSheet(
            initialSettings: const ReminderSettings(),
            profile: _profile,
            onGetPermissionState: () async => state(),
            onRequestNotificationPermission: () async {
              notificationRequests++;
              notificationsAllowed = true;
              return true;
            },
            onRequestExactAlarmPermission: () async {
              exactAlarmRequests++;
              exactAlarmsAllowed = true;
              return true;
            },
            onOpenNotificationSettings: () async => true,
            onTestNotification: () async => true,
            onTestAlarm: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Allow exact workout alarms'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(notificationRequests, 1);
    expect(exactAlarmRequests, 1);
    expect(find.text('Notifications allowed'), findsOneWidget);
    expect(find.text('Exact alarms allowed'), findsOneWidget);
  });

  testWidgets('workout alarm has a separate audible test', (tester) async {
    var alarmTests = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReminderSettingsSheet(
            initialSettings: const ReminderSettings(alarmEnabled: true),
            profile: _profile,
            onGetPermissionState: () async => const NotificationPermissionState(
              notificationsAllowed: true,
              exactAlarmsAllowed: true,
            ),
            onRequestNotificationPermission: () async => true,
            onRequestExactAlarmPermission: () async => true,
            onOpenNotificationSettings: () async => true,
            onTestNotification: () async => true,
            onTestAlarm: () async {
              alarmTests++;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Test workout alarm sound'));
    await tester.tap(find.text('Test workout alarm sound'));
    await tester.pumpAndSettle();

    expect(alarmTests, 1);
    expect(
      find.text('Alarm test started. Nourish uses your phone’s Alarm volume.'),
      findsOneWidget,
    );
  });
}
