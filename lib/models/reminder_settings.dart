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
