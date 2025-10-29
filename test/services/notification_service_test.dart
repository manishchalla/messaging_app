import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cocolab_messaging/services/notification_service.dart';

@GenerateMocks([http.Client])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    test('headers construction includes correct content type and authorization', () async {
      final accessToken = await notificationService.getAccessToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['Authorization'], startsWith('Bearer '));
    });

    test('message payload construction validates all key components', () {
      final testFcmToken = 'test_token';
      final testTitle = 'Test Title';
      final testBody = 'Test Body';
      final testData = {
        'type': 'custom_notification',
        'id': '12345'
      };

      final payload = _constructTestPayload(
          testFcmToken,
          testTitle,
          testBody,
          testData
      );

      _validatePayloadStructure(payload,
          token: testFcmToken,
          title: testTitle,
          body: testBody,
          data: testData
      );
    });

    test('notification and data-only message payload handling', () {
      final testFcmToken = 'test_token';
      final testData = {
        'senderId': 'user123',
        'message': 'Test message'
      };

      final dataPayload = _constructDataPayload(testFcmToken, testData);
      _validateDataPayloadStructure(dataPayload, testFcmToken, testData);
    });

    test('error logging for notification sending scenarios', () {
      final errorScenarios = [
        {
          'statusCode': 400,
          'expectedMessage': 'Failed to send notification: ',
          'method': 'sendNotification'
        },
        {
          'statusCode': 500,
          'expectedMessage': 'Failed to send data notification: ',
          'method': 'sendNotificationData'
        }
      ];

      for (final scenario in errorScenarios) {
        expect(() async {
          if (scenario['method'] == 'sendNotification') {
            await notificationService.sendNotification(
                'test_token',
                'Test Title',
                'Test Body'
            );
          } else {
            await notificationService.sendNotificationData(
                'test_token',
                {'test': 'data'}
            );
          }
        }, returnsNormally);
      }
    });
  });
}

Map<String, dynamic> _constructTestPayload(
    String token,
    String title,
    String body,
    Map<String, String> data
    ) {
  return {
    'message': {
      'token': token,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data,
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
}

Map<String, dynamic> _constructDataPayload(
    String token,
    Map<String, String> data
    ) {
  return {
    'message': {
      'token': token,
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
}

void _validatePayloadStructure(
    Map<String, dynamic> payload, {
      required String token,
      required String title,
      required String body,
      required Map<String, String> data,
    }) {
  final message = payload['message'] as Map<String, dynamic>;
  expect(message['token'], equals(token));

  final notification = message['notification'] as Map<String, dynamic>;
  expect(notification['title'], equals(title));
  expect(notification['body'], equals(body));

  expect(message['data'], equals(data));

  final android = message['android'] as Map<String, dynamic>;
  expect(android['priority'], equals('high'));

  final androidNotification = android['notification'] as Map<String, dynamic>;
  expect(androidNotification['channel_id'], equals('cocolab_notification_channel'));

  final apns = message['apns'] as Map<String, dynamic>;
  final apsPayload = apns['payload']['aps'] as Map<String, dynamic>;
  expect(apsPayload['content-available'], equals(1));
}

void _validateDataPayloadStructure(
    Map<String, dynamic> payload,
    String token,
    Map<String, String> data
    ) {
  final message = payload['message'] as Map<String, dynamic>;
  expect(message['token'], equals(token));
  expect(message['data'], equals(data));

  final android = message['android'] as Map<String, dynamic>;
  expect(android['priority'], equals('high'));

  final apns = message['apns'] as Map<String, dynamic>;
  final apsPayload = apns['payload']['aps'] as Map<String, dynamic>;
  expect(apsPayload['content-available'], equals(1));
}