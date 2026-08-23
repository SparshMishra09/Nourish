import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/food_analysis.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../widgets/metric_ring.dart';
import '../widgets/recipe_card.dart';
import '../widgets/shared_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.profile,
    required this.recipes,
    required this.workoutPlan,
    required this.nutrition,
    required this.waterLoggedMl,
    required this.completedWorkouts,
    required this.onProfileTap,
    required this.onRecipeTap,
    required this.onNutritionTap,
    required this.onScanTap,
    required this.onWaterTap,
    required this.onWorkoutTap,
    this.photoUrl,
  });

  final UserProfile profile;
  final List<Recipe> recipes;
  final WorkoutPlan workoutPlan;
  final DailyNutrition nutrition;
  final int waterLoggedMl;
  final int completedWorkouts;
  final String? photoUrl;
  final VoidCallback onProfileTap;
  final ValueChanged<Recipe> onRecipeTap;
  final VoidCallback onNutritionTap;
  final VoidCallback onScanTap;
  final VoidCallback onWaterTap;
  final VoidCallback onWorkoutTap;

  @override
  Widget build(BuildContext context) {
    final today = workoutPlan.nextWorkout(DateTime.now());
    return CustomScrollView(
      key: const PageStorageKey('dashboard'),
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
                  name: profile.name,
                  photoUrl: photoUrl,
                  onTap: onProfileTap,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        profile.name.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleLarge,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.line),
                  ),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Today, made\nfor your goal.',
              style: context.text.displayMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _DailyCard(
              profile: profile,
              nutrition: nutrition,
              waterLoggedMl: waterLoggedMl,
              onWaterTap: onWaterTap,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverToBoxAdapter(child: _ScanMealBanner(onTap: onScanTap)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Picked for you',
              subtitle: '${profile.dietType} · ${profile.goal}',
              actionLabel: 'See all',
              onAction: onNutritionTap,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 262,
            child: recipes.isEmpty
                ? const Center(child: Text('No matching recipes yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: recipes.take(5).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) => RecipeCard(
                      recipe: recipes[index],
                      compact: true,
                      onTap: () => onRecipeTap(recipes[index]),
                    ),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Your next workout',
              subtitle: '${workoutPlan.daysPerWeek} training days this week',
              actionLabel: 'Plan',
              onAction: onWorkoutTap,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _WorkoutPreview(day: today, onTap: onWorkoutTap),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 125),
          sliver: SliverToBoxAdapter(
            child: _MomentumCard(
              completedWorkouts: completedWorkouts,
              workoutTarget: workoutPlan.daysPerWeek,
              date: DateFormat('EEEE, d MMMM').format(DateTime.now()),
            ),
          ),
        ),
      ],
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.profile,
    required this.nutrition,
    required this.waterLoggedMl,
    required this.onWaterTap,
  });
  final UserProfile profile;
  final DailyNutrition nutrition;
  final int waterLoggedMl;
  final VoidCallback onWaterTap;

  @override
  Widget build(BuildContext context) {
    final calorieProgress = nutrition.calories / profile.calorieTarget;
    final remaining = (profile.calorieTarget - nutrition.calories).clamp(
      0,
      profile.calorieTarget,
    );
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY ENERGY',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$remaining kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    Text(
                      'remaining of ${profile.calorieTarget}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.lime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        profile.goal,
                        style: const TextStyle(
                          color: AppPalette.lime,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              MetricRing(
                progress: calorieProgress,
                value: '${nutrition.calories}',
                label: 'eaten',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _MacroProgress(
                  label: 'Protein',
                  value: nutrition.protein.round(),
                  target: profile.proteinTarget,
                  color: AppPalette.mint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgress(
                  label: 'Carbs',
                  value: nutrition.carbs.round(),
                  target: profile.carbTarget,
                  color: AppPalette.sun,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MacroProgress(
                  label: 'Fibre',
                  value: nutrition.fiber.round(),
                  target: profile.fiberTarget,
                  color: AppPalette.coral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgress(
                  label: 'Water +',
                  value: waterLoggedMl,
                  target: profile.waterTargetMl,
                  color: AppPalette.violet,
                  unit: 'ml',
                  onTap: onWaterTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.unit = 'g',
    this.onTap,
  });
  final String label;
  final int value;
  final int target;
  final Color color;
  final String unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$value/$target$unit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: (value / target).clamp(0, 1),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanMealBanner extends StatelessWidget {
  const _ScanMealBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8FFF5), Color(0xFFF1F8D9)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.mint.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppPalette.mint,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log what you actually ate',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Scan the whole plate, confirm the portion, done.',
                      style: TextStyle(color: AppPalette.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutPreview extends StatelessWidget {
  const _WorkoutPreview({required this.day, required this.onTap});
  final WorkoutDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: AppPalette.line),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppPalette.violet, Color(0xFFB7AEFF)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.title, style: context.text.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      day.subtitle,
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppPalette.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${day.durationMinutes} min',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Icon(
                          Icons.format_list_numbered_rounded,
                          size: 16,
                          color: AppPalette.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${day.exercises.length} moves',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard({
    required this.completedWorkouts,
    required this.workoutTarget,
    required this.date,
  });
  final int completedWorkouts;
  final int workoutTarget;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFFBD0), Color(0xFFFDF9E8)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppPalette.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: AppPalette.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontSize: 11, color: AppPalette.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  '$completedWorkouts of $workoutTarget workouts complete',
                  style: context.text.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
