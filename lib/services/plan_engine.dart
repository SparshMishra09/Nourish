import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';

class PlanEngine {
  const PlanEngine();

  List<Recipe> recommendRecipes(
    List<Recipe> recipes,
    UserProfile profile, {
    String mealFilter = 'All',
  }) {
    final blocked = profile.avoidFoods
        .map((item) => item.toLowerCase())
        .toSet();
    final eligible = recipes.where((recipe) {
      if (!recipe.supportsDiet(profile.dietType)) return false;
      if (mealFilter != 'All' && recipe.mealType != mealFilter) return false;
      if (recipe.allergens.any(
        (item) => blocked.contains(item.toLowerCase()),
      )) {
        return false;
      }
      return true;
    }).toList();

    eligible.sort((a, b) {
      final aScore = _recipeScore(a, profile);
      final bScore = _recipeScore(b, profile);
      return bScore.compareTo(aScore);
    });
    return eligible;
  }

  int _recipeScore(Recipe recipe, UserProfile profile) {
    var score = recipe.goalTags.contains(profile.goal) ? 30 : 0;
    if (profile.goal == 'Build muscle') score += recipe.protein;
    if (profile.goal == 'Lose fat') {
      score += recipe.fiber * 2;
      score += recipe.protein;
      score -= recipe.calories ~/ 50;
    }
    if (profile.goal == 'Maintain weight') {
      score += recipe.fiber + recipe.protein;
    }
    if (recipe.tags.contains('Quick')) score += 3;
    return score;
  }

  DailyMealPlan buildDailyMealPlan(
    List<Recipe> recipes,
    UserProfile profile, {
    DateTime? date,
  }) {
    const mealShares = <String, double>{
      'Breakfast': 0.25,
      'Lunch': 0.30,
      'Dinner': 0.30,
      'Snack': 0.15,
    };
    final eligible = recommendRecipes(recipes, profile);
    final meals = <PlannedMeal>[];

    for (final entry in mealShares.entries) {
      final candidates = eligible
          .where((recipe) => recipe.mealType == entry.key)
          .toList();
      if (candidates.isEmpty) continue;

      final targetCalories = profile.calorieTarget * entry.value;
      final targetProtein = profile.proteinTarget * entry.value;
      candidates.sort((first, second) {
        final firstScore = _mealSlotScore(
          first,
          profile,
          targetCalories: targetCalories,
          targetProtein: targetProtein,
        );
        final secondScore = _mealSlotScore(
          second,
          profile,
          targetCalories: targetCalories,
          targetProtein: targetProtein,
        );
        return secondScore.compareTo(firstScore);
      });

      // Rotate between the eight best-fitting options from day to day. This
      // uses the broader catalog while keeping every suggestion close to the
      // user's nutrition target, diet, exclusions and goal.
      final rotationPool = candidates.take(8).toList();
      final planDate = date ?? DateTime.now();
      final dayNumber =
          DateTime(
            planDate.year,
            planDate.month,
            planDate.day,
          ).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay;
      final profileSeed = profile.uid.codeUnits.fold<int>(0, (a, b) => a + b);
      final mealSeed = entry.key.codeUnits.fold<int>(0, (a, b) => a + b);
      final recipe =
          rotationPool[(dayNumber + profileSeed + mealSeed) %
              rotationPool.length];
      meals.add(
        PlannedMeal(
          mealType: entry.key,
          recipe: recipe,
          servingScale: suggestedServingScale(
            recipe,
            profile,
            calorieShare: entry.value,
          ),
          fitReason: recipeFitReason(recipe, profile),
        ),
      );
    }

    return DailyMealPlan(
      meals: meals,
      calorieTarget: profile.calorieTarget,
      proteinTarget: profile.proteinTarget,
    );
  }

  int _mealSlotScore(
    Recipe recipe,
    UserProfile profile, {
    required double targetCalories,
    required double targetProtein,
  }) {
    final share = targetCalories / profile.calorieTarget;
    final scale = suggestedServingScale(recipe, profile, calorieShare: share);
    final calorieFit =
        30 - (((recipe.calories * scale) - targetCalories).abs() / 25).round();
    final proteinFit =
        25 - (((recipe.protein * scale) - targetProtein).abs() * 1.5).round();
    return (_recipeScore(recipe, profile) * 4) + calorieFit + proteinFit;
  }

  double suggestedServingScale(
    Recipe recipe,
    UserProfile profile, {
    double? calorieShare,
  }) {
    if (recipe.mealType == 'Side' && calorieShare == null) return 1;
    final share =
        calorieShare ??
        switch (recipe.mealType) {
          'Breakfast' => 0.25,
          'Lunch' || 'Dinner' => 0.30,
          'Snack' => 0.15,
          _ => 0.25,
        };
    final calorieScale = (profile.calorieTarget * share) / recipe.calories;
    final proteinScale = (profile.proteinTarget * share) / recipe.protein;
    final proteinWeight = profile.goal == 'Build muscle' ? 0.35 : 0.20;
    final blended =
        (calorieScale * (1 - proteinWeight)) + (proteinScale * proteinWeight);
    final clamped = blended.clamp(0.75, 1.5);
    return (clamped * 4).round() / 4;
  }

  String recipeFitReason(Recipe recipe, UserProfile profile) {
    return switch (profile.goal) {
      'Build muscle' =>
        '${recipe.protein}g protein per serving for muscle-focused days',
      'Lose fat' =>
        '${recipe.fiber}g fibre and ${recipe.protein}g protein for staying power',
      _ => '${recipe.calories} kcal with balanced, practical ingredients',
    };
  }

  WorkoutPlan buildWorkoutPlan(UserProfile profile) {
    const weekOrder = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final selectedDays =
        profile.availableWorkoutDays.where(weekOrder.contains).toSet().toList()
          ..sort(
            (first, second) =>
                weekOrder.indexOf(first).compareTo(weekOrder.indexOf(second)),
          );
    final availableDays = selectedDays.length >= 2
        ? selectedDays.take(6).toList()
        : suggestedWorkoutDays(profile.workoutDays);
    final dayCount = availableDays.length;
    final templates = switch (profile.goal) {
      'Build muscle' => _muscleTemplates,
      'Lose fat' => _fatLossTemplates,
      _ => _fitnessTemplates,
    };

    final days = List<WorkoutDay>.generate(dayCount, (index) {
      final template = templates[index % templates.length];
      final items = List<ExerciseItem>.from(template.exercises);
      final wantsHomeOnly =
          profile.equipment.length == 1 &&
          profile.equipment.contains('Bodyweight');
      final adjusted = wantsHomeOnly
          ? items.map(_bodyweightAlternative).toList()
          : items;
      final mainExercises = _fitToDuration(adjusted, profile.sessionMinutes);
      final support = _buildWorkoutSupport(
        title: template.title,
        goal: profile.goal,
        mainExercises: mainExercises,
      );
      return WorkoutDay(
        dayLabel: availableDays[index],
        title: template.title,
        subtitle: template.subtitle,
        durationMinutes: profile.sessionMinutes,
        exercises: mainExercises,
        warmUp: support.warmUp,
        coolDown: support.coolDown,
      );
    });

    return WorkoutPlan(goal: profile.goal, daysPerWeek: dayCount, days: days);
  }

  ExerciseItem _bodyweightAlternative(ExerciseItem exercise) {
    const swaps = {
      'Dumbbell goblet squat': ExerciseItem(
        name: 'Tempo bodyweight squat',
        detail: '4 × 12 · 3 sec down',
        focus: 'Quads · glutes',
        icon: '🦵',
      ),
      'One-arm dumbbell row': ExerciseItem(
        name: 'Prone Y-T-W raises',
        detail: '3 × 8 each shape',
        focus: 'Upper back',
        icon: '🪽',
      ),
      'Dumbbell Romanian deadlift': ExerciseItem(
        name: 'Single-leg hip hinge',
        detail: '3 × 10 each side',
        focus: 'Hamstrings · balance',
        icon: '⚖️',
      ),
      'Dumbbell shoulder press': ExerciseItem(
        name: 'Pike push-up',
        detail: '3 × 8-12',
        focus: 'Shoulders · triceps',
        icon: '🔺',
      ),
    };
    return swaps[exercise.name] ?? exercise;
  }

  List<ExerciseItem> _fitToDuration(List<ExerciseItem> exercises, int minutes) {
    final count = switch (minutes) {
      <= 20 => 4,
      <= 35 => 5,
      _ => 6,
    };
    return exercises.take(count).toList();
  }

  _WorkoutSupport _buildWorkoutSupport({
    required String title,
    required String goal,
    required List<ExerciseItem> mainExercises,
  }) {
    final mainNames = mainExercises.map((item) => item.name).toSet();
    final lowerTitle = title.toLowerCase();

    late final List<ExerciseItem> warmUpCandidates;
    late final List<ExerciseItem> coolDownCandidates;
    late final String warmUpReason;
    late final String coolDownReason;
    late final int warmUpCount;

    if (lowerTitle.contains('upper body')) {
      warmUpCandidates = const [
        _dynamicChestOpener,
        _scapulaPushUp,
        _worldStretchWarmUp,
        _inclinePushUpWarmUp,
        _birdDogWarmUp,
      ];
      coolDownCandidates = const [
        _chestShoulderStretch,
        _kneelingLatStretch,
        _tricepsStretch,
      ];
      warmUpReason =
          'Prepares the shoulders, shoulder blades and upper back for presses and rows without tiring your working muscles.';
      coolDownReason =
          'Gently opens the chest, lats and arms used by today’s upper-body work.';
      warmUpCount = 3;
    } else if (lowerTitle.contains('lower body')) {
      warmUpCandidates = const [
        _ankleCircles,
        _worldStretchWarmUp,
        _squatReachWarmUp,
        _gluteBridgeWarmUp,
        _backForthWarmUp,
      ];
      coolDownCandidates = const [
        _hamstringStretch,
        _sideQuadStretch,
        _standingCalfStretch,
      ];
      warmUpReason =
          'Moves the ankles and hips, then rehearses the squat and hip-drive patterns in today’s leg session.';
      coolDownReason =
          'Targets the hamstrings, quads and calves after the day’s squat, hinge and lunge patterns.';
      warmUpCount = 4;
    } else if (lowerTitle.contains('cardio')) {
      warmUpCandidates = const [
        _ankleCircles,
        _dynamicChestOpener,
        _backForthWarmUp,
        _squatReachWarmUp,
        _worldStretchWarmUp,
      ];
      coolDownCandidates = const [
        _backForthCoolDown,
        _standingCalfStretch,
        _hamstringStretch,
        _chestShoulderStretch,
      ];
      warmUpReason =
          'Builds rhythm and range gradually before today’s repeated full-body cardio intervals.';
      coolDownReason =
          'First eases your pace, then relaxes the calves, hamstrings and shoulders used during the intervals.';
      warmUpCount = 4;
    } else if (lowerTitle.contains('mobility')) {
      warmUpCandidates = const [
        _backForthWarmUp,
        _dynamicChestOpener,
        _ankleCircles,
        _scapulaPushUp,
      ];
      coolDownCandidates = const [
        _chestShoulderStretch,
        _hamstringStretch,
        _kneelingLatStretch,
      ];
      warmUpReason =
          'Raises body temperature gently while keeping your core fresh for controlled mobility work.';
      coolDownReason =
          'A quiet, low-intensity finish for the hips, back and shoulders after today’s mobility flow.';
      warmUpCount = 3;
    } else {
      warmUpCandidates = const [
        _backForthWarmUp,
        _worldStretchWarmUp,
        _dynamicChestOpener,
        _squatReachWarmUp,
        _scapulaPushUp,
        _gluteBridgeWarmUp,
        _ankleCircles,
      ];
      coolDownCandidates = const [
        _backForthCoolDown,
        _chestShoulderStretch,
        _hamstringStretch,
        _standingCalfStretch,
      ];
      warmUpReason = goal == 'Build muscle'
          ? 'Rehearses today’s push, squat and hinge patterns at low effort so your energy stays available for the working sets.'
          : 'Prepares the upper body, hips and ankles for today’s mixed full-body session.';
      coolDownReason =
          'Steps the effort down before relaxing the main upper- and lower-body areas trained today.';
      warmUpCount = 4;
    }

    final warmUpExercises = _supportItems(
      warmUpCandidates,
      mainNames: mainNames,
      count: warmUpCount,
    );

    return _WorkoutSupport(
      warmUp: WorkoutSupportBlock(
        title: 'Warm-up',
        reason: warmUpReason,
        estimatedMinutes: warmUpExercises.length == 4 ? 5 : 4,
        exercises: warmUpExercises,
      ),
      coolDown: WorkoutSupportBlock(
        title: 'Cool-down',
        reason: coolDownReason,
        estimatedMinutes: 4,
        exercises: coolDownCandidates,
      ),
    );
  }

  List<ExerciseItem> _supportItems(
    List<ExerciseItem> candidates, {
    required Set<String> mainNames,
    required int count,
  }) {
    final selected = candidates
        .where((exercise) => !mainNames.contains(exercise.name))
        .take(count)
        .toList();
    if (selected.length == count) return selected;

    for (final exercise in candidates) {
      if (!selected.contains(exercise)) selected.add(exercise);
      if (selected.length == count) break;
    }
    return selected;
  }
}

class _WorkoutSupport {
  const _WorkoutSupport({required this.warmUp, required this.coolDown});

  final WorkoutSupportBlock warmUp;
  final WorkoutSupportBlock coolDown;
}

const _dynamicChestOpener = ExerciseItem(
  name: 'Dynamic chest opener',
  detail: '40 sec · smooth reps',
  focus: 'Chest · shoulders',
  icon: '🪽',
);

const _scapulaPushUp = ExerciseItem(
  name: 'Scapula push-up',
  detail: '8 slow reps',
  focus: 'Shoulder blades · serratus',
  icon: '🛡️',
);

const _ankleCircles = ExerciseItem(
  name: 'Ankle circles',
  detail: '8 each way · each side',
  focus: 'Ankles · calves',
  icon: '🔄',
);

const _worldStretchWarmUp = ExerciseItem(
  name: 'World’s greatest stretch',
  detail: '4 flowing reps each side',
  focus: 'Hips · upper back',
  icon: '🌍',
);

const _squatReachWarmUp = ExerciseItem(
  name: 'Squat to reach',
  detail: '8 easy reps',
  focus: 'Hips · knees · shoulders',
  icon: '🚀',
);

const _gluteBridgeWarmUp = ExerciseItem(
  name: 'Glute bridge',
  detail: '10 easy reps',
  focus: 'Glutes · hips',
  icon: '🌉',
);

const _inclinePushUpWarmUp = ExerciseItem(
  name: 'Incline push-up',
  detail: '6 easy reps',
  focus: 'Chest · shoulders',
  icon: '💪',
);

const _birdDogWarmUp = ExerciseItem(
  name: 'Bird dog',
  detail: '6 each side · controlled',
  focus: 'Core · spine',
  icon: '🐦',
);

const _backForthWarmUp = ExerciseItem(
  name: 'Back & forth step',
  detail: '45 sec · easy pace',
  focus: 'Pulse · hips · legs',
  icon: '👟',
);

const _backForthCoolDown = ExerciseItem(
  name: 'Back & forth step',
  detail: '60 sec · gradually slower',
  focus: 'Active downshift',
  icon: '🌙',
);

const _chestShoulderStretch = ExerciseItem(
  name: 'Chest & shoulder stretch',
  detail: '20 sec each side',
  focus: 'Chest · front shoulders',
  icon: '🤲',
);

const _kneelingLatStretch = ExerciseItem(
  name: 'Kneeling lat stretch',
  detail: '20 sec each side',
  focus: 'Lats · shoulders',
  icon: '🙆',
);

const _tricepsStretch = ExerciseItem(
  name: 'Triceps stretch',
  detail: '20 sec each side',
  focus: 'Triceps · shoulders',
  icon: '🫱',
);

const _hamstringStretch = ExerciseItem(
  name: 'Hamstring stretch',
  detail: '20 sec each side',
  focus: 'Hamstrings · glutes',
  icon: '🦵',
);

const _sideQuadStretch = ExerciseItem(
  name: 'Side-lying quad stretch',
  detail: '20 sec each side',
  focus: 'Quadriceps',
  icon: '🛌',
);

const _standingCalfStretch = ExerciseItem(
  name: 'Standing calf stretch',
  detail: '20 sec each side',
  focus: 'Calves · ankles',
  icon: '🧱',
);

const _muscleTemplates = <WorkoutDay>[
  WorkoutDay(
    dayLabel: '',
    title: 'Upper body strength',
    subtitle: 'Controlled reps · 60 sec rest',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Push-up',
        detail: '4 × 8-15',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '4 × 10 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Dumbbell shoulder press',
        detail: '3 × 10-12',
        focus: 'Shoulders · triceps',
        icon: '🏋️',
      ),
      ExerciseItem(
        name: 'Close-grip push-up',
        detail: '3 × 8-12',
        focus: 'Triceps · chest',
        icon: '🔥',
      ),
      ExerciseItem(
        name: 'Reverse snow angel',
        detail: '3 × 12',
        focus: 'Upper back · posture',
        icon: '❄️',
      ),
      ExerciseItem(
        name: 'Dead bug',
        detail: '3 × 10 each side',
        focus: 'Core control',
        icon: '🪲',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Lower body power',
    subtitle: 'Strong legs · steady tempo',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '4 × 10-12',
        focus: 'Quads · glutes',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'Dumbbell Romanian deadlift',
        detail: '4 × 10',
        focus: 'Hamstrings · glutes',
        icon: '⚡',
      ),
      ExerciseItem(
        name: 'Reverse lunge',
        detail: '3 × 10 each side',
        focus: 'Legs · balance',
        icon: '↩️',
      ),
      ExerciseItem(
        name: 'Glute bridge',
        detail: '3 × 15',
        focus: 'Glutes · core',
        icon: '🌉',
      ),
      ExerciseItem(
        name: 'Calf raise',
        detail: '3 × 18',
        focus: 'Calves',
        icon: '⬆️',
      ),
      ExerciseItem(
        name: 'Side plank',
        detail: '3 × 30 sec each',
        focus: 'Obliques',
        icon: '📐',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Full body builder',
    subtitle: 'Compound focus · quality first',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '3 × 12',
        focus: 'Legs · core',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'Push-up',
        detail: '3 × max clean reps',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '3 × 12 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Dumbbell Romanian deadlift',
        detail: '3 × 12',
        focus: 'Posterior chain',
        icon: '⚡',
      ),
      ExerciseItem(
        name: 'Dumbbell shoulder press',
        detail: '3 × 10',
        focus: 'Shoulders',
        icon: '🏋️',
      ),
      ExerciseItem(
        name: 'Plank shoulder tap',
        detail: '3 × 16 total',
        focus: 'Core · stability',
        icon: '🧱',
      ),
    ],
  ),
];

const _fatLossTemplates = <WorkoutDay>[
  WorkoutDay(
    dayLabel: '',
    title: 'Full body metabolic',
    subtitle: '40 sec work · 20 sec reset',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Squat to reach',
        detail: '4 × 40 sec',
        focus: 'Legs · cardio',
        icon: '🚀',
      ),
      ExerciseItem(
        name: 'Incline push-up',
        detail: '4 × 40 sec',
        focus: 'Upper body',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'Mountain climber',
        detail: '4 × 40 sec',
        focus: 'Core · cardio',
        icon: '⛰️',
      ),
      ExerciseItem(
        name: 'Reverse lunge',
        detail: '4 × 40 sec',
        focus: 'Legs · balance',
        icon: '↩️',
      ),
      ExerciseItem(
        name: 'Plank shoulder tap',
        detail: '4 × 40 sec',
        focus: 'Core · stability',
        icon: '🧱',
      ),
      ExerciseItem(
        name: 'Fast feet',
        detail: '4 × 40 sec',
        focus: 'Cardio · agility',
        icon: '👟',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Strength & sculpt',
    subtitle: '45 sec work · controlled form',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '3 × 12',
        focus: 'Quads · glutes',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '3 × 12 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Dumbbell Romanian deadlift',
        detail: '3 × 12',
        focus: 'Hamstrings · glutes',
        icon: '⚡',
      ),
      ExerciseItem(
        name: 'Incline push-up',
        detail: '3 × 10-15',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'Dead bug',
        detail: '3 × 10 each side',
        focus: 'Core control',
        icon: '🪲',
      ),
      ExerciseItem(
        name: 'Marching bridge',
        detail: '3 × 16 total',
        focus: 'Glutes · core',
        icon: '🌉',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Low-impact cardio',
    subtitle: 'Apartment friendly · no jumping',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Power march',
        detail: '5 × 60 sec',
        focus: 'Cardio',
        icon: '🥁',
      ),
      ExerciseItem(
        name: 'Step jack',
        detail: '5 × 45 sec',
        focus: 'Full body',
        icon: '⭐',
      ),
      ExerciseItem(
        name: 'Knee drive',
        detail: '4 × 40 sec each',
        focus: 'Core · cardio',
        icon: '⬆️',
      ),
      ExerciseItem(
        name: 'Lateral step & reach',
        detail: '4 × 50 sec',
        focus: 'Agility',
        icon: '↔️',
      ),
      ExerciseItem(
        name: 'Standing mountain climber',
        detail: '4 × 45 sec',
        focus: 'Core · cardio',
        icon: '⛰️',
      ),
      ExerciseItem(
        name: 'Boxer shuffle',
        detail: '4 × 60 sec',
        focus: 'Cardio',
        icon: '🥊',
      ),
    ],
  ),
];

const _fitnessTemplates = <WorkoutDay>[
  WorkoutDay(
    dayLabel: '',
    title: 'Balanced full body',
    subtitle: 'Strength · movement · core',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '3 × 12',
        focus: 'Legs · core',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'Push-up',
        detail: '3 × 8-15',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '3 × 12 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Reverse lunge',
        detail: '3 × 10 each side',
        focus: 'Legs · balance',
        icon: '↩️',
      ),
      ExerciseItem(
        name: 'Dead bug',
        detail: '3 × 10 each side',
        focus: 'Core control',
        icon: '🪲',
      ),
      ExerciseItem(
        name: 'Power march',
        detail: '4 × 45 sec',
        focus: 'Cardio',
        icon: '🥁',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Mobility & core',
    subtitle: 'Restore range · move well',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'World’s greatest stretch',
        detail: '2 × 5 each side',
        focus: 'Hips · thoracic',
        icon: '🌍',
      ),
      ExerciseItem(
        name: '90/90 hip switch',
        detail: '3 × 8',
        focus: 'Hip mobility',
        icon: '🔄',
      ),
      ExerciseItem(
        name: 'Bird dog',
        detail: '3 × 10 each side',
        focus: 'Core · back',
        icon: '🐦',
      ),
      ExerciseItem(
        name: 'Side plank',
        detail: '3 × 25 sec each',
        focus: 'Obliques',
        icon: '📐',
      ),
      ExerciseItem(
        name: 'Glute bridge',
        detail: '3 × 15',
        focus: 'Glutes · core',
        icon: '🌉',
      ),
      ExerciseItem(
        name: 'Child’s pose breathing',
        detail: '2 × 60 sec',
        focus: 'Recovery',
        icon: '🌿',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Cardio conditioning',
    subtitle: 'Steady intervals · finish fresh',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Power march',
        detail: '4 × 60 sec',
        focus: 'Cardio',
        icon: '🥁',
      ),
      ExerciseItem(
        name: 'Squat to reach',
        detail: '4 × 40 sec',
        focus: 'Full body',
        icon: '🚀',
      ),
      ExerciseItem(
        name: 'Step jack',
        detail: '4 × 45 sec',
        focus: 'Cardio',
        icon: '⭐',
      ),
      ExerciseItem(
        name: 'Mountain climber',
        detail: '4 × 35 sec',
        focus: 'Core · cardio',
        icon: '⛰️',
      ),
      ExerciseItem(
        name: 'Lateral step & reach',
        detail: '4 × 45 sec',
        focus: 'Agility',
        icon: '↔️',
      ),
      ExerciseItem(
        name: 'Standing cooldown flow',
        detail: '5 minutes',
        focus: 'Recovery',
        icon: '🌿',
      ),
    ],
  ),
];
