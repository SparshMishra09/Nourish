import 'recipe.dart';

class PlannedMeal {
  const PlannedMeal({
    required this.mealType,
    required this.recipe,
    required this.servingScale,
    required this.fitReason,
  });

  final String mealType;
  final Recipe recipe;
  final double servingScale;
  final String fitReason;

  int get calories => (recipe.calories * servingScale).round();
  int get protein => (recipe.protein * servingScale).round();

  String get portionLabel {
    if (servingScale <= 0.87) return '¾ serving';
    if (servingScale <= 1.12) return '1 serving';
    if (servingScale <= 1.37) return '1¼ servings';
    return '1½ servings';
  }
}

class DailyMealPlan {
  const DailyMealPlan({
    required this.meals,
    required this.calorieTarget,
    required this.proteinTarget,
  });

  final List<PlannedMeal> meals;
  final int calorieTarget;
  final int proteinTarget;

  int get plannedCalories =>
      meals.fold(0, (total, meal) => total + meal.calories);
  int get plannedProtein =>
      meals.fold(0, (total, meal) => total + meal.protein);
  bool get isComplete => meals.length == 4;
}
