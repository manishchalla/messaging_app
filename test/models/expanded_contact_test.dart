// test/models/expanded_contact_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cocolab_messaging/models/expanded_contact.dart';

void main() {
  group('ExpandedContact Tests', () {
    test('creates ExpandedContact with correct properties', () {
      final contact = Contact(id: '1', displayName: 'John Doe');
      const phoneNumber = '1234567890';
      const isRegistered = true;

      final expandedContact = ExpandedContact(
        contact: contact,
        phoneNumber: phoneNumber,
        isRegistered: isRegistered,
      );

      expect(expandedContact.contact, contact);
      expect(expandedContact.phoneNumber, phoneNumber);
      expect(expandedContact.isRegistered, isRegistered);
    });

    test('toString returns formatted string', () {
      final contact = Contact(id: '1', displayName: 'John Doe');
      const phoneNumber = '1234567890';

      final expandedContact = ExpandedContact(
        contact: contact,
        phoneNumber: phoneNumber,
        isRegistered: true,
      );

      expect(expandedContact.toString(), 'John Doe (1234567890)');
    });
  });
}