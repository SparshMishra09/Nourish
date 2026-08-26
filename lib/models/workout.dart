class ExerciseItem {
  const ExerciseItem({
    required this.name,
    required this.detail,
    required this.focus,
    required this.icon,
  });

  final String name;
  final String detail;
  final String focus;
  final String icon;

  factory ExerciseItem.fromMap(Map<String, dynamic> map) => ExerciseItem(
    name: map['name'] as String? ?? '',
    detail: map['detail'] as String? ?? '',
    focus: map['focus'] as String? ?? '',
    icon: map['icon'] as String? ?? '⚡',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'detail': detail,
    'focus': focus,
    'icon': icon,
  };
}

class WorkoutSupportBlock {
  const WorkoutSupportBlock({
    required this.title,
    required this.reason,
    required this.estimatedMinutes,
    required this.exercises,
  });

  static const empty = WorkoutSupportBlock(
    title: '',
    reason: '',
    estimatedMinutes: 0,
    exercises: [],
  );

  final String title;
  final String reason;
  final int estimatedMinutes;
  final List<ExerciseItem> exercises;

  bool get isEmpty => exercises.isEmpty;

  factory WorkoutSupportBlock.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    return WorkoutSupportBlock(
      title: map['title'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.round() ?? 0,
      exercises: (map['exercises'] as List? ?? const [])
          .map(
            (item) =>
                ExerciseItem.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'reason': reason,
    'estimatedMinutes': estimatedMinutes,
    'exercises': exercises.map((item) => item.toMap()).toList(),
  };
}

class WorkoutDay {
  const WorkoutDay({
    required this.dayLabel,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.exercises,
    this.warmUp = WorkoutSupportBlock.empty,
    this.coolDown = WorkoutSupportBlock.empty,
  });

  final String dayLabel;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final List<ExerciseItem> exercises;
  final WorkoutSupportBlock warmUp;
  final WorkoutSupportBlock coolDown;

  int get optionalExtraMinutes =>
      warmUp.estimatedMinutes + coolDown.estimatedMinutes;

  factory WorkoutDay.fromMap(Map<String, dynamic> map) => WorkoutDay(
    dayLabel: map['dayLabel'] as String? ?? '',
    title: map['title'] as String? ?? '',
    subtitle: map['subtitle'] as String? ?? '',
    durationMinutes: (map['durationMinutes'] as num?)?.round() ?? 30,
    exercises: (map['exercises'] as List? ?? const [])
        .map(
          (item) =>
              ExerciseItem.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    warmUp: WorkoutSupportBlock.fromMap(
      map['warmUp'] is Map
          ? Map<String, dynamic>.from(map['warmUp'] as Map)
          : null,
    ),
    coolDown: WorkoutSupportBlock.fromMap(
      map['coolDown'] is Map
          ? Map<String, dynamic>.from(map['coolDown'] as Map)
          : null,
    ),
  );

  Map<String, dynamic> toMap() => {
    'dayLabel': dayLabel,
    'title': title,
    'subtitle': subtitle,
    'durationMinutes': durationMinutes,
    'exercises': exercises.map((item) => item.toMap()).toList(),
    'warmUp': warmUp.toMap(),
    'coolDown': coolDown.toMap(),
  };
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.goal,
    required this.daysPerWeek,
    required this.days,
  });

  final String goal;
  final int daysPerWeek;
  final List<WorkoutDay> days;

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) => WorkoutPlan(
    goal: map['goal'] as String? ?? 'General fitness',
    daysPerWeek: (map['daysPerWeek'] as num?)?.round() ?? 3,
    days: (map['days'] as List? ?? const [])
        .map(
          (item) => WorkoutDay.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'goal': goal,
    'daysPerWeek': daysPerWeek,
    'days': days.map((day) => day.toMap()).toList(),
  };

  WorkoutDay nextWorkout(DateTime from) {
    if (days.isEmpty) {
      throw StateError('Workout plan has no training days.');
    }
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    for (var offset = 0; offset < labels.length; offset++) {
      final label = labels[(from.weekday - 1 + offset) % labels.length];
      for (final workout in days) {
        if (workout.dayLabel == label) return workout;
      }
    }
    return days.first;
  }
}
