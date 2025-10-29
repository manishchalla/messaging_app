import 'package:flutter_contacts/flutter_contacts.dart';

class ExpandedContact {
  final Contact contact;
  final String phoneNumber;
  final bool isRegistered;
  final bool isUnknown;
  final bool hasUnreadMessages;

  ExpandedContact({
    required this.contact,
    required this.phoneNumber,
    required this.isRegistered,
    this.isUnknown = false,
    this.hasUnreadMessages = false,
  });

  @override
  String toString() => '${contact.displayName} ($phoneNumber)';
}