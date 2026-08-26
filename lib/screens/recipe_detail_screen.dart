import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../services/plan_engine.dart';
import '../widgets/recipe_image.dart';
import '../widgets/shared_ui.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.profile,
  });

  final Recipe recipe;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final engine = const PlanEngine();
    final servingScale = engine.suggestedServingScale(recipe, profile);
    final plannedMeal = PlannedMeal(
      mealType: recipe.mealType,
      recipe: recipe,
      servingScale: servingScale,
      fitReason: engine.recipeFitReason(recipe, profile),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 390,
            pinned: true,
            backgroundColor: AppPalette.ink,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.38),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _RecipeHero(recipe: recipe),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 42),
                decoration: const BoxDecoration(
                  color: AppPalette.canvas,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PersonalFitCard(
                      profile: profile,
                      plannedMeal: plannedMeal,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppPalette.line),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(recipe.description, style: context.text.bodyLarge),
                    const SizedBox(height: 22),
                    _NutritionStrip(recipe: recipe),
                    const SizedBox(height: 7),
                    const Text(
                      'Nutrition shown per standard serving.',
                      style: TextStyle(color: AppPalette.muted, fontSize: 11),
                    ),
                    if (recipe.allergens.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppPalette.sun.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Contains: ${recipe.allergens.join(', ')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    const SectionHeader(
                      title: 'Ingredients',
                      subtitle: 'Measured for one standard serving',
                    ),
                    const SizedBox(height: 14),
                    ...recipe.ingredients.map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppPalette.lime.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, size: 15),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  ingredient,
                                  style: context.text.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionHeader(
                      title: 'Make it',
                      subtitle: 'Step-by-step, with no guesswork',
                    ),
                    const SizedBox(height: 14),
                    ...recipe.steps.asMap().entries.map(
                      (entry) =>
                          _StepCard(number: entry.key + 1, text: entry.value),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Nutrition values are practical estimates and vary with ingredient brands, oil and portion size.',
                      style: context.text.bodyMedium?.copyWith(
                        color: AppPalette.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeHero extends StatelessWidget {
  const _RecipeHero({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RecipeImage(recipe: recipe),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x18000000), Color(0xE8000F0C)],
              stops: [0.30, 1],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 47,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.mealType.toUpperCase(),
                style: const TextStyle(
                  color: AppPalette.lime,
                  letterSpacing: 1.7,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                recipe.name,
                style: context.text.displayMedium?.copyWith(
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${recipe.prepMinutes} min',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.restaurant_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${recipe.servings} serving',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonalFitCard extends StatelessWidget {
  const _PersonalFitCard({required this.profile, required this.plannedMeal});

  final UserProfile profile;
  final PlannedMeal plannedMeal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.lime.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppPalette.lime.withValues(alpha: 0.44)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppPalette.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why it fits ${profile.goal.toLowerCase()}',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  plannedMeal.fitReason,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suggested: ${plannedMeal.portionLabel} · ${plannedMeal.calories} kcal · ${plannedMeal.protein}g protein',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionStrip extends StatelessWidget {
  const _NutritionStrip({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('${recipe.calories}', 'kcal'),
      ('${recipe.protein}g', 'protein'),
      ('${recipe.carbs}g', 'carbs'),
      ('${recipe.fat}g', 'fat'),
      ('${recipe.fiber}g', 'fibre'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 3;
          return Wrap(
            runSpacing: 14,
            children: items
                .map(
                  (item) => SizedBox(
                    width: itemWidth,
                    child: _NutritionItem(value: item.$1, label: item.$2),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  const _NutritionItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppPalette.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppPalette.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppPalette.lime,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}
