import 'package:flutter/material.dart';

import '../core/app_theme.dart';

Future<void> showGoalCelebration(BuildContext context, {required String name}) {
  final firstName = name.trim().split(RegExp(r'\s+')).first;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close congratulations',
    barrierColor: AppPalette.ink.withValues(alpha: 0.68),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (dialogContext, _, _) =>
        _GoalCelebrationCard(firstName: firstName),
    transitionBuilder: (_, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _GoalCelebrationCard extends StatelessWidget {
  const _GoalCelebrationCard({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: BoxDecoration(
              color: AppPalette.canvas,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 2,
                  top: 14,
                  child: _Spark(
                    icon: Icons.star_rounded,
                    color: AppPalette.sun,
                  ),
                ),
                const Positioned(
                  right: 4,
                  top: 58,
                  child: _Spark(
                    icon: Icons.circle,
                    color: AppPalette.violet,
                    size: 13,
                  ),
                ),
                const Positioned(
                  right: 26,
                  top: 2,
                  child: _Spark(
                    icon: Icons.auto_awesome_rounded,
                    color: AppPalette.coral,
                    size: 22,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppPalette.lime,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/nourish_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.lime,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'DAILY PLAN COMPLETE',
                        style: TextStyle(
                          color: AppPalette.ink,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You did it, $firstName!',
                      textAlign: TextAlign.center,
                      style: context.text.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your energy, protein, fibre, hydration, and planned movement are all on track today.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppPalette.muted,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppPalette.line),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: AppPalette.coral,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Today is now glowing in your year',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.celebration_rounded),
                      label: const Text('Keep the momentum'),
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
}

class _Spark extends StatelessWidget {
  const _Spark({required this.icon, required this.color, this.size = 18});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(icon, color: color, size: size);
}
