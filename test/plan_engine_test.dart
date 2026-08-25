import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/models/exercise_guide.dart';
import 'package:nourish/models/recipe.dart';
import 'package:nourish/models/user_profile.dart';
import 'package:nourish/services/plan_engine.dart';

void main() {
  const engine = PlanEngine();

  test('calculates realistic personalized targets', () {
    final profile = _profile(goal: 'Lose fat');

    expect(profile.bmi, closeTo(24.22, 0.02));
    expect(profile.calorieTarget, lessThan(profile.maintenanceCalories));
    expect(profile.proteinTarget, 112);
    expect(profile.waterTargetMl, 2450);
  });

  test('recipe recommendations honor diet and allergen filters', () {
    final profile = _profile(
      dietType: 'Vegetarian',
      avoidFoods: const ['Dairy'],
    );

    final results = engine.recommendRecipes(_recipes, profile);

    expect(results.map((item) => item.id), ['vegan_bowl']);
  });

  test('workout plan matches availability and bodyweight equipment', () {
    final profile = _profile(
      goal: 'Build muscle',
      workoutDays: 5,
      availableWorkoutDays: const ['MON', 'WED', 'THU', 'SAT', 'SUN'],
      sessionMinutes: 20,
    );

    final plan = engine.buildWorkoutPlan(profile);

    expect(plan.days, hasLength(5));
    expect(plan.days.map((day) => day.dayLabel), [
      'MON',
      'WED',
      'THU',
      'SAT',
      'SUN',
    ]);
    expect(plan.days.every((day) => day.durationMinutes == 20), isTrue);
    expect(plan.days.every((day) => day.exercises.length == 4), isTrue);
    expect(
      plan.days
          .expand((day) => day.exercises)
          .any((item) => item.name.contains('Dumbbell')),
      isFalse,
    );

    expect(plan.nextWorkout(DateTime(2026, 8, 27)).dayLabel, 'THU');
    expect(plan.nextWorkout(DateTime(2026, 8, 28)).dayLabel, 'SAT');
    expect(plan.nextWorkout(DateTime(2026, 8, 30)).dayLabel, 'SUN');
  });

  test('every generated exercise has coaching and a professional demo', () {
    const goals = ['Build muscle', 'Lose fat', 'Maintain weight'];
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final generatedNames = <String>{};

    for (final goal in goals) {
      for (final equipment in const [
        ['Bodyweight'],
        ['Bodyweight', 'Dumbbells'],
      ]) {
        final plan = engine.buildWorkoutPlan(
          _profile(
            goal: goal,
            workoutDays: 6,
            availableWorkoutDays: days,
            sessionMinutes: 45,
            equipment: equipment,
          ),
        );
        generatedNames.addAll(
          plan.days.expand((day) => day.exercises).map((item) => item.name),
        );
      }
    }

    expect(generatedNames, hasLength(33));
    expect(
      generatedNames.difference(ExerciseGuideCatalog.coveredExerciseNames),
      isEmpty,
    );
    expect(
      ExerciseGuideCatalog.coveredExerciseNames.difference(generatedNames),
      isEmpty,
    );
    expect(
      generatedNames.difference(ExerciseGuideCatalog.coveredDemoNames),
      isEmpty,
    );
    for (final exerciseName in generatedNames) {
      final demo = ExerciseGuideCatalog.demoForName(exerciseName);
      expect(demo, isNotNull, reason: '$exerciseName needs a demonstration');
      expect(demo!.exerciseDbId, hasLength(7));
      expect(demo.mediaUrl, startsWith('https://static.exercisedb.dev/media/'));
      expect(demo.sourceName, isNotEmpty);
    }
  });
}

UserProfile _profile({
  String goal = 'Lose fat',
  String dietType = 'Vegetarian',
  int workoutDays = 4,
  int sessionMinutes = 35,
  List<String>? availableWorkoutDays,
  List<String> avoidFoods = const [],
  List<String> equipment = const ['Bodyweight'],
}) {
  return UserProfile(
    uid: 'test-user',
    name: 'Test User',
    email: 'test@example.com',
    age: 30,
    gender: 'Male',
    heightCm: 170,
    weightKg: 70,
    goal: goal,
    dietType: dietType,
    activityLevel: 'Moderately active',
    workoutDays: workoutDays,
    availableWorkoutDays:
        availableWorkoutDays ?? suggestedWorkoutDays(workoutDays),
    sessionMinutes: sessionMinutes,
    equipment: equipment,
    avoidFoods: avoidFoods,
    onboardingComplete: true,
  );
}

const _recipes = [
  Recipe(
    id: 'paneer',
    name: 'Paneer Bowl',
    description: '',
    dietType: 'Vegetarian',
    mealType: 'Lunch',
    emoji: '🥙',
    calories: 500,
    protein: 30,
    carbs: 50,
    fat: 18,
    fiber: 8,
    prepMinutes: 20,
    servings: 1,
    tags: ['High protein'],
    goalTags: ['Build muscle'],
    allergens: ['Dairy'],
    ingredients: [],
    steps: [],
  ),
  Recipe(
    id: 'vegan_bowl',
    name: 'Vegan Bowl',
    description: '',
    dietType: 'Vegan',
    mealType: 'Lunch',
    emoji: '🌱',
    calories: 430,
    protein: 22,
    carbs: 64,
    fat: 10,
    fiber: 15,
    prepMinutes: 25,
    servings: 1,
    tags: ['High fiber'],
    goalTags: ['Lose fat'],
    allergens: [],
    ingredients: [],
    steps: [],
  ),
  Recipe(
    id: 'chicken',
    name: 'Chicken Plate',
    description: '',
    dietType: 'Non-vegetarian',
    mealType: 'Dinner',
    emoji: '🍗',
    calories: 520,
    protein: 48,
    carbs: 45,
    fat: 15,
    fiber: 5,
    prepMinutes: 30,
    servings: 1,
    tags: ['High protein'],
    goalTags: ['Build muscle'],
    allergens: [],
    ingredients: [],
    steps: [],
  ),
];
