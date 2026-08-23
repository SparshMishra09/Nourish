import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/core/app_theme.dart';
import 'package:nourish/models/recipe.dart';
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
}

const _recipe = Recipe(
  id: 'paneer_power_bowl',
  name: 'Paneer Power Bowl',
  description: 'Balanced test recipe',
  dietType: 'Vegetarian',
  mealType: 'Lunch',
  emoji: '🥙',
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
