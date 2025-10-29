import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/screens/auth/auth_form.dart';

void main() {
  testWidgets('AuthForm renders welcome text correctly', (WidgetTester tester) async {
    // Define mock callback
    bool googleSignInCalled = false;

    // Build AuthForm widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthForm(
          isLoading: false,
          onGoogleSignIn: () {
            googleSignInCalled = true;
          },
        ),
      ),
    ));

    // Verify welcome text is displayed correctly
    expect(find.text('Welcome to CoColab Messaging'), findsOneWidget);
    expect(find.byType(Text), findsAtLeastNWidgets(2)); // Welcome text and button text
  });

  testWidgets('AuthForm shows sign in button when not loading', (WidgetTester tester) async {
    // Build AuthForm widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthForm(
          isLoading: false,
          onGoogleSignIn: () {},
        ),
      ),
    ));

    // Verify sign in button is displayed
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);
  });

  testWidgets('AuthForm shows CircularProgressIndicator when loading', (WidgetTester tester) async {
    // Build AuthForm widget with loading=true
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthForm(
          isLoading: true,
          onGoogleSignIn: () {},
        ),
      ),
    ));

    // Verify loading indicator is displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('AuthForm calls onGoogleSignIn when button is pressed', (WidgetTester tester) async {
    // Define mock callback
    bool googleSignInCalled = false;

    // Build AuthForm widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthForm(
          isLoading: false,
          onGoogleSignIn: () {
            googleSignInCalled = true;
          },
        ),
      ),
    ));

    // Tap the sign in button
    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    // Verify callback was called
    expect(googleSignInCalled, true);
  });

  testWidgets('AuthForm has correct styling', (WidgetTester tester) async {
    // Build AuthForm widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthForm(
          isLoading: false,
          onGoogleSignIn: () {},
        ),
      ),
    ));

    // Verify styling
    // There might be multiple Center widgets, so let's find the one that contains our Column
    final centerFinder = find.ancestor(
      of: find.byType(Column),
      matching: find.byType(Center),
    );
    expect(centerFinder, findsOneWidget);

    final columnWidget = tester.widget<Column>(find.byType(Column));
    expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);

    final titleText = tester.widget<Text>(find.text('Welcome to CoColab Messaging'));
    expect(titleText.style?.fontSize, 24);
    expect(titleText.style?.fontWeight, FontWeight.bold);

    // Verify spacing between elements
    final sizedBoxFinder = find.byType(SizedBox).at(0);
    final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
    expect(sizedBox.height, 30);
  });
}