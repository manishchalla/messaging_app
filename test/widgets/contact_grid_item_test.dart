// test/widgets/contact_grid_item_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cocolab_messaging/models/expanded_contact.dart';
import 'package:cocolab_messaging/models/user_profile.dart';
import 'package:cocolab_messaging/widgets/contact_grid_item.dart';

void main() {
  testWidgets('ContactGridItem displays contact information', (WidgetTester tester) async {
    final contact = Contact(
      id: '1',
      displayName: 'John Doe',
    );

    final expandedContact = ExpandedContact(
      contact: contact,
      phoneNumber: '1234567890',
      isRegistered: true,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactGridItem(
          expandedContact: expandedContact,
          onTap: (_) {},
        ),
      ),
    ));

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });


  testWidgets('ContactGridItem calls onTap callback when tapped', (WidgetTester tester) async {
    final contact = Contact(
      id: '1',
      displayName: 'John Doe',
    );

    final expandedContact = ExpandedContact(
      contact: contact,
      phoneNumber: '1234567890',
      isRegistered: true,
    );

    bool tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactGridItem(
          expandedContact: expandedContact,
          onTap: (_) {
            tapped = true;
          },
        ),
      ),
    ));

    // Use a more specific finder - find the Card and tap on it
    // or find the InkWell that wraps the content based on your widget hierarchy
    await tester.tap(find.byType(Card));

    // Alternative approaches if the above doesn't work:
    // 1. Find by text within the ContactGridItem
    // await tester.tap(find.text('John Doe'));

    // 2. Use descendant finder to be more specific
    // await tester.tap(find.descendant(
    //   of: find.byType(ContactGridItem),
    //   matching: find.byType(InkWell).first,
    // ));

    expect(tapped, true);
  });
}