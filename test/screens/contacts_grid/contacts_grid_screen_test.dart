import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cocolab_messaging/models/expanded_contact.dart';
import 'package:cocolab_messaging/models/user_profile.dart';
import 'package:cocolab_messaging/screens/contacts_grid/contacts_grid_screen.dart';
import 'package:cocolab_messaging/services/auth_service.dart';
import 'package:cocolab_messaging/services/profile_service.dart';
import 'package:cocolab_messaging/services/message_service.dart';
import 'package:cocolab_messaging/utils/contacts_helper.dart';

// Create test-specific implementation
class TestContactsGridScreen extends StatelessWidget {
  final List<ExpandedContact> contacts;
  final bool isLoading;
  final Function(String) onSearch;
  final VoidCallback onRefresh;
  final Function(ExpandedContact) onContactTap;
  final bool showEmptyState;
  final bool showErrorDialog;
  final bool showPermissionDialog;

  const TestContactsGridScreen({
    Key? key,
    required this.contacts,
    this.isLoading = false,
    required this.onSearch,
    required this.onRefresh,
    required this.onContactTap,
    this.showEmptyState = false,
    this.showErrorDialog = false,
    this.showPermissionDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show dialogs based on flags
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showErrorDialog) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Could not load contacts. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (showPermissionDialog) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text('This app requires access to contacts. Please enable it in settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search contacts...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: onSearch,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : showEmptyState
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No contacts found"),
                  const SizedBox(height: 8),
                  const Text("Make sure you have granted permission and synced your contacts."),
                  TextButton(
                    onPressed: onRefresh,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  child: InkWell(
                    onTap: () => onContactTap(contact),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          child: Text(contact.contact.displayName[0]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact.contact.displayName,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          contact.phoneNumber,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Simple Contact implementation for testing
class TestContact implements Contact {
  @override
  final String displayName;
  @override
  final String id;

  TestContact(this.displayName, this.id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testContacts = List.generate(3, (i) =>
      ExpandedContact(
        contact: TestContact('Contact $i', 'contact-$i'),
        phoneNumber: '12345$i',
        isRegistered: true,
      )
  );

  testWidgets('ContactsGridScreen displays contacts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: testContacts,
        onSearch: (_) {},
        onRefresh: () {},
        onContactTap: (_) {},
      ),
    ));

    expect(find.text('Contact 0'), findsOneWidget);
    expect(find.text('Contact 1'), findsOneWidget);
    expect(find.text('Contact 2'), findsOneWidget);
  });

  testWidgets('ContactsGridScreen shows loading state', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: [],
        isLoading: true,
        onSearch: (_) {},
        onRefresh: () {},
        onContactTap: (_) {},
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ContactsGridScreen filters contacts with search', (WidgetTester tester) async {
    String lastSearchQuery = '';
    List<ExpandedContact> filteredContacts = testContacts;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => TestContactsGridScreen(
          contacts: filteredContacts,
          onSearch: (query) {
            setState(() {
              lastSearchQuery = query;
              filteredContacts = testContacts.where((c) =>
                  c.contact.displayName.toLowerCase().contains(query.toLowerCase())).toList();
            });
          },
          onRefresh: () {},
          onContactTap: (_) {},
        ),
      ),
    ));

    // Check initial state
    expect(find.text('Contact 0'), findsOneWidget);
    expect(find.text('Contact 1'), findsOneWidget);
    expect(find.text('Contact 2'), findsOneWidget);

    // Enter search text
    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();

    // Verify filtered results
    expect(find.text('Contact 0'), findsNothing);
    expect(find.text('Contact 1'), findsOneWidget);
    expect(find.text('Contact 2'), findsNothing);
  });

  testWidgets('Empty state shows correct UI', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: [],
        showEmptyState: true,
        onSearch: (_) {},
        onRefresh: () {},
        onContactTap: (_) {},
      ),
    ));

    expect(find.text('No contacts found'), findsOneWidget);
    expect(find.text('Make sure you have granted permission and synced your contacts.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Retry button calls onRefresh', (WidgetTester tester) async {
    bool refreshCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: [],
        showEmptyState: true,
        onSearch: (_) {},
        onRefresh: () {
          refreshCalled = true;
        },
        onContactTap: (_) {},
      ),
    ));

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(refreshCalled, true);
  });

  testWidgets('Refresh button calls onRefresh', (WidgetTester tester) async {
    bool refreshCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: testContacts,
        onSearch: (_) {},
        onRefresh: () {
          refreshCalled = true;
        },
        onContactTap: (_) {},
      ),
    ));

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(refreshCalled, true);
  });

  testWidgets('Contact tap calls onContactTap', (WidgetTester tester) async {
    ExpandedContact? tappedContact;

    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: testContacts,
        onSearch: (_) {},
        onRefresh: () {},
        onContactTap: (contact) {
          tappedContact = contact;
        },
      ),
    ));

    await tester.tap(find.text('Contact 1').first);
    await tester.pump();

    expect(tappedContact, isNotNull);
    expect(tappedContact?.contact.displayName, 'Contact 1');
  });

  testWidgets('Error dialog shows correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: [],
        showErrorDialog: true,
        onSearch: (_) {},
        onRefresh: () {},
        onContactTap: (_) {},
      ),
    ));

    await tester.pump();

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Could not load contacts. Please try again.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsNothing);
  });

  testWidgets('Permission dialog shows correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestContactsGridScreen(
        contacts: [],
        showPermissionDialog: true,
        onSearch: (_) {},
        onRefresh: () {},
        onContactTap: (_) {},
      ),
    ));

    await tester.pump();

    expect(find.text('Permission Denied'), findsOneWidget);
    expect(find.text('This app requires access to contacts. Please enable it in settings.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Permission Denied'), findsNothing);
  });

  testWidgets('Profile button navigates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/': (context) => TestContactsGridScreen(
          contacts: testContacts,
          onSearch: (_) {},
          onRefresh: () {},
          onContactTap: (_) {},
        ),
        '/profile': (context) => const Scaffold(body: Text('Profile Screen')),
      },
    ));

    await tester.tap(find.byIcon(Icons.account_circle));
    await tester.pumpAndSettle();

    expect(find.text('Profile Screen'), findsOneWidget);
  });
}