// test/widgets/custom_contact_avatar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cocolab_messaging/widgets/custom_contact_avatar.dart';

void main() {
  testWidgets('CustomContactAvatar displays initials for single name', (WidgetTester tester) async {
    final contact = Contact(displayName: 'John');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: CustomContactAvatar(contact: contact),
        ),
      ),
    ));

    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('CustomContactAvatar displays initials for full name', (WidgetTester tester) async {
    final contact = Contact(displayName: 'John Doe');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: CustomContactAvatar(contact: contact),
        ),
      ),
    ));

    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('CustomContactAvatar displays question mark for empty name', (WidgetTester tester) async {
    final contact = Contact(displayName: '');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: CustomContactAvatar(contact: contact),
        ),
      ),
    ));

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('CustomContactAvatar uses correct sizing', (WidgetTester tester) async {
    final contact = Contact(displayName: 'John');
    const radius = 30.0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: CustomContactAvatar(
            contact: contact,
            radius: radius,
          ),
        ),
      ),
    ));

    final container = tester.widget<Container>(find.byType(Container));
    expect(container.constraints?.minWidth, radius * 2);
    expect(container.constraints?.minHeight, radius * 2);
  });
}