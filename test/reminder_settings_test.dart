import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/models/reminder_settings.dart';

void main() {
  test('reminder settings round-trip and format time', () {
    const original = ReminderSettings(
      alarmEnabled: true,
      advanceEnabled: true,
      hour: 18,
      minute: 5,
      advanceMinutes: 30,
    );

    final restored = ReminderSettings.fromMap(original.toMap());

    expect(restored.alarmEnabled, isTrue);
    expect(restored.advanceEnabled, isTrue);
    expect(restored.anyEnabled, isTrue);
    expect(restored.timeLabel, '6:05 PM');
    expect(restored.advanceMinutes, 30);
  });

  test('missing cloud values use quiet, safe defaults', () {
    final settings = ReminderSettings.fromMap(null);

    expect(settings.anyEnabled, isFalse);
    expect(settings.timeLabel, '6:00 PM');
  });

  test('next workout alarm uses the nearest selected training day', () {
    final now = DateTime(2026, 8, 24, 15, 6); // Monday.
    final alarm = nextWorkoutAlarmAt(
      workoutDays: const ['MON', 'FRI', 'SAT', 'SUN'],
      hour: 15,
      minute: 8,
      from: now,
    );

    expect(alarm, DateTime(2026, 8, 24, 15, 8));
    expect(formatAlarmCountdown(alarm!, from: now), 'in 2 mins');
    expect(formatAlarmDayAndTime(alarm, from: now), 'Today at 3:08 PM');
  });

  test('past time on today’s training day moves to the next selected day', () {
    final now = DateTime(2026, 8, 24, 15, 9); // Monday.
    final alarm = nextWorkoutAlarmAt(
      workoutDays: const ['MON', 'FRI'],
      hour: 15,
      minute: 8,
      from: now,
    );

    expect(alarm, DateTime(2026, 8, 28, 15, 8));
    expect(formatAlarmDayAndTime(alarm!, from: now), 'Fri at 3:08 PM');
  });
}
