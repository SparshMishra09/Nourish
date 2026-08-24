class ReminderSettings {
  const ReminderSettings({
    this.alarmEnabled = false,
    this.advanceEnabled = false,
    this.hour = 18,
    this.minute = 0,
    this.advanceMinutes = 30,
  });

  final bool alarmEnabled;
  final bool advanceEnabled;
  final int hour;
  final int minute;
  final int advanceMinutes;

  bool get anyEnabled => alarmEnabled || advanceEnabled;

  String get timeLabel {
    final period = hour >= 12 ? 'PM' : 'AM';
    final clockHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$clockHour:${minute.toString().padLeft(2, '0')} $period';
  }

  factory ReminderSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ReminderSettings();
    return ReminderSettings(
      alarmEnabled: map['alarmEnabled'] as bool? ?? false,
      advanceEnabled: map['advanceEnabled'] as bool? ?? false,
      hour: ((map['hour'] as num?)?.round() ?? 18).clamp(0, 23),
      minute: ((map['minute'] as num?)?.round() ?? 0).clamp(0, 59),
      advanceMinutes: ((map['advanceMinutes'] as num?)?.round() ?? 30).clamp(
        10,
        120,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'alarmEnabled': alarmEnabled,
    'advanceEnabled': advanceEnabled,
    'hour': hour,
    'minute': minute,
    'advanceMinutes': advanceMinutes,
  };

  ReminderSettings copyWith({
    bool? alarmEnabled,
    bool? advanceEnabled,
    int? hour,
    int? minute,
    int? advanceMinutes,
  }) {
    return ReminderSettings(
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      advanceEnabled: advanceEnabled ?? this.advanceEnabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    );
  }
}

DateTime? nextWorkoutAlarmAt({
  required Iterable<String> workoutDays,
  required int hour,
  required int minute,
  DateTime? from,
}) {
  final now = from ?? DateTime.now();
  DateTime? earliest;
  for (final label in workoutDays.toSet()) {
    final weekday = _weekdayForReminderLabel(label);
    if (weekday == null) continue;
    final daysAhead =
        (weekday - now.weekday + DateTime.daysPerWeek) % DateTime.daysPerWeek;
    var candidate = DateTime(
      now.year,
      now.month,
      now.day + daysAhead,
      hour,
      minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: DateTime.daysPerWeek));
    }
    if (earliest == null || candidate.isBefore(earliest)) {
      earliest = candidate;
    }
  }
  return earliest;
}

String formatAlarmCountdown(DateTime alarmAt, {DateTime? from}) {
  final now = from ?? DateTime.now();
  final seconds = alarmAt.difference(now).inSeconds;
  if (seconds <= 0) return 'now';
  final minutes = (seconds + 59) ~/ 60;
  if (minutes < 60) return 'in $minutes ${minutes == 1 ? 'min' : 'mins'}';

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours < 24) {
    return remainingMinutes == 0
        ? 'in $hours ${hours == 1 ? 'hr' : 'hrs'}'
        : 'in $hours ${hours == 1 ? 'hr' : 'hrs'} $remainingMinutes min';
  }

  final days = hours ~/ 24;
  final remainingHours = hours % 24;
  return remainingHours == 0
      ? 'in $days ${days == 1 ? 'day' : 'days'}'
      : 'in $days ${days == 1 ? 'day' : 'days'} $remainingHours hr';
}

String formatAlarmDayAndTime(DateTime alarmAt, {DateTime? from}) {
  final now = from ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final alarmDay = DateTime(alarmAt.year, alarmAt.month, alarmAt.day);
  final dayDifference = alarmDay.difference(today).inDays;
  final dayLabel = switch (dayDifference) {
    0 => 'Today',
    1 => 'Tomorrow',
    _ => const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][alarmAt.weekday - 1],
  };
  final period = alarmAt.hour >= 12 ? 'PM' : 'AM';
  final clockHour = alarmAt.hour % 12 == 0 ? 12 : alarmAt.hour % 12;
  final clock =
      '$clockHour:${alarmAt.minute.toString().padLeft(2, '0')} $period';
  return '$dayLabel at $clock';
}

int? _weekdayForReminderLabel(String label) => switch (label.toUpperCase()) {
  'MON' => DateTime.monday,
  'TUE' => DateTime.tuesday,
  'WED' => DateTime.wednesday,
  'THU' => DateTime.thursday,
  'FRI' => DateTime.friday,
  'SAT' => DateTime.saturday,
  'SUN' => DateTime.sunday,
  _ => null,
};
