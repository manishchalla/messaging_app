import 'package:cocolab_messaging/models/expanded_contact.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/profile_service.dart';

class ContactsHelper {
  static Future<List<ExpandedContact>> fetchAndMatchContacts(ProfileService profileService) async {
    if (!await FlutterContacts.requestPermission()) {
      throw Exception('Permission denied');
    }

    try {
      // Get all registered users
      final snapshot = await FirebaseDatabase.instance.ref('users').get();
      if (!snapshot.exists) return [];

      // Extract and normalize registered numbers
      final registeredNumbers = (snapshot.value as Map)
          .values
          .map((user) => (user as Map)['phoneNumber']?.toString() ?? '')
          .where((number) => number.isNotEmpty)
          .map((number) => _normalizePhoneNumber(number))
          .toSet();

      // Get contacts with full details
      final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
          withGroups: false,
          withAccounts: false
      );

      // Create expanded contacts list
      final expandedContacts = <ExpandedContact>[];

      for (final contact in contacts) {
        // Process each phone number in the contact
        for (final phone in contact.phones) {
          final normalizedNumber = _normalizePhoneNumber(phone.number);

          // If the number is registered, add it as an expanded contact
          if (registeredNumbers.contains(normalizedNumber)) {
            expandedContacts.add(ExpandedContact(
              contact: contact,
              phoneNumber: phone.number,
              isRegistered: true,
              isUnknown: false
            ));
          }
        }
      }

      return expandedContacts;
    } catch (e) {
      print('Error in fetchAndMatchContacts: $e');
      throw Exception('Failed to fetch and match contacts: $e');
    }
  }

  static Future<Set<String>> _batchCheckPhoneNumbers(
      ProfileService profileService,
      Set<String> numbers
      ) async {
    // Create chunks of 10 numbers for batch processing
    final chunks = numbers.toList().fold<List<List<String>>>(
        [],
            (chunks, item) {
          if (chunks.isEmpty || chunks.last.length >= 10) {
            chunks.add([item]);
          } else {
            chunks.last.add(item);
          }
          return chunks;
        }
    );

    final registeredNumbers = <String>{};

    // Process chunks in parallel
    await Future.wait(
        chunks.map((chunk) async {
          final snapshot = await FirebaseDatabase.instance
              .ref('users')
              .orderByChild('phoneNumber')
              .startAt(chunk.first)
              .endAt(chunk.last)
              .get();

          if (snapshot.exists) {
            final data = Map<String, dynamic>.from(snapshot.value as Map);
            registeredNumbers.addAll(
                data.values
                    .map((v) => v['phoneNumber'] as String)
                    .where((num) => chunk.contains(num))
            );
          }
        })
    );

    return registeredNumbers;
  }

  static String _normalizePhoneNumber(String phoneNumber) {
    // First, clean the string of any whitespace
    String cleaned = phoneNumber.trim();

    // Handle common country code formats
    if (cleaned.startsWith('+1')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('1')) {
      cleaned = cleaned.substring(1);
    }

    // Remove all non-digit characters
    String onlyDigits = cleaned.replaceAll(RegExp(r'[^\d]'), '');

    // Get last 10 digits if longer
    if (onlyDigits.length > 10) {
      onlyDigits = onlyDigits.substring(onlyDigits.length - 10);
    }

    return onlyDigits;
  }
}