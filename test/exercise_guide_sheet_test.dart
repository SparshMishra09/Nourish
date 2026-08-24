import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/models/workout.dart';
import 'package:nourish/widgets/exercise_guide_sheet.dart';

void main() {
  testWidgets('exercise form loop opens with coaching details', (tester) async {
    const exercise = ExerciseItem(
      name: 'Push-up',
      detail: '4 × 8-15',
      focus: 'Chest · triceps',
      icon: '💪',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showExerciseGuideSheet(context, exercise),
              child: const Text('Open guide'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open guide'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Nourish Form Loop · built in and available offline'),
      findsOneWidget,
    );
    expect(find.text('Set your position'), findsOneWidget);
    expect(find.text('Make the movement'), findsOneWidget);
    expect(find.text('Common mistake'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
