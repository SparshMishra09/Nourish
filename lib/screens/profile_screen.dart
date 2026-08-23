import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/user_profile.dart';
import '../widgets/shared_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onEditPlan,
    required this.onSignOut,
    this.photoUrl,
  });

  final UserProfile profile;
  final String? photoUrl;
  final VoidCallback onEditPlan;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('profile'),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 16,
              20,
              30,
            ),
            decoration: const BoxDecoration(
              color: AppPalette.ink,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileAvatarButton(
                    name: profile.name,
                    photoUrl: photoUrl,
                    onTap: () {},
                  ),
                  const SizedBox(height: 25),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: context.text.displayMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              profile.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.52),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: onEditPlan,
                        style: IconButton.styleFrom(
                          backgroundColor: AppPalette.lime,
                          foregroundColor: AppPalette.ink,
                        ),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      _ProfileStat(value: '${profile.age}', label: 'years'),
                      _ProfileStat(
                        value: '${profile.heightCm.round()}',
                        label: 'cm',
                      ),
                      _ProfileStat(
                        value: '${profile.weightKg.round()}',
                        label: 'kg',
                      ),
                      _ProfileStat(
                        value: profile.bmi.toStringAsFixed(1),
                        label: 'BMI*',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Your plan',
              subtitle: 'The choices shaping recommendations',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppPalette.line),
              ),
              child: Column(
                children: [
                  _PlanRow(icon: '🎯', label: 'Goal', value: profile.goal),
                  const Divider(height: 25),
                  _PlanRow(
                    icon: '🥗',
                    label: 'Food style',
                    value: profile.dietType,
                  ),
                  const Divider(height: 25),
                  _PlanRow(
                    icon: '🏋️',
                    label: 'Training',
                    value:
                        '${profile.availableWorkoutDays.join(', ')} · ${profile.sessionMinutes} min',
                  ),
                  const Divider(height: 25),
                  _PlanRow(
                    icon: '⚡',
                    label: 'Activity',
                    value: profile.activityLevel,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Daily targets',
              subtitle: 'Estimated from your profile',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _TargetCard(
                    icon: Icons.local_fire_department_rounded,
                    color: AppPalette.coral,
                    value: '${profile.calorieTarget}',
                    label: 'kcal',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TargetCard(
                    icon: Icons.fitness_center_rounded,
                    color: AppPalette.violet,
                    value: '${profile.proteinTarget}',
                    label: 'protein g',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TargetCard(
                    icon: Icons.water_drop_rounded,
                    color: AppPalette.mint,
                    value: (profile.waterTargetMl / 1000).toStringAsFixed(1),
                    label: 'water L',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF9F3), Color(0xFFF2F8DD)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppPalette.ink),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Private by design',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your profile, meals and workouts are stored under your own Firebase user ID and are not readable by other users.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(
            child: OutlinedButton.icon(
              onPressed: onEditPlan,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Edit goals and preferences'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                foregroundColor: AppPalette.ink,
                side: const BorderSide(color: AppPalette.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 125),
          sliver: SliverToBoxAdapter(
            child: TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(foregroundColor: AppPalette.coral),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppPalette.muted, fontSize: 12.5),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(color: AppPalette.muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
