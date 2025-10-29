// test/widgets/contact_info_box_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:cocolab_messaging/screens/contact_info/contact_info_box.dart';

void main() {
  group('ContactInfoBox Widget Tests', () {
    // Helper to create a test widget with the correct constraints
    Widget buildTestWidget({
      required String displayName,
      required String phoneNumber,
      String? photoUrl,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            // Wrap with SizedBox to provide the expected constraints from the parent
            child: SizedBox(
              height: 500, // Enough height to avoid overflow
              width: 400,
              child: ContactInfoBox(
                displayName: displayName,
                phoneNumber: phoneNumber,
                photoUrl: photoUrl,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders correctly with required properties', (WidgetTester tester) async {
      // Arrange
      const displayName = 'John Doe';
      const phoneNumber = '+1 123 456 7890';

      // Act
      await tester.pumpWidget(buildTestWidget(
        displayName: displayName,
        phoneNumber: phoneNumber,
      ));

      // Assert
      expect(find.text(displayName), findsOneWidget);
      expect(find.text(phoneNumber), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('displays initials when photoUrl is null', (WidgetTester tester) async {
      // Arrange
      const displayName = 'John Doe';
      const phoneNumber = '+1 123 456 7890';

      // Act
      await tester.pumpWidget(buildTestWidget(
        displayName: displayName,
        phoneNumber: phoneNumber,
      ));

      // Assert - Find the CircleAvatar, check text inside if visible
      final avatarFinder = find.byType(CircleAvatar);
      expect(avatarFinder, findsOneWidget);

      // Since it's difficult to directly check the text inside CircleAvatar in widget tests,
      // we'll check that the initials function works correctly in a separate, focused test
      final circleAvatar = tester.widget<CircleAvatar>(avatarFinder);
      expect(circleAvatar.child, isA<Text>());

      // Check the initials function directly
      expect(circleAvatar.backgroundColor, Colors.blue[900]);
    });

    // Direct test of the _getInitials private function by checking resulting UI
    testWidgets('initials function produces correct output', (WidgetTester tester) async {
      // Test cases
      final testCases = [
        {'name': 'John Doe', 'expected': 'JD'},
        {'name': 'John', 'expected': 'J'},
        {'name': '', 'expected': '?'},
      ];

      for (final testCase in testCases) {
        // Act
        await tester.pumpWidget(buildTestWidget(
          displayName: testCase['name']!,
          phoneNumber: '+1 123 456 7890',
        ));

        // Find the CircleAvatar and its child Text widget
        final avatarFinder = find.byType(CircleAvatar);
        expect(avatarFinder, findsOneWidget);

        final CircleAvatar avatar = tester.widget(avatarFinder);
        if (avatar.child is Text) {
          final textWidget = avatar.child as Text;
          expect(textWidget.data, equals(testCase['expected']));
        } else {
          fail('CircleAvatar child is not a Text widget');
        }

        // Important: Reset for next test case
        await tester.pumpAndSettle();
      }
    });

    testWidgets('uses NetworkImage when photoUrl is provided', (WidgetTester tester) async {
      // When testing network images, wrap in mockNetworkImagesFor
      mockNetworkImagesFor(() async {
        // Arrange
        const displayName = 'John Doe';
        const phoneNumber = '+1 123 456 7890';
        const photoUrl = 'https://example.com/profile.jpg';

        // Act
        await tester.pumpWidget(buildTestWidget(
          displayName: displayName,
          phoneNumber: phoneNumber,
          photoUrl: photoUrl,
        ));

        // Assert - Check that the CircleAvatar has a backgroundImage
        final CircleAvatar avatar = tester.widget(find.byType(CircleAvatar));
        expect(avatar.backgroundImage, isA<NetworkImage>());
        expect((avatar.backgroundImage as NetworkImage).url, equals(photoUrl));
        expect(avatar.child, isNull); // No child (initials) should be present
      });
    });

    testWidgets('has correct style properties', (WidgetTester tester) async {
      // Arrange
      const displayName = 'John Doe';
      const phoneNumber = '+1 123 456 7890';

      // Act
      await tester.pumpWidget(buildTestWidget(
        displayName: displayName,
        phoneNumber: phoneNumber,
      ));

      // Assert - Verify container and decoration
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      final BoxDecoration? decoration = container.decoration as BoxDecoration?;

      expect(decoration, isNotNull);
      expect(decoration!.borderRadius, isA<BorderRadius>());

      // Verify text styles - if visible in the viewport
      final Text nameText = tester.widget(find.text(displayName));
      expect(nameText.style?.fontSize, 26);
      expect(nameText.style?.fontWeight, FontWeight.bold);
    });
  });
}