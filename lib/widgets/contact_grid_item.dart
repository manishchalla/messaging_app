// lib/widgets/contact_grid_item.dart
import 'package:cocolab_messaging/models/expanded_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_profile.dart';
import '../screens/contact_info/contact_info_screen.dart';

class ContactGridItem extends StatelessWidget {
  final ExpandedContact expandedContact;
  final UserProfile? userProfile;
  final Function(ExpandedContact) onTap;

  const ContactGridItem({
    super.key,
    required this.expandedContact,
    this.userProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFF212121),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: expandedContact.hasUnreadMessages
              ? Colors.blue.shade400
              : const Color(0xFF2C2C2C),
          width: expandedContact.hasUnreadMessages ? 2.5 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => onTap(expandedContact),
        child: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: 'contact_${expandedContact.contact.id}_${expandedContact.phoneNumber}',
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue.shade100,
                            child: expandedContact.isUnknown
                                ? Icon(Icons.person_off, size: 36, color: Colors.orange[300])
                                : userProfile?.photoUrl != null
                                ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: userProfile!.photoUrl!,
                                cacheKey: userProfile!.photoUrl!,
                                placeholderFadeInDuration: const Duration(milliseconds: 300),
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                placeholder: (context, url) => CircularProgressIndicator(
                                  color: Colors.grey,
                                ),
                                errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red),
                              ),
                            )
                                : Text(
                              _getInitials(expandedContact.contact.displayName),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        // Unread message indicator - on the left side
                        if (expandedContact.hasUnreadMessages)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF212121), width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          expandedContact.contact.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: expandedContact.hasUnreadMessages
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: expandedContact.hasUnreadMessages
                                ? Colors.white
                                : null,
                          ),
                        ),
                      ),
                    ),
                    if (expandedContact.isUnknown)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 14, color: Colors.orange[300]),
                            const SizedBox(width: 4),
                            Text(
                              "Unknown",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[300],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Flexible(
                      child: Text(
                        expandedContact.phoneNumber,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: IconButton(
                icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                onPressed: () => _showContactInfo(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactInfo(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => ContactInfoScreen(
          displayName: expandedContact.contact.displayName,
          phoneNumber: expandedContact.phoneNumber,
          photoUrl: userProfile?.photoUrl,
        ),
      ),
    );
  }

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

  String _getInitials(String displayName) {
    if (displayName.isEmpty) return "?";
    final names = displayName.trim().split(" ");
    if (names.length >= 2) {
      return "${names[0][0]}${names[1][0]}".toUpperCase();
    }
    return displayName[0].toUpperCase();
  }
}