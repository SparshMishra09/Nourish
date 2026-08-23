import 'food_analysis.dart';
import 'user_profile.dart';

class DailyGoalEvaluation {
  const DailyGoalEvaluation({
    required this.energyReady,
    required this.proteinReady,
    required this.fiberReady,
    required this.waterReady,
    required this.workoutReady,
  });

  final bool energyReady;
  final bool proteinReady;
  final bool fiberReady;
  final bool waterReady;
  final bool workoutReady;

  bool get isComplete =>
      energyReady && proteinReady && fiberReady && waterReady && workoutReady;

  int get completedChecks => [
    energyReady,
    proteinReady,
    fiberReady,
    waterReady,
    workoutReady,
  ].where((ready) => ready).length;
}

abstract final class DailyGoalEvaluator {
  static DailyGoalEvaluation evaluate({
    required UserProfile profile,
    required DailyNutrition nutrition,
    required int waterLoggedMl,
    required bool workoutScheduled,
    required bool workoutCompleted,
  }) {
    final calorieRatio = nutrition.calories / profile.calorieTarget;
    return DailyGoalEvaluation(
      // A practical range avoids rewarding under-fuelling or requiring an
      // impossible exact calorie match.
      energyReady: calorieRatio >= 0.9 && calorieRatio <= 1.1,
      proteinReady: nutrition.protein >= profile.proteinTarget * 0.9,
      fiberReady: nutrition.fiber >= profile.fiberTarget * 0.8,
      waterReady: waterLoggedMl >= profile.waterTargetMl,
      workoutReady: !workoutScheduled || workoutCompleted,
    );
  }
}
