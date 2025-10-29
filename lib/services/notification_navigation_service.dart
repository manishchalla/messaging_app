// lib/services/notification_navigation_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../screens/chat_screen.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ProfileService _profileService = ProfileService();
  static final AuthService _authService = AuthService();
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Initialize notification navigation handling
  static Future<void> initialize() async {
    // Handle notification when app is in terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        handleNotificationNavigation(message);
      }
    });

    // Handle notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationNavigation(message);
    });
  }

  // Handle navigation based on notification data - public method accessible to other classes
  static Future<void> handleNotificationNavigation(RemoteMessage message) async {
    try {
      final data = message.data;

      // Check if this is a chat message notification
      if (data.containsKey('senderId')) {
        final currentUser = _authService.currentUser;
        if (currentUser == null) return;

        final senderId = data['senderId'];

        // Fetch sender's profile
        final senderProfile = await _profileService.getProfile(senderId);
        if (senderProfile == null) return;

        // Fetch contact info from device contacts
        final contacts = await _fetchContactForPhoneNumber(senderProfile.phoneNumber, senderId);
        if (contacts == null) return;

        // Navigate to chat screen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contact: contacts,
              recipientId: senderId,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error handling notification navigation: $e');
    }
  }

  // Helper method to find contact by phone number
  static Future<Contact?> _fetchContactForPhoneNumber(String phoneNumber, String senderId) async {
    try {
      if (!await FlutterContacts.requestPermission()) {
        return null;
      }

      // Normalize the phone number for comparison
      final normalizedSearchNumber = _normalizePhoneNumber(phoneNumber);

      // Get all contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      // Find contact with matching phone number
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalizedContactNumber = _normalizePhoneNumber(phone.number);
          if (normalizedContactNumber == normalizedSearchNumber) {
            return await FlutterContacts.getContact(contact.id);
          }
        }
      }

      // If no match found in contacts, create a "virtual" contact with the phone number
      final userProfile = await _profileService.getProfile(senderId);
      return Contact(
        id: 'virtual_$normalizedSearchNumber',
        displayName: userProfile?.displayName ?? 'Unknown',
        phones: [Phone(normalizedSearchNumber)],
      );
    } catch (e) {
      print('Error fetching contact: $e');
      return null;
    }
  }

  // Helper method to normalize phone numbers for comparison
  static String _normalizePhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.trim();
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
}