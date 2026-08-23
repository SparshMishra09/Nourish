import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/models/daily_goal.dart';
import 'package:nourish/models/food_analysis.dart';
import 'package:nourish/models/user_profile.dart';

void main() {
  final profile = _profile();

  test(
    'daily goal completes when essentials and planned workout are ready',
    () {
      final nutrition = DailyNutrition(
        calories: (profile.calorieTarget * 0.95).round(),
        protein: profile.proteinTarget.toDouble(),
        fiber: profile.fiberTarget.toDouble(),
      );

      final result = DailyGoalEvaluator.evaluate(
        profile: profile,
        nutrition: nutrition,
        waterLoggedMl: profile.waterTargetMl,
        workoutScheduled: true,
        workoutCompleted: true,
      );

      expect(result.isComplete, isTrue);
      expect(result.completedChecks, 5);
    },
  );

  test('scheduled workout is required but a rest-day workout is not', () {
    final nutrition = DailyNutrition(
      calories: profile.calorieTarget,
      protein: profile.proteinTarget.toDouble(),
      fiber: profile.fiberTarget.toDouble(),
    );

    final trainingDay = DailyGoalEvaluator.evaluate(
      profile: profile,
      nutrition: nutrition,
      waterLoggedMl: profile.waterTargetMl,
      workoutScheduled: true,
      workoutCompleted: false,
    );
    final restDay = DailyGoalEvaluator.evaluate(
      profile: profile,
      nutrition: nutrition,
      waterLoggedMl: profile.waterTargetMl,
      workoutScheduled: false,
      workoutCompleted: false,
    );

    expect(trainingDay.isComplete, isFalse);
    expect(trainingDay.workoutReady, isFalse);
    expect(restDay.isComplete, isTrue);
  });

  test('energy must stay in a practical target range', () {
    final result = DailyGoalEvaluator.evaluate(
      profile: profile,
      nutrition: DailyNutrition(
        calories: (profile.calorieTarget * 1.2).round(),
        protein: profile.proteinTarget.toDouble(),
        fiber: profile.fiberTarget.toDouble(),
      ),
      waterLoggedMl: profile.waterTargetMl,
      workoutScheduled: false,
      workoutCompleted: false,
    );

    expect(result.energyReady, isFalse);
    expect(result.isComplete, isFalse);
  });
}

UserProfile _profile() => const UserProfile(
  uid: 'goal-test',
  name: 'Goal Tester',
  email: 'goal@example.com',
  age: 30,
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
