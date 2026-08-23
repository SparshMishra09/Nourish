import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/core/app_theme.dart';
import 'package:nourish/widgets/year_activity_heatmap.dart';

void main() {
  testWidgets('year heatmap reports completed days without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: YearActivityHeatmap(
              completedDayKeys: {'2026-01-02', '2026-08-24'},
              year: 2026,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 completed days'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
