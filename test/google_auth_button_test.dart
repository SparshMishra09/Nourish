import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/widgets/google_auth_button.dart';

void main() {
  testWidgets('Google auth button adapts its action and loading state', (
    tester,
  ) async {
    var taps = 0;

    Widget app({required bool isSignUp, bool isLoading = false}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: GoogleAuthButton(
                onPressed: () => taps++,
                isSignUp: isSignUp,
                isLoading: isLoading,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(app(isSignUp: false));

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(
      find.image(const AssetImage(GoogleAuthButton.logoAsset)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('googleSignIn')));
    expect(taps, 1);

    await tester.pumpWidget(app(isSignUp: true));
    await tester.pumpAndSettle();
    expect(find.text('Sign up with Google'), findsOneWidget);

    await tester.pumpWidget(app(isSignUp: true, isLoading: true));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('Connecting to Google…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('googleSignIn')));
    expect(taps, 1);
  });
}
