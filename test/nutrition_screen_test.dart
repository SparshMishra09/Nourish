import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/core/app_theme.dart';
import 'package:nourish/models/recipe.dart';
import 'package:nourish/models/user_profile.dart';
import 'package:nourish/screens/nutrition_screen.dart';
import 'package:nourish/widgets/recipe_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('meal screen renders a complete personalized photo plan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recipes = <Recipe>[];
    for (final asset in const [
      'assets/data/recipes.json',
      'assets/data/recipe_expansion.json',
      'assets/data/recipe_expansion_v2.json',
      'assets/data/recipe_sides.json',
    ]) {
      final source = await rootBundle.loadString(asset);
      final records = jsonDecode(source) as List<dynamic>;
      recipes.addAll(
        records.map((record) {
          final map = Map<String, dynamic>.from(record as Map);
          return Recipe.fromMap(map.remove('id') as String, map);
        }),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NutritionScreen(
            profile: _profile,
            recipes: recipes,
            onProfileTap: () {},
            onRecipeTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YOUR DAY, PLANNED'), findsOneWidget);
    expect(find.byType(RecipeImage), findsAtLeastNWidgets(4));
    expect(
      find.textContaining('Only food you scan or log changes Today'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('All'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sides'));
    await tester.pumpAndSettle();
    expect(find.text('20 recipes'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Recommended'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('20 recipes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _profile = UserProfile(
  uid: 'meal-ui-test',
  name: 'Meal Test',
  email: 'meal@example.com',
  age: 29,
  gender: 'Female',
  heightCm: 165,
  weightKg: 65,
  goal: 'Lose fat',
  dietType: 'Non-vegetarian',
  activityLevel: 'Moderately active',
  workoutDays: 3,
  availableWorkoutDays: ['MON', 'WED', 'FRI'],
  sessionMinutes: 35,
  equipment: ['Bodyweight'],
  avoidFoods: [],
  onboardingComplete: true,
);
