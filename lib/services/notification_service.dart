// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  // Method to retrieve an access token using the service account
  Future<String> getAccessToken() async {
    final serviceAccountJson = {
      
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials =
    await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );

    client.close();
    return credentials.accessToken.data; // Access token returned here
  }

  // In notification_service.dart, add this method
  Future<void> sendNotificationData(String targetFcmToken, Map<String, String> data) async {
    final accessToken = await getAccessToken();
    final fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/cocolab-40e6f/messages:send';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    // Build a data-only message payload (no notification)
    final messagePayload = {
      'message': {
        'token': targetFcmToken,
        'data': data,
        'android': {
          'priority': 'high',
        },
        'apns': {
          'payload': {
            'aps': {
              'content-available': 1,
            }
          }
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: headers,
        body: jsonEncode(messagePayload),
      );

      if (response.statusCode == 200) {
        print("Data notification sent successfully!");
      } else {
        print("Failed to send data notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending data notification: $e");
    }
  }

  // Method to send a notification
  Future<void> sendNotification(String targetFcmToken,
      String title,
      String body,
      [Map<String, String>? data]) async {
    final accessToken = await getAccessToken(); // Retrieve the access token
    final fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/cocolab-40e6f/messages:send';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken', // Use the access token here
    };

    // Build the message payload
    final messagePayload = {
      'message': {
        'token': targetFcmToken, // Target user's FCM token
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': 'message',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'cocolab_notification_channel',
          }
        },
        'apns': {
          'payload': {
            'aps': {
              'content-available': 1,
            }
          }
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: headers,
        body: jsonEncode(messagePayload),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully!");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}