import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/core/app_theme.dart';
import 'package:nourish/models/recipe.dart';
import 'package:nourish/models/user_profile.dart';
import 'package:nourish/screens/recipe_detail_screen.dart';
import 'package:nourish/widgets/recipe_card.dart';

void main() {
  testWidgets('recipe card renders nutrition and opens details', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: RecipeCard(recipe: _recipe, onTap: () => tapped = true),
          ),
        ),
      ),
    );

    expect(find.text('Paneer Power Bowl'), findsOneWidget);
    expect(find.text('520'), findsOneWidget);
    expect(find.text('34g'), findsOneWidget);

    await tester.tap(find.text('Paneer Power Bowl'));
    expect(tapped, isTrue);
  });

  testWidgets('recipe details show personal fit, fibre, and cooking steps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const RecipeDetailScreen(recipe: _recipe, profile: _profile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Why it fits build muscle'), findsOneWidget);
    expect(find.text('fibre'), findsOneWidget);
    expect(find.textContaining('Suggested:'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Make it'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Paneer'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _recipe = Recipe(
  id: 'paneer_power_bowl',
  name: 'Paneer Power Bowl',
  description: 'Balanced test recipe',
  dietType: 'Vegetarian',
  mealType: 'Lunch',
  emoji: '🥙',
  imageAsset: 'assets/images/recipes/paneer_power_bowl.webp',
  calories: 520,
  protein: 34,
  carbs: 54,
  fat: 20,
  fiber: 10,
  prepMinutes: 25,
  servings: 1,
  tags: ['High protein'],
  goalTags: ['Build muscle'],
  allergens: ['Dairy'],
  ingredients: ['Paneer'],
  steps: ['Cook'],
);

const _profile = UserProfile(
  uid: 'test-user',
  name: 'Test User',
  email: 'test@example.com',
  age: 30,
  gender: 'Male',
  heightCm: 170,
  weightKg: 70,
  goal: 'Build muscle',
  dietType: 'Vegetarian',
  activityLevel: 'Moderately active',
  workoutDays: 3,
  availableWorkoutDays: ['MON', 'WED', 'FRI'],
  sessionMinutes: 35,
  equipment: ['Bodyweight'],
  avoidFoods: [],
  onboardingComplete: true,
);
