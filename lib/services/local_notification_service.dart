import 'dart:async';

import 'package:cocolab_messaging/services/profile_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

import 'notification_navigation_service.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static StreamController<Map<String, dynamic>>? _notificationStreamController;

  // Initialize local notifications
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload);
            // Pass the data to the navigation service
            if (data.containsKey('senderId')) {
              _handleLocalNotificationTap(data);
            }
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );
  }

  static void setNotificationStreamController(StreamController<Map<String, dynamic>> controller) {
    _notificationStreamController = controller;
  }


  // Handle local notification tap
  static void _handleLocalNotificationTap(Map<String, dynamic> data) {
    // Create a RemoteMessage-like object to reuse the navigation logic
    final message = RemoteMessage(
      data: Map<String, String>.from(data),
    );

    // Use the same handler from the notification navigation service
    NotificationNavigationService.handleNotificationNavigation(message);
  }

  // Create a notification channel for Android
  static void createNotificationChannel() {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'cocolab_notification_channel', // Same ID used in AndroidManifest.xml
      'Cocolab Notifications',
      description: 'This channel is used for Cocolab app notifications.',
      importance: Importance.high,
    );

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle foreground notifications
  // In local_notification_service.dart
  // Handle foreground notifications
  static void handleForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Notification received in foreground: ${message.notification?.title}");
      print("Notification data: ${message.data}");

      try {
        // Check if this is a chat message
        if (message.data.containsKey('senderId') &&
            message.data.containsKey('notificationType') &&
            message.data['notificationType'] == 'chat_message') {

          final senderId = message.data['senderId'];
          final messageText = message.data['message'] ?? '';

          // Create payload for notification tap
          final payload = json.encode(message.data);

          // Look up the sender's name in contacts
          String senderName = await _findContactNameBySenderId(senderId);

          // Create notification with the contact name
          _flutterLocalNotificationsPlugin.show(
            DateTime.now().millisecond,
            "$senderName sent you a message",  // Use contact name here
            messageText,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'cocolab_notification_channel',
                'Cocolab Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: payload,
          );

          // Notify the contacts grid about the new message
          if (_notificationStreamController != null) {
            _notificationStreamController!.add(message.data);
          }

          return;
        }
      } catch (e) {
        print("Error handling chat notification: $e");
      }

      // Default handling for other notifications
      if (message.notification != null) {
        _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecond,
          message.notification?.title ?? 'New Notification',
          message.notification?.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'cocolab_notification_channel',
              'Cocolab Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.isNotEmpty ? json.encode(message.data) : null,
        );

        // Notify the contacts grid about the new message
        if (_notificationStreamController != null && message.data.isNotEmpty) {
          _notificationStreamController!.add(message.data);
        }
      }
    });
  }

// Add this helper method
  static Future<String> _findContactNameBySenderId(String senderId) async {
    try {
      // Get the sender's profile
      final profileService = ProfileService();
      final senderProfile = await profileService.getProfile(senderId);

      if (senderProfile?.phoneNumber == null) {
        return senderProfile?.displayName ?? "Unknown";
      }

      // Normalize the phone number
      final normalizedNumber = _normalizePhoneNumber(senderProfile!.phoneNumber);

      // Check if we have permission to access contacts
      if (await FlutterContacts.requestPermission()) {
        // Get all contacts
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );

        // Look for this number in contacts
        for (final contact in contacts) {
          for (final phone in contact.phones) {
            if (_normalizePhoneNumber(phone.number) == normalizedNumber) {
              // Found the contact - use their saved name
              return contact.displayName;
            }
          }
        }
      }

      // If not found in contacts, return the Firebase display name
      return senderProfile.displayName ?? "Unknown";
    } catch (e) {
      print("Error finding contact name: $e");
      return "Unknown";
    }
  }

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


  // Handle background notifications
  static Future<void> handleBackgroundNotifications() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    print("Notification title: ${message.notification?.title}");
    print("Notification body: ${message.notification?.body}");
  }
}