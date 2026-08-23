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
}
