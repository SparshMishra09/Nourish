import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/recipe.dart';
import 'recipe_image.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.compact = false,
    this.fitLabel,
    this.portionLabel,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final bool compact;
  final String? fitLabel;
  final String? portionLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${recipe.name} recipe',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: compact ? 286 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: compact ? 148 : 184,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RecipeImage(recipe: recipe),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x6B000000)],
                            stops: [0.46, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 13,
                        top: 13,
                        child: _PhotoBadge(label: recipe.mealType),
                      ),
                      Positioned(
                        right: 13,
                        top: 13,
                        child: _PhotoBadge(
                          icon: Icons.schedule_rounded,
                          label: '${recipe.prepMinutes} min',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 18,
                    15,
                    compact ? 16 : 18,
                    17,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.ink,
                          fontSize: 20,
                          height: 1.06,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${recipe.dietType}  ·  ${portionLabel ?? '${recipe.servings} serving'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (fitLabel != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.lime.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            fitLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppPalette.ink,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _MicroStat(
                            value: '${recipe.calories}',
                            label: 'kcal',
                          ),
                          const _DotDivider(),
                          _MicroStat(
                            value: '${recipe.protein}g',
                            label: 'protein',
                          ),
                          const _DotDivider(),
                          _MicroStat(value: '${recipe.fiber}g', label: 'fibre'),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            color: AppPalette.ink,
                            size: 21,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.ink.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicroStat extends StatelessWidget {
  const _MicroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 9.5,
            color: AppPalette.muted,
          ),
        ),
      ],
    );
  }
}

class _DotDivider extends StatelessWidget {
  const _DotDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 9),
    child: Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: AppPalette.ink.withValues(alpha: 0.26),
        shape: BoxShape.circle,
      ),
    ),
  );
}
