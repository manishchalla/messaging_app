import 'package:cocolab_messaging/screens/contacts_grid/contact_search_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ContactSearchBar updates text field', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ContactSearchBar(controller: controller))));

    await tester.enterText(find.byType(TextField), 'John');
    expect(controller.text, 'John');
  });
}
