import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../widgets/shared_ui.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.profile,
    required this.plan,
    required this.onProfileTap,
    required this.onCompleteWorkout,
    this.photoUrl,
  });

  final UserProfile profile;
  final WorkoutPlan plan;
  final VoidCallback onProfileTap;
  final Future<void> Function(WorkoutDay day) onCompleteWorkout;
  final String? photoUrl;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selected = 0;
  bool _completing = false;
  final Set<int> _completed = {};

  Future<void> _completeDay() async {
    setState(() => _completing = true);
    try {
      await widget.onCompleteWorkout(widget.plan.days[_selected]);
      if (mounted) {
        setState(() => _completed.add(_selected));
        showAppMessage(context, 'Workout complete — strong work.');
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Could not save your workout. Try again.');
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.plan.days[_selected];
    return CustomScrollView(
      key: const PageStorageKey('workouts'),
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
                    color: AppPalette.violet.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${widget.plan.daysPerWeek} DAYS / WEEK',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.7,
                    ),
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
                Text('Move with\npurpose.', style: context.text.displayMedium),
                const SizedBox(height: 11),
                Text(
                  'A ${widget.profile.goal.toLowerCase()} plan shaped for ${widget.profile.sessionMinutes} minutes and your equipment.',
                  style: const TextStyle(color: AppPalette.muted, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              scrollDirection: Axis.horizontal,
              itemCount: widget.plan.days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final planDay = widget.plan.days[index];
                final selected = index == _selected;
                return InkWell(
                  onTap: () => setState(() => _selected = index),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 210),
                    width: 75,
                    decoration: BoxDecoration(
                      color: selected ? AppPalette.ink : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppPalette.ink : AppPalette.line,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          planDay.dayLabel,
                          style: TextStyle(
                            color: selected ? Colors.white : AppPalette.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Icon(
                          _completed.contains(index)
                              ? Icons.check_circle_rounded
                              : Icons.fitness_center_rounded,
                          color: selected ? AppPalette.lime : AppPalette.ink,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
          sliver: SliverToBoxAdapter(child: _WorkoutHero(day: day)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 13),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Exercise flow',
              subtitle: '${day.exercises.length} moves · warm up first',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: day.exercises.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ExerciseCard(index: index, exercise: day.exercises[index]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.sun.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Stop if you feel sharp pain, dizziness or unusual discomfort. Choose clean form over more reps.',
                          style: TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const ValueKey('completeWorkout'),
                  onPressed: _completing || _completed.contains(_selected)
                      ? null
                      : _completeDay,
                  icon: _completing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _completed.contains(_selected)
                              ? Icons.check_circle_rounded
                              : Icons.flag_rounded,
                        ),
                  label: Text(
                    _completed.contains(_selected)
                        ? 'Completed today'
                        : 'Mark workout complete',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({required this.day});
  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8D7BFF), Color(0xFF5C49DE)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppPalette.violet.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 3,
            child: Icon(
              Icons.sports_gymnastics_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 98,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${day.durationMinutes} MIN SESSION',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                day.title,
                style: context.text.headlineLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                day.subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.66)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.index, required this.exercise});
  final int index;
  final ExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: index.isEven
                  ? AppPalette.lime.withValues(alpha: 0.28)
                  : AppPalette.violet.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(exercise.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: context.text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  exercise.focus,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppPalette.canvas,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              exercise.detail,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
