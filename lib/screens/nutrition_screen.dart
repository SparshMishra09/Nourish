import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../widgets/recipe_card.dart';
import '../widgets/shared_ui.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({
    super.key,
    required this.profile,
    required this.recipes,
    required this.onProfileTap,
    required this.onRecipeTap,
    this.photoUrl,
  });

  final UserProfile profile;
  final List<Recipe> recipes;
  final VoidCallback onProfileTap;
  final ValueChanged<Recipe> onRecipeTap;
  final String? photoUrl;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  String _mealFilter = 'All';
  String _query = '';

  List<Recipe> get _visibleRecipes {
    final normalized = _query.trim().toLowerCase();
    return widget.recipes.where((recipe) {
      final mealMatches =
          _mealFilter == 'All' || recipe.mealType == _mealFilter;
      final queryMatches =
          normalized.isEmpty ||
          recipe.name.toLowerCase().contains(normalized) ||
          recipe.tags.any((tag) => tag.toLowerCase().contains(normalized));
      return mealMatches && queryMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _visibleRecipes;
    return CustomScrollView(
      key: const PageStorageKey('nutrition'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 12,
              20,
              0,
            ),
            child: Row(
              children: [
                ProfileAvatarButton(
                  name: widget.profile.name,
                  photoUrl: widget.photoUrl,
                  onTap: widget.onProfileTap,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.lime.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(switch (widget.profile.dietType) {
                        'Vegan' => '🌱',
                        'Vegetarian' => '🥬',
                        _ => '🍗',
                      }),
                      const SizedBox(width: 6),
                      Text(
                        widget.profile.dietType,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Food that fits\nyour life.',
                  style: context.text.displayMedium,
                ),
                const SizedBox(height: 11),
                Text(
                  'Ranked for ${widget.profile.goal.toLowerCase()} and your daily nutrition targets.',
                  style: const TextStyle(color: AppPalette.muted, fontSize: 15),
                ),
                const SizedBox(height: 22),
                TextField(
                  key: const ValueKey('recipeSearch'),
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search recipes or benefits',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: const [
                'All',
                'Breakfast',
                'Lunch',
                'Dinner',
                'Snack',
              ].length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = const [
                  'All',
                  'Breakfast',
                  'Lunch',
                  'Dinner',
                  'Snack',
                ][index];
                final selected = filter == _mealFilter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) => setState(() => _mealFilter = filter),
                  selectedColor: AppPalette.ink,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  side: const BorderSide(color: AppPalette.line),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 13),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text('Recommended', style: context.text.headlineMedium),
                const Spacer(),
                Text(
                  '${recipes.length} recipes',
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (recipes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyRecipes(query: _query, filter: _mealFilter),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 125),
            sliver: SliverList.separated(
              itemCount: recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => RecipeCard(
                recipe: recipes[index],
                onTap: () => widget.onRecipeTap(recipes[index]),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyRecipes extends StatelessWidget {
  const _EmptyRecipes({required this.query, required this.filter});
  final String query;
  final String filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppPalette.lime.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.ramen_dining_rounded, size: 36),
            ),
            const SizedBox(height: 18),
            Text('No recipes found', style: context.text.headlineMedium),
            const SizedBox(height: 7),
            Text(
              query.isNotEmpty
                  ? 'Try a different search term.'
                  : 'No $filter recipes match all your current filters.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
