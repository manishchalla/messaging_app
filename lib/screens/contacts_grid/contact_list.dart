// lib/widgets/contact_list.dart
import 'package:cocolab_messaging/models/expanded_contact.dart';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../widgets/contact_grid_item.dart';


class ContactList extends StatelessWidget {
  final List<ExpandedContact> expandedContacts;
  final Map<String, UserProfile> userProfiles;
  final Function(ExpandedContact) onTap;

  const ContactList({
    Key? key,
    required this.expandedContacts,
    required this.userProfiles,
    required this.onTap,
  }) : super(key: key);

  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.trim();
    if (cleaned.startsWith('+1')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('1') && cleaned.length > 10) {
      cleaned = cleaned.substring(1);
    }
    cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length > 10) {
      cleaned = cleaned.substring(cleaned.length - 10);
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: expandedContacts.length,
      itemBuilder: (context, index) {
        final expandedContact = expandedContacts[index];
        final normalizedNumber = _normalizePhoneNumber(expandedContact.phoneNumber);
        final userProfile = userProfiles[normalizedNumber];

        return ContactGridItem(
          expandedContact: expandedContact,
          userProfile: userProfile,
          onTap: onTap,
        );
      },
    );
  }
}