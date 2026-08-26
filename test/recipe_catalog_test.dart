import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/models/recipe.dart';
import 'package:nourish/models/user_profile.dart';
import 'package:nourish/services/plan_engine.dart';
import 'package:nourish/services/recipe_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Recipe> bundled;

  setUpAll(() async {
    bundled = await _loadBundledRecipes();
  });

  test(
    'every bundled recipe is complete and has a packaged food photo',
    () async {
      expect(bundled, hasLength(100));
      expect(bundled.map((recipe) => recipe.id).toSet(), hasLength(100));
      expect(bundled.every((recipe) => recipe.isComplete), isTrue);
      expect(
        bundled.map((recipe) => recipe.imageAsset).toSet(),
        hasLength(100),
      );

      for (final recipe in bundled) {
        expect(recipe.description, isNotEmpty, reason: recipe.id);
        expect(
          recipe.ingredients.length,
          greaterThanOrEqualTo(6),
          reason: recipe.id,
        );
        expect(recipe.steps.length, greaterThanOrEqualTo(4), reason: recipe.id);
        expect(recipe.fiber, greaterThan(0), reason: recipe.id);
        expect(recipe.goalTags, isNotEmpty, reason: recipe.id);
        final image = await rootBundle.load(recipe.imageAsset);
        expect(image.lengthInBytes, greaterThan(50000), reason: recipe.id);
      }
    },
  );

  test('catalog is balanced across all four meal categories', () {
    for (final mealType in const [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snack',
      'Side',
    ]) {
      expect(
        bundled.where((recipe) => recipe.mealType == mealType),
        hasLength(20),
        reason: '$mealType should have exactly 20 complete options',
      );
    }
  });

  test('side dishes stay simple and outside the four-slot daily plan', () {
    final sides = bundled.where((recipe) => recipe.mealType == 'Side').toList();

    expect(sides, hasLength(20));
    expect(sides.every((recipe) => recipe.prepMinutes <= 30), isTrue);
    expect(sides.every((recipe) => recipe.calories <= 250), isTrue);

    const engine = PlanEngine();
    final profile = _profile(
      dietType: 'Non-vegetarian',
      goal: 'Maintain weight',
    );
    expect(
      sides.every(
        (recipe) => engine.suggestedServingScale(recipe, profile) == 1,
      ),
      isTrue,
    );
    final plan = engine.buildDailyMealPlan(
      bundled,
      profile,
      date: DateTime(2026, 9, 10),
    );
    expect(plan.meals, hasLength(4));
    expect(plan.meals.any((meal) => meal.mealType == 'Side'), isFalse);
  });

  test(
    'recipe names stay unique after punctuation and spacing normalization',
    () {
      String normalized(String value) =>
          value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

      expect(
        bundled.map((recipe) => normalized(recipe.name)).toSet(),
        hasLength(bundled.length),
      );
    },
  );

  test('daily menu covers every meal for each supported diet and goal', () {
    const engine = PlanEngine();
    const diets = ['Vegan', 'Vegetarian', 'Non-vegetarian'];
    const goals = ['Lose fat', 'Build muscle', 'Maintain weight'];

    for (final diet in diets) {
      for (final goal in goals) {
        final profile = _profile(dietType: diet, goal: goal);
        final plan = engine.buildDailyMealPlan(bundled, profile);

        expect(plan.isComplete, isTrue, reason: '$diet / $goal');
        expect(plan.meals.map((meal) => meal.mealType).toSet(), {
          'Breakfast',
          'Lunch',
          'Dinner',
          'Snack',
        }, reason: '$diet / $goal');
        expect(
          plan.meals.every((meal) => meal.recipe.supportsDiet(diet)),
          isTrue,
        );
        expect(
          plan.meals.every(
            (meal) => meal.servingScale >= 0.75 && meal.servingScale <= 1.5,
          ),
          isTrue,
        );
      }
    }
  });

  test('daily menu respects allergens before scoring recipes', () {
    const engine = PlanEngine();
    final plan = engine.buildDailyMealPlan(
      bundled,
      _profile(
        dietType: 'Vegetarian',
        goal: 'Lose fat',
        avoidFoods: const ['Dairy'],
      ),
    );

    expect(plan.isComplete, isTrue);
    expect(
      plan.meals.expand((meal) => meal.recipe.allergens),
      isNot(contains('Dairy')),
    );
  });

  test('strictest onboarding filters still produce four safe meals', () {
    const engine = PlanEngine();
    const blocked = [
      'Dairy',
      'Egg',
      'Gluten',
      'Peanut',
      'Soy',
      'Fish',
      'Shellfish',
      'Sesame',
      'Tree nuts',
    ];
    final plan = engine.buildDailyMealPlan(
      bundled,
      _profile(dietType: 'Vegan', goal: 'Maintain weight', avoidFoods: blocked),
    );

    expect(plan.isComplete, isTrue);
    expect(
      plan.meals
          .expand((meal) => meal.recipe.allergens)
          .toSet()
          .intersection(blocked.toSet()),
      isEmpty,
    );
  });

  test('daily menu is stable for a day and rotates top matches tomorrow', () {
    const engine = PlanEngine();
    final profile = _profile(dietType: 'Non-vegetarian', goal: 'Build muscle');
    final first = engine.buildDailyMealPlan(
      bundled,
      profile,
      date: DateTime(2026, 8, 26),
    );
    final repeated = engine.buildDailyMealPlan(
      bundled,
      profile,
      date: DateTime(2026, 8, 26, 23, 59),
    );
    final tomorrow = engine.buildDailyMealPlan(
      bundled,
      profile,
      date: DateTime(2026, 8, 27),
    );

    expect(
      first.meals.map((meal) => meal.recipe.id),
      repeated.meals.map((meal) => meal.recipe.id),
    );
    expect(
      first.meals.map((meal) => meal.recipe.id),
      isNot(tomorrow.meals.map((meal) => meal.recipe.id)),
    );
  });

  test(
    'expanded plans surface eight distinct matches per meal in eight days',
    () {
      const engine = PlanEngine();
      final profile = _profile(
        dietType: 'Non-vegetarian',
        goal: 'Maintain weight',
      );
      final seenByMeal = <String, Set<String>>{
        for (final meal in const ['Breakfast', 'Lunch', 'Dinner', 'Snack'])
          meal: <String>{},
      };

      for (var offset = 0; offset < 8; offset++) {
        final plan = engine.buildDailyMealPlan(
          bundled,
          profile,
          date: DateTime(2026, 9, 1 + offset),
        );
        for (final meal in plan.meals) {
          seenByMeal[meal.mealType]!.add(meal.recipe.id);
        }
      }

      for (final entry in seenByMeal.entries) {
        expect(entry.value, hasLength(8), reason: entry.key);
      }
    },
  );

  test('cloud overlays cannot remove bundled recipe essentials', () {
    final fallback = bundled.first;
    final partialCloudRecipe = Recipe.fromMap(fallback.id, {
      'name': '${fallback.name} Cloud',
      'calories': fallback.calories + 5,
    });

    final merged = RecipeCatalog.merge(
      bundled: bundled,
      remote: [partialCloudRecipe],
    );
    final result = merged.first;

    expect(result.name, '${fallback.name} Cloud');
    expect(result.calories, fallback.calories + 5);
    expect(result.imageAsset, fallback.imageAsset);
    expect(result.ingredients, fallback.ingredients);
    expect(result.steps, fallback.steps);
    expect(result.allergens, fallback.allergens);
    expect(result.isComplete, isTrue);
  });

  test('incomplete cloud-only recipes are ignored', () {
    final merged = RecipeCatalog.merge(
      bundled: bundled,
      remote: [
        Recipe.fromMap('unfinished', const {'name': 'Unfinished idea'}),
      ],
    );

    expect(merged, hasLength(bundled.length));
    expect(merged.any((recipe) => recipe.id == 'unfinished'), isFalse);
  });
}

Future<List<Recipe>> _loadBundledRecipes() async {
  const assets = [
    'assets/data/recipes.json',
    'assets/data/recipe_expansion.json',
    'assets/data/recipe_expansion_v2.json',
    'assets/data/recipe_sides.json',
  ];
  final recipes = <Recipe>[];
  for (final asset in assets) {
    final source = await rootBundle.loadString(asset);
    final records = jsonDecode(source) as List<dynamic>;
    recipes.addAll(
      records.map((record) {
        final map = Map<String, dynamic>.from(record as Map);
        return Recipe.fromMap(map.remove('id') as String, map);
      }),
    );
  }
  return recipes;
}

UserProfile _profile({
  required String dietType,
  required String goal,
  List<String> avoidFoods = const [],
}) {
  return UserProfile(
    uid: 'catalog-test',
    name: 'Catalog Test',
    email: 'catalog@example.com',
    age: 30,
    gender: 'Female',
    heightCm: 165,
    weightKg: 65,
    goal: goal,
    dietType: dietType,
    activityLevel: 'Moderately active',
    workoutDays: 3,
    availableWorkoutDays: const ['MON', 'WED', 'FRI'],
    sessionMinutes: 35,
    equipment: const ['Bodyweight'],
    avoidFoods: avoidFoods,
    onboardingComplete: true,
  );
}
