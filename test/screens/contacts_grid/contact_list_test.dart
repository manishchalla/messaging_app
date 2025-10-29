// test/screens/contacts_grid/contact_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cocolab_messaging/models/expanded_contact.dart';
import 'package:cocolab_messaging/models/user_profile.dart';
import 'package:cocolab_messaging/screens/contacts_grid/contact_list.dart';
import 'package:cocolab_messaging/widgets/contact_grid_item.dart';

// Generate mock classes
@GenerateMocks([Contact])
import 'contact_list_test.mocks.dart';

void main() {
  group('ContactList Widget Tests', () {
    // Test data
    late List<ExpandedContact> expandedContacts;
    late Map<String, UserProfile> userProfiles;
    late Function(ExpandedContact) mockOnTap;

    setUp(() {
      // Create mock contacts
      final mockContact1 = MockContact();
      final mockContact2 = MockContact();
      final mockContact3 = MockContact();

      // Set up properties for mock contacts including id
      when(mockContact1.displayName).thenReturn('John Doe');
      when(mockContact1.id).thenReturn('contact1');

      when(mockContact2.displayName).thenReturn('Jane Smith');
      when(mockContact2.id).thenReturn('contact2');

      when(mockContact3.displayName).thenReturn('Bob Johnson');
      when(mockContact3.id).thenReturn('contact3');

      // Create expanded contacts
      expandedContacts = [
        ExpandedContact(
          contact: mockContact1,
          phoneNumber: '+1 (123) 456-7890',
          isRegistered: true,
        ),
        ExpandedContact(
          contact: mockContact2,
          phoneNumber: '+1 (987) 654-3210',
          isRegistered: true,
        ),
        ExpandedContact(
          contact: mockContact3,
          phoneNumber: '555-123-4567',
          isRegistered: false,
        ),
      ];

      // Create user profiles
      userProfiles = {
        '1234567890': UserProfile(
          phoneNumber: '+1 (123) 456-7890',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/john.jpg',
          lastUpdated: DateTime.now(),
        ),
        '9876543210': UserProfile(
          phoneNumber: '+1 (987) 654-3210',
          displayName: 'Jane Smith',
          photoUrl: null,
          lastUpdated: DateTime.now(),
        ),
      };

      // Mock onTap callback
      mockOnTap = (_) {};
    });

    // Create a testable widget
    Widget createTestableContactList() {
      return MaterialApp(
        home: Scaffold(
          body: ContactList(
            expandedContacts: expandedContacts,
            userProfiles: userProfiles,
            onTap: mockOnTap,
          ),
        ),
      );
    }

    // Create a testable widget with empty contacts
    Widget createEmptyContactList() {
      return MaterialApp(
        home: Scaffold(
          body: ContactList(
            expandedContacts: [],
            userProfiles: userProfiles,
            onTap: mockOnTap,
          ),
        ),
      );
    }




    testWidgets('should handle empty contacts list gracefully',
            (WidgetTester tester) async {
          // Arrange & Act
          await tester.pumpWidget(createEmptyContactList());
          await tester.pumpAndSettle();

          // Assert
          expect(find.byType(GridView), findsOneWidget);
          expect(find.byType(ContactGridItem), findsNothing);
        });




  });
}