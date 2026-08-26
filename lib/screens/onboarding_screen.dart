import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/user_profile.dart';
import '../widgets/brand_mark.dart';
import '../widgets/shared_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.initialProfile,
    required this.onComplete,
  });

  final UserProfile initialProfile;
  final Future<void> Function(UserProfile profile) onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  late UserProfile _profile;
  int _page = 0;
  bool _saving = false;

  static const _pageCount = 4;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await widget.onComplete(_profile.copyWith(onboardingComplete: true));
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Could not save your plan. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  const BrandMark(size: 40),
                  const Spacer(),
                  Text(
                    '${_page + 1} / $_pageCount',
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: (_page + 1) / _pageCount,
                  backgroundColor: AppPalette.line,
                  valueColor: const AlwaysStoppedAnimation(AppPalette.lime),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _BasicsStep(
                    profile: _profile,
                    onChanged: (profile) => setState(() => _profile = profile),
                  ),
                  _GoalStep(
                    profile: _profile,
                    onChanged: (profile) => setState(() => _profile = profile),
                  ),
                  _ScheduleStep(
                    profile: _profile,
                    onChanged: (profile) => setState(() => _profile = profile),
                  ),
                  _ReadyStep(profile: _profile),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    SizedBox.square(
                      dimension: 56,
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _controller.previousPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: const BorderSide(color: AppPalette.line),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppPalette.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('onboardingNext'),
                      onPressed: _saving ? null : _next,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _page == _pageCount - 1
                                      ? 'Build my plan'
                                      : 'Continue',
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AppPalette.limeDark,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: context.text.displayMedium),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(color: AppPalette.muted, fontSize: 15),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({required this.profile, required this.onChanged});
  final UserProfile profile;
  final ValueChanged<UserProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      eyebrow: 'Meet your body',
      title: 'A few numbers,\nsmarter targets.',
      subtitle:
          'We use these details to estimate energy and protein needs. You can edit them anytime.',
      child: Column(
        children: [
          _ValueSlider(
            label: 'Height',
            value: profile.heightCm,
            min: 130,
            max: 220,
            suffix: 'cm',
            onChanged: (value) => onChanged(profile.copyWith(heightCm: value)),
          ),
          const SizedBox(height: 14),
          _ValueSlider(
            label: 'Weight',
            value: profile.weightKg,
            min: 35,
            max: 180,
            suffix: 'kg',
            onChanged: (value) => onChanged(profile.copyWith(weightKg: value)),
          ),
          const SizedBox(height: 14),
          _ValueSlider(
            label: 'Age',
            value: profile.age.toDouble(),
            min: 16,
            max: 80,
            suffix: 'years',
            onChanged: (value) =>
                onChanged(profile.copyWith(age: value.round())),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Gender', style: context.text.titleMedium),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Male', 'Female', 'Prefer not to say']
                .map(
                  (gender) => ChoiceChip(
                    label: Text(gender),
                    selected: profile.gender == gender,
                    onSelected: (_) =>
                        onChanged(profile.copyWith(gender: gender)),
                    selectedColor: AppPalette.ink,
                    labelStyle: TextStyle(
                      color: profile.gender == gender
                          ? Colors.white
                          : AppPalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    side: const BorderSide(color: AppPalette.line),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.profile, required this.onChanged});
  final UserProfile profile;
  final ValueChanged<UserProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      eyebrow: 'Choose your direction',
      title: 'What are we\nworking toward?',
      subtitle:
          'Your goal changes calorie targets, recipe ranking and workout structure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChoiceTile(
            emoji: '🔥',
            title: 'Lose fat',
            subtitle: 'A sustainable calorie gap with filling meals',
            selected: profile.goal == 'Lose fat',
            onTap: () => onChanged(profile.copyWith(goal: 'Lose fat')),
          ),
          const SizedBox(height: 10),
          _ChoiceTile(
            emoji: '💪',
            title: 'Build muscle',
            subtitle: 'Protein-forward meals and progressive strength',
            selected: profile.goal == 'Build muscle',
            onTap: () => onChanged(profile.copyWith(goal: 'Build muscle')),
          ),
          const SizedBox(height: 10),
          _ChoiceTile(
            emoji: '⚖️',
            title: 'Maintain weight',
            subtitle: 'Balanced nutrition and all-round fitness',
            selected: profile.goal == 'Maintain weight',
            onTap: () => onChanged(profile.copyWith(goal: 'Maintain weight')),
          ),
          const SizedBox(height: 26),
          Text('Food preference', style: context.text.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: ['Vegetarian', 'Non-vegetarian', 'Vegan']
                .map(
                  (diet) => ChoiceChip(
                    avatar: Text(switch (diet) {
                      'Vegan' => '🌱',
                      'Vegetarian' => '🥬',
                      _ => '🍗',
                    }),
                    label: Text(diet),
                    selected: profile.dietType == diet,
                    onSelected: (_) =>
                        onChanged(profile.copyWith(dietType: diet)),
                    selectedColor: AppPalette.lime,
                    side: BorderSide(
                      color: profile.dietType == diet
                          ? AppPalette.limeDark
                          : AppPalette.line,
                    ),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('Avoid ingredients', style: context.text.titleLarge),
          const SizedBox(height: 5),
          const Text(
            'Optional allergy and preference filters',
            style: TextStyle(color: AppPalette.muted),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'Dairy',
                  'Egg',
                  'Gluten',
                  'Peanut',
                  'Soy',
                  'Fish',
                  'Shellfish',
                  'Sesame',
                  'Tree nuts',
                ].map((item) {
                  final selected = profile.avoidFoods.contains(item);
                  return FilterChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (value) {
                      final next = List<String>.from(profile.avoidFoods);
                      value ? next.add(item) : next.remove(item);
                      onChanged(profile.copyWith(avoidFoods: next));
                    },
                    selectedColor: AppPalette.coral.withValues(alpha: 0.2),
                    checkmarkColor: AppPalette.coral,
                    side: const BorderSide(color: AppPalette.line),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({required this.profile, required this.onChanged});
  final UserProfile profile;
  final ValueChanged<UserProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      eyebrow: 'Make it realistic',
      title: 'Fit the plan\ninto your week.',
      subtitle:
          'Tell us what you can genuinely sustain. Consistency beats an impossible plan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which days can you train?', style: context.text.titleLarge),
          const SizedBox(height: 5),
          const Text(
            'Pick 2–6 days. We’ll place the right sessions on those exact days.',
            style: TextStyle(color: AppPalette.muted, fontSize: 12),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                const {
                  'MON': 'Mon',
                  'TUE': 'Tue',
                  'WED': 'Wed',
                  'THU': 'Thu',
                  'FRI': 'Fri',
                  'SAT': 'Sat',
                  'SUN': 'Sun',
                }.entries.map((entry) {
                  final selected = profile.availableWorkoutDays.contains(
                    entry.key,
                  );
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (value) {
                      final next = List<String>.from(
                        profile.availableWorkoutDays,
                      );
                      if (value) {
                        if (next.length >= 6) {
                          showAppMessage(
                            context,
                            'Choose up to 6 training days.',
                          );
                          return;
                        }
                        next.add(entry.key);
                      } else {
                        if (next.length <= 2) {
                          showAppMessage(
                            context,
                            'Keep at least 2 training days.',
                          );
                          return;
                        }
                        next.remove(entry.key);
                      }
                      const order = [
                        'MON',
                        'TUE',
                        'WED',
                        'THU',
                        'FRI',
                        'SAT',
                        'SUN',
                      ];
                      next.sort(
                        (a, b) => order.indexOf(a).compareTo(order.indexOf(b)),
                      );
                      onChanged(
                        profile.copyWith(
                          workoutDays: next.length,
                          availableWorkoutDays: next,
                        ),
                      );
                    },
                    selectedColor: AppPalette.lime,
                    checkmarkColor: AppPalette.ink,
                    side: const BorderSide(color: AppPalette.line),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.availableWorkoutDays.length} training days · ${profile.availableWorkoutDays.join(' · ')}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
          const SizedBox(height: 18),
          _ValueSlider(
            label: 'Time per workout',
            value: profile.sessionMinutes.toDouble(),
            min: 15,
            max: 60,
            divisions: 9,
            suffix: 'min',
            onChanged: (value) =>
                onChanged(profile.copyWith(sessionMinutes: value.round())),
          ),
          const SizedBox(height: 22),
          Text('Daily activity', style: context.text.titleLarge),
          const SizedBox(height: 12),
          ...[
            'Mostly sitting',
            'Lightly active',
            'Moderately active',
            'Very active',
          ].map(
            (activity) => _ActivityTile(
              label: activity,
              selected: profile.activityLevel == activity,
              onTap: () => onChanged(profile.copyWith(activityLevel: activity)),
            ),
          ),
          const SizedBox(height: 14),
          Text('Equipment available', style: context.text.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                ['Bodyweight', 'Dumbbells', 'Resistance bands', 'Full gym'].map(
                  (item) {
                    final selected = profile.equipment.contains(item);
                    return FilterChip(
                      label: Text(item),
                      selected: selected,
                      onSelected: (value) {
                        final next = List<String>.from(profile.equipment);
                        if (value) {
                          next.add(item);
                        } else if (next.length > 1) {
                          next.remove(item);
                        }
                        onChanged(profile.copyWith(equipment: next));
                      },
                      selectedColor: AppPalette.lime,
                      side: const BorderSide(color: AppPalette.line),
                    );
                  },
                ).toList(),
          ),
        ],
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      eyebrow: 'Your starting plan',
      title: 'Built around\nwhat matters to you.',
      subtitle:
          'These are estimates for general wellness, not medical advice. Adjust with professional guidance when needed.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppPalette.ink,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.ink.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _SummaryMetric(
                      value: '${profile.calorieTarget}',
                      label: 'daily kcal',
                      color: AppPalette.lime,
                    ),
                    _SummaryMetric(
                      value: '${profile.proteinTarget}g',
                      label: 'protein',
                      color: AppPalette.mint,
                    ),
                    _SummaryMetric(
                      value: '${profile.workoutDays}×',
                      label: 'workouts',
                      color: AppPalette.coral,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppPalette.lime,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${profile.dietType} recipes ranked for ${profile.goal.toLowerCase()}, plus ${profile.sessionMinutes}-minute workouts on ${profile.availableWorkoutDays.join(', ')}.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ReadyRow(
            icon: Icons.restaurant_menu_rounded,
            color: AppPalette.sun,
            title: 'Personal recipe feed',
            subtitle: 'Full ingredients, method and nutrition per serving',
          ),
          const SizedBox(height: 10),
          _ReadyRow(
            icon: Icons.fitness_center_rounded,
            color: AppPalette.violet,
            title: 'A complete weekly split',
            subtitle: 'Every training day includes exact exercises and sets',
          ),
          const SizedBox(height: 10),
          _ReadyRow(
            icon: Icons.tune_rounded,
            color: AppPalette.mint,
            title: 'Easy to reshape',
            subtitle: 'Update goals, preferences or availability anytime',
          ),
        ],
      ),
    );
  }
}

class _ValueSlider extends StatelessWidget {
  const _ValueSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: context.text.titleMedium),
              const Spacer(),
              Text(
                '${value.round()} $suffix',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions ?? (max - min).round(),
            activeColor: AppPalette.ink,
            inactiveColor: AppPalette.line,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected ? AppPalette.ink : Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: selected ? AppPalette.ink : AppPalette.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppPalette.canvas,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : AppPalette.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.58)
                          : AppPalette.muted,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppPalette.lime : AppPalette.line,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppPalette.ink),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppPalette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.lime.withValues(alpha: 0.22)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppPalette.limeDark : AppPalette.line,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppPalette.ink : AppPalette.muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
