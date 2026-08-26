import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/core/app_theme.dart';
import 'package:nourish/models/user_profile.dart';
import 'package:nourish/screens/workout_screen.dart';
import 'package:nourish/services/plan_engine.dart';

void main() {
  testWidgets('workout screen presents optional prep and recovery with demos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = UserProfile(
      uid: 'support-test',
      name: 'Nourish Tester',
      email: 'tester@nourish.app',
      age: 28,
      gender: 'Female',
      heightCm: 165,
      weightKg: 62,
      goal: 'Build muscle',
      dietType: 'Vegetarian',
      activityLevel: 'Moderately active',
      workoutDays: 3,
      availableWorkoutDays: ['MON', 'WED', 'FRI'],
      sessionMinutes: 35,
      equipment: ['Bodyweight', 'Dumbbells'],
      avoidFoods: [],
      onboardingComplete: true,
    );
    final plan = const PlanEngine().buildWorkoutPlan(profile);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WorkoutScreen(
            profile: profile,
            plan: plan,
            onProfileTap: () {},
            onCompleteWorkout: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SMART FLOW'), findsOneWidget);
    expect(find.text('PREP'), findsOneWidget);
    expect(find.text('TRAIN'), findsOneWidget);
    expect(find.text('RECOVER'), findsOneWidget);
    expect(find.textContaining('your selected 35-minute workout'), findsOne);

    final warmUpDemo = find.byKey(
      const ValueKey('support-Dynamic chest opener-40 sec · smooth reps'),
    );
    await tester.ensureVisible(warmUpDemo);
    await tester.pumpAndSettle();
    expect(find.text('Warm-up'), findsOneWidget);
    expect(
      find.textContaining('The goal is readiness, not fatigue.'),
      findsOneWidget,
    );

    await tester.tap(warmUpDemo);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dynamic chest opener'), findsWidgets);
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.textContaining('ExerciseDB by AscendAPI'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -2200),
      1400,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cool-down'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cool-down'));
    await tester.pumpAndSettle();

    expect(find.textContaining('mild tension, never pain'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('support-Chest & shoulder stretch-20 sec each side'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
