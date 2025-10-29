import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/screens/profile/profile_form.dart';

void main() {
  group('ProfileForm Widget Tests', () {
    testWidgets('ProfileForm should render correctly with empty values',
            (WidgetTester tester) async {
          // Create text editing controllers with empty initial values
          final nameController = TextEditingController();
          final phoneController = TextEditingController();

          // Build the ProfileForm widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProfileForm(
                  nameController: nameController,
                  phoneController: phoneController,
                ),
              ),
            ),
          );

          // Verify that the form has two TextFields
          expect(find.byType(TextField), findsNWidgets(2));

          // Verify that the labels are correctly displayed
          expect(find.text('Name'), findsOneWidget);
          expect(find.text('Phone Number'), findsOneWidget);

          // Verify that the text fields are empty
          expect(nameController.text, isEmpty);
          expect(phoneController.text, isEmpty);
        });

    testWidgets('ProfileForm should render with pre-filled values',
            (WidgetTester tester) async {
          // Create text editing controllers with initial values
          final nameController = TextEditingController(text: 'John Doe');
          final phoneController = TextEditingController(text: '+1 (555) 123-4567');

          // Build the ProfileForm widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProfileForm(
                  nameController: nameController,
                  phoneController: phoneController,
                ),
              ),
            ),
          );

          // Verify that the form has two TextFields
          expect(find.byType(TextField), findsNWidgets(2));

          // Verify the text fields have the correct values
          expect(nameController.text, 'John Doe');
          expect(phoneController.text, '+1 (555) 123-4567');
        });


    testWidgets('Phone number field should have phone keyboard type',
            (WidgetTester tester) async {
          // Create text editing controllers
          final nameController = TextEditingController();
          final phoneController = TextEditingController();

          // Build the ProfileForm widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProfileForm(
                  nameController: nameController,
                  phoneController: phoneController,
                ),
              ),
            ),
          );

          // Find the text fields
          final phoneField = find.byType(TextField).at(1);

          // Verify that the phone field has the correct keyboard type
          final phoneFieldWidget = tester.widget<TextField>(phoneField);
          expect(phoneFieldWidget.keyboardType, TextInputType.phone);
        });

    testWidgets('Name and phone fields should have correct decoration',
            (WidgetTester tester) async {
          // Create text editing controllers
          final nameController = TextEditingController();
          final phoneController = TextEditingController();

          // Build the ProfileForm widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProfileForm(
                  nameController: nameController,
                  phoneController: phoneController,
                ),
              ),
            ),
          );

          // Find the text fields
          final nameField = find.byType(TextField).at(0);
          final phoneField = find.byType(TextField).at(1);

          // Verify that the fields have the correct decoration
          final nameFieldWidget = tester.widget<TextField>(nameField);
          final phoneFieldWidget = tester.widget<TextField>(phoneField);

          expect(nameFieldWidget.decoration?.labelText, 'Name');
          expect(phoneFieldWidget.decoration?.labelText, 'Phone Number');

          // Check that both fields have an outline border
          expect(nameFieldWidget.decoration?.border is OutlineInputBorder, isTrue);
          expect(phoneFieldWidget.decoration?.border is OutlineInputBorder, isTrue);
        });

    testWidgets('Form should have a SizedBox with correct height between fields',
            (WidgetTester tester) async {
          // Create text editing controllers
          final nameController = TextEditingController();
          final phoneController = TextEditingController();

          // Build the ProfileForm widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProfileForm(
                  nameController: nameController,
                  phoneController: phoneController,
                ),
              ),
            ),
          );

          // Find a SizedBox with a height of 16
          final sizedBoxFinder = find.byWidgetPredicate((widget) =>
          widget is SizedBox && widget.height == 16.0);

          // Verify we found at least one SizedBox with height 16
          expect(sizedBoxFinder, findsWidgets);
        });

    testWidgets('Form should be laid out in a Column',
            (WidgetTester tester) async {
          // Create text editing controllers
          final nameController = TextEditingController();
          final phoneController = TextEditingController();

          // Build the ProfileForm widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProfileForm(
                  nameController: nameController,
                  phoneController: phoneController,
                ),
              ),
            ),
          );

          // Verify that the form is laid out in a Column
          expect(find.byType(Column), findsOneWidget);
        });
  });
}