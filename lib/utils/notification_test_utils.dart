// lib/utils/notification_test_utils.dart
import 'package:firebase_database/firebase_database.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// In notification_test_utils.dart
Future<void> sendTestNotification(
    String targetUserId, {
      required String title,
      required String body,
    }) async {
  final db = FirebaseDatabase.instance.ref();
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  print("Fetching FCM token for user: $targetUserId");

  final snapshot = await db.child('users').child(targetUserId).get();
  if (snapshot.exists) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final targetFcmToken = data['fcmToken'];

    if (targetFcmToken != null) {
      print("FCM token found: $targetFcmToken");
      final notificationService = NotificationService();

      // Create data payload that will be used to construct a notification on the client
      Map<String, String> dataPayload = {
        'senderId': currentUser.uid,
        'message': body,
        'notificationType': 'chat_message',
        // Don't put the title here - let the client construct it
      };

      print("Sending notification to token: $targetFcmToken");
      await notificationService.sendNotificationData(
        targetFcmToken,
        dataPayload,  // Send only data, no notification
      );
      print("Notification sent successfully.");
    } else {
      print("No FCM token found for the target user.");
    }
  } else {
    print("Target user not found in the database.");
  }
}