import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../widgets/exercise_guide_sheet.dart';
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
        if (!day.warmUp.isEmpty && !day.coolDown.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
            sliver: SliverToBoxAdapter(child: _WorkoutJourney(day: day)),
          ),
        if (!day.warmUp.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            sliver: SliverToBoxAdapter(
              child: _OptionalSupportBlock(
                key: ValueKey('${day.dayLabel}-warm-up'),
                block: day.warmUp,
                isWarmUp: true,
                initiallyExpanded: true,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 13),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Exercise flow',
              subtitle:
                  '${day.exercises.length} moves · tap any move for a professional demo',
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
        if (!day.coolDown.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _OptionalSupportBlock(
                key: ValueKey('${day.dayLabel}-cool-down'),
                block: day.coolDown,
                isWarmUp: false,
                initiallyExpanded: false,
              ),
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

class _WorkoutJourney extends StatelessWidget {
  const _WorkoutJourney({required this.day});

  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.lime,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'SMART FLOW',
                  style: TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '+${day.optionalExtraMinutes} min if you choose both',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _JourneyStep(
                  icon: Icons.local_fire_department_rounded,
                  label: 'PREP',
                  time: '~${day.warmUp.estimatedMinutes} min',
                  accent: AppPalette.sun,
                ),
              ),
              const _JourneyArrow(),
              Expanded(
                child: _JourneyStep(
                  icon: Icons.fitness_center_rounded,
                  label: 'TRAIN',
                  time: '${day.durationMinutes} min',
                  accent: AppPalette.lime,
                ),
              ),
              const _JourneyArrow(),
              Expanded(
                child: _JourneyStep(
                  icon: Icons.air_rounded,
                  label: 'RECOVER',
                  time: '~${day.coolDown.estimatedMinutes} min',
                  accent: AppPalette.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            'Prep and recovery are optional extras — your selected ${day.durationMinutes}-minute workout stays unchanged.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.icon,
    required this.label,
    required this.time,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: accent),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _JourneyArrow extends StatelessWidget {
  const _JourneyArrow();

  @override
  Widget build(BuildContext context) => Icon(
    Icons.arrow_forward_rounded,
    size: 15,
    color: Colors.white.withValues(alpha: 0.3),
  );
}

class _OptionalSupportBlock extends StatelessWidget {
  const _OptionalSupportBlock({
    super.key,
    required this.block,
    required this.isWarmUp,
    required this.initiallyExpanded,
  });

  final WorkoutSupportBlock block;
  final bool isWarmUp;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final accent = isWarmUp ? AppPalette.sun : AppPalette.mint;
    final tint = isWarmUp
        ? AppPalette.sun.withValues(alpha: 0.16)
        : AppPalette.mint.withValues(alpha: 0.16);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: const BorderSide(color: AppPalette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('${block.title}-${block.reason}'),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 15),
          leading: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isWarmUp
                  ? Icons.local_fire_department_rounded
                  : Icons.air_rounded,
              color: AppPalette.ink,
            ),
          ),
          title: Text(block.title, style: context.text.titleLarge),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              'OPTIONAL · ~${block.estimatedMinutes} MIN EXTRA',
              style: const TextStyle(
                color: AppPalette.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.65,
              ),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                block.reason,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < block.exercises.length; index++) ...[
              _SupportExerciseTile(
                exercise: block.exercises[index],
                accent: accent,
              ),
              if (index != block.exercises.length - 1)
                const SizedBox(height: 8),
            ],
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppPalette.muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isWarmUp
                        ? 'Keep every rep easy. The goal is readiness, not fatigue.'
                        : 'Use mild tension, never pain. Hold smoothly without bouncing.',
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportExerciseTile extends StatelessWidget {
  const _SupportExerciseTile({required this.exercise, required this.accent});

  final ExerciseItem exercise;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.canvas,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('support-${exercise.name}-${exercise.detail}'),
        onTap: () => showExerciseGuideSheet(context, exercise),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exercise.icon,
                  style: const TextStyle(fontSize: 19),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${exercise.detail} · ${exercise.focus}',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppPalette.ink,
                size: 24,
              ),
            ],
          ),
        ),
      ),
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppPalette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showExerciseGuideSheet(context, exercise),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
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
                    child: Text(
                      exercise.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: const BoxDecoration(
                        color: AppPalette.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppPalette.lime,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.focus} · watch demo',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.canvas,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  exercise.detail,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
