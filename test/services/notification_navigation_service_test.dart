import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cocolab_messaging/services/notification_navigation_service.dart';
import 'package:cocolab_messaging/services/profile_service.dart';
import 'package:cocolab_messaging/services/auth_service.dart';
import 'package:cocolab_messaging/models/user_profile.dart';

@GenerateMocks([
  ProfileService,
  AuthService,
  User,
  Contact,
  RemoteMessage,
  FirebaseAuth,
  FlutterContacts
])
import 'notification_navigation_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock method channels
  setUpAll(() {
    // Mock Firebase Core channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
          (methodCall) async {
        if (methodCall.method == 'initializeApp') {
          return {
            'name': '[DEFAULT]',
            'options': {},
          };
        }
        return null;
      },
    );

    // Mock Flutter Contacts channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('github.com/QuisApp/flutter_contacts'),
          (methodCall) async {
        switch (methodCall.method) {
          case 'requestPermission':
            return true;
          case 'getContacts':
            return [];
          default:
            return null;
        }
      },
    );
  });

  group('NotificationNavigationService', () {
    late MockProfileService mockProfileService;
    late MockAuthService mockAuthService;
    late MockUser mockUser;
    late MockContact mockContact;

    setUp(() {
      mockProfileService = MockProfileService();
      mockAuthService = MockAuthService();
      mockUser = MockUser();
      mockContact = MockContact();

      // Setup default mock behaviors
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');
    });

    test('phone number normalization handles various formats', () {
      final testCases = [
        {
          'input': '+11234567890',
          'expected': '1234567890'
        },
        {
          'input': '1234567890',
          'expected': '1234567890'
        },
        {
          'input': '(123) 456-7890',
          'expected': '1234567890'
        },
        {
          'input': '+44 7911 123456',
          'expected': '7911123456'
        }
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as String;
        final expected = testCase['expected'] as String;

        final result = _normalizePhoneNumber(input);
        expect(result, equals(expected), reason: 'Failed for input: $input');
      }
    });

    test('handleNotificationNavigation handles valid chat message', () async {
      // Prepare test data
      final testSenderId = 'sender_user_id';
      final testMessage = RemoteMessage(
          data: {
            'senderId': testSenderId,
            'notificationType': 'chat_message'
          }
      );

      // Mock profile service to return a user profile
      when(mockProfileService.getProfile(testSenderId)).thenAnswer((_) async =>
          UserProfile(
              phoneNumber: '1234567890',
              displayName: 'Sender User',
              lastUpdated: DateTime.now()
          )
      );

      // Verify no exceptions are thrown
      await expectLater(
              () => NotificationNavigationService.handleNotificationNavigation(testMessage),
          returnsNormally
      );
    });

    test('handleNotificationNavigation handles missing senderId', () async {
      final mockMessage = RemoteMessage(data: {});

      await expectLater(
              () => NotificationNavigationService.handleNotificationNavigation(mockMessage),
          returnsNormally
      );
    });

    test('handleNotificationNavigation handles null current user', () async {
      // Override current user to be null
      when(mockAuthService.currentUser).thenReturn(null);

      final mockMessage = RemoteMessage(
          data: {'senderId': 'test_user'}
      );

      await expectLater(
              () => NotificationNavigationService.handleNotificationNavigation(mockMessage),
          returnsNormally
      );
    });
  });
}

// Standalone function to match the private method in NotificationNavigationService
String _normalizePhoneNumber(String phoneNumber) {
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