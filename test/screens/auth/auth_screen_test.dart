import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/screens/auth/auth_form.dart';

// Simple mock test for AuthForm only - avoiding Firebase dependencies
void main() {
  testWidgets('AuthForm shows button and welcome text', (WidgetTester tester) async {
    // Build a simpler test widget just to test the AuthForm's behavior
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthForm(
          isLoading: false,
          onGoogleSignIn: () {},
        ),
      ),
    ));

    // Verify text and button are displayed
    expect(find.text('Welcome to CoColab Messaging'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);
  });

  testWidgets('AuthForm shows loading indicator when loading', (WidgetTester tester) async {
    // Build a test widget with loading=true
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthForm(
          isLoading: true,
          onGoogleSignIn: () {},
        ),
      ),
    ));

    // Verify loading indicator is shown and button is not
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('AuthForm calls onGoogleSignIn when button is tapped',
          (WidgetTester tester) async {
        bool callbackCalled = false;

        // Build a test widget
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: AuthForm(
              isLoading: false,
              onGoogleSignIn: () {
                callbackCalled = true;
              },
            ),
          ),
        ));

        // Find and tap the sign-in button
        await tester.tap(find.text('Sign in with Google'));
        await tester.pump();

        // Verify callback was called
        expect(callbackCalled, true);
      });
}