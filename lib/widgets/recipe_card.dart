import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.compact = false,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(recipe.id);
    return Semantics(
      button: true,
      label: 'Open ${recipe.name} recipe',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            width: compact ? 270 : double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Text(
                        recipe.emoji,
                        style: const TextStyle(fontSize: 31),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.ink.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${recipe.prepMinutes} min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontSize: 21,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${recipe.mealType}  ·  ${recipe.dietType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.ink.withValues(alpha: 0.62),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    _MicroStat(value: '${recipe.calories}', label: 'kcal'),
                    const _DotDivider(),
                    _MicroStat(value: '${recipe.protein}g', label: 'protein'),
                    const _DotDivider(),
                    _MicroStat(value: '${recipe.fiber}g', label: 'fiber'),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: AppPalette.ink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<Color> _gradientFor(String id) {
    final palettes = <List<Color>>[
      const [Color(0xFFE7F9A9), Color(0xFFB9F227)],
      const [Color(0xFFFFE3C7), Color(0xFFFFA978)],
      const [Color(0xFFD9F7EE), Color(0xFF77D8B9)],
      const [Color(0xFFE5E0FF), Color(0xFFA99BFF)],
      const [Color(0xFFFFE6E1), Color(0xFFFF9C87)],
    ];
    return palettes[id.codeUnits.fold<int>(0, (sum, item) => sum + item) %
        palettes.length];
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 9.5,
            color: AppPalette.ink.withValues(alpha: 0.52),
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
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: AppPalette.ink.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    ),
  );
}
