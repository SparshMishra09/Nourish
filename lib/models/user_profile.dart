import 'dart:math' as math;

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.dietType,
    required this.activityLevel,
    required this.workoutDays,
    required this.availableWorkoutDays,
    required this.sessionMinutes,
    required this.equipment,
    required this.avoidFoods,
    required this.onboardingComplete,
  });

  final String uid;
  final String name;
  final String email;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String goal;
  final String dietType;
  final String activityLevel;
  final int workoutDays;
  final List<String> availableWorkoutDays;
  final int sessionMinutes;
  final List<String> equipment;
  final List<String> avoidFoods;
  final bool onboardingComplete;

  factory UserProfile.empty({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return UserProfile(
      uid: uid,
      name: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : 'Explorer',
      email: email,
      age: 25,
      gender: 'Prefer not to say',
      heightCm: 170,
      weightKg: 70,
      goal: 'Lose fat',
      dietType: 'Vegetarian',
      activityLevel: 'Moderately active',
      workoutDays: 4,
      availableWorkoutDays: const ['MON', 'TUE', 'THU', 'SAT'],
      sessionMinutes: 35,
      equipment: const ['Bodyweight'],
      avoidFoods: const [],
      onboardingComplete: false,
    );
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    double number(String key, double fallback) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    final workoutDays = (map['workoutDays'] as num?)?.toInt() ?? 4;
    final storedAvailability = List<String>.from(
      map['availableWorkoutDays'] as List? ?? const [],
    );

    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? 'Explorer',
      email: map['email'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 25,
      gender: map['gender'] as String? ?? 'Prefer not to say',
      heightCm: number('heightCm', 170),
      weightKg: number('weightKg', 70),
      goal: map['goal'] as String? ?? 'Lose fat',
      dietType: map['dietType'] as String? ?? 'Vegetarian',
      activityLevel: map['activityLevel'] as String? ?? 'Moderately active',
      workoutDays: workoutDays,
      availableWorkoutDays: storedAvailability.isEmpty
          ? suggestedWorkoutDays(workoutDays)
          : storedAvailability,
      sessionMinutes: (map['sessionMinutes'] as num?)?.toInt() ?? 35,
      equipment: List<String>.from(
        map['equipment'] as List? ?? const ['Bodyweight'],
      ),
      avoidFoods: List<String>.from(map['avoidFoods'] as List? ?? const []),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'age': age,
    'gender': gender,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'goal': goal,
    'dietType': dietType,
    'activityLevel': activityLevel,
    'workoutDays': workoutDays,
    'availableWorkoutDays': availableWorkoutDays,
    'sessionMinutes': sessionMinutes,
    'equipment': equipment,
    'avoidFoods': avoidFoods,
    'onboardingComplete': onboardingComplete,
  };

  double get bmi => weightKg / math.pow(heightCm / 100, 2);

  double get bmr {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (gender) {
      'Male' => base + 5,
      'Female' => base - 161,
      _ => base - 78,
    };
  }

  double get activityMultiplier => switch (activityLevel) {
    'Mostly sitting' => 1.2,
    'Lightly active' => 1.375,
    'Very active' => 1.725,
    _ => 1.55,
  };

  int get maintenanceCalories => (bmr * activityMultiplier).round();

  int get calorieTarget => switch (goal) {
    'Lose fat' => math.max(1200, maintenanceCalories - 400),
    'Build muscle' => maintenanceCalories + 250,
    _ => maintenanceCalories,
  };

  int get proteinTarget {
    final multiplier = goal == 'Build muscle' ? 1.8 : 1.6;
    return (weightKg * multiplier).round();
  }

  int get carbTarget => (calorieTarget * 0.45 / 4).round();

  int get fiberTarget => math.max(20, (calorieTarget / 1000 * 14).round());

  int get waterTargetMl => (weightKg * 35).round();

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? goal,
    String? dietType,
    String? activityLevel,
    int? workoutDays,
    List<String>? availableWorkoutDays,
    int? sessionMinutes,
    List<String>? equipment,
    List<String>? avoidFoods,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      dietType: dietType ?? this.dietType,
      activityLevel: activityLevel ?? this.activityLevel,
      workoutDays:
          workoutDays ?? availableWorkoutDays?.length ?? this.workoutDays,
      availableWorkoutDays: availableWorkoutDays ?? this.availableWorkoutDays,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      equipment: equipment ?? this.equipment,
      avoidFoods: avoidFoods ?? this.avoidFoods,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

List<String> suggestedWorkoutDays(int count) {
  const balanced = <int, List<String>>{
    2: ['TUE', 'FRI'],
    3: ['MON', 'WED', 'FRI'],
    4: ['MON', 'TUE', 'THU', 'SAT'],
    5: ['MON', 'TUE', 'THU', 'FRI', 'SAT'],
    6: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
  };
  return List<String>.from(balanced[count.clamp(2, 6)]!);
}
