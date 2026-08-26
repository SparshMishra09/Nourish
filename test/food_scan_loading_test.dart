import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/screens/food_scan_screen.dart';

void main() {
  testWidgets('scanner loading overlay communicates each verification stage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              height: 300,
              child: ScannerLoadingOverlay(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Reading the package'), findsOneWidget);
    expect(find.text('Identity first · nutrition second'), findsOneWidget);
    expect(find.text('Your photo is not saved'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Matching the exact product'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
