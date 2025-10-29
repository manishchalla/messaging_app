// test/firebase_mocks.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';

// Setup Firebase mocks
class TestFirebaseMocks {
  static void setupFirebaseMocks() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup method channels
    setupMethodChannels();

    // Register platform instance
    FirebasePlatform.instance = TestFirebasePlatform();
  }

  static void setupMethodChannels() {
    // Firebase Core
    const MethodChannel firebaseCoreChannel = MethodChannel('plugins.flutter.io/firebase_core');
    firebaseCoreChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firebase#initializeApp':
          return {
            'name': '[DEFAULT]',
            'options': mockFirebaseOptions,
          };
        case 'Firebase#options':
          return mockFirebaseOptions;
        default:
          return null;
      }
    });

    // Firebase Auth
    const MethodChannel firebaseAuthChannel = MethodChannel('plugins.flutter.io/firebase_auth');
    firebaseAuthChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });

    // Firebase Database
    const MethodChannel firebaseDatabaseChannel = MethodChannel('plugins.flutter.io/firebase_database');
    firebaseDatabaseChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'DatabaseReference#get':
          return {
            'value': mockProfileData,
          };
        default:
          return null;
      }
    });

    // Firebase Storage - simple mock to prevent errors
    const MethodChannel firebaseStorageChannel = MethodChannel('plugins.flutter.io/firebase_storage');
    firebaseStorageChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      // Always return success for storage methods
      return null;
    });

    // Firebase Messaging - simple mock to prevent errors
    const MethodChannel firebaseMessagingChannel = MethodChannel('plugins.flutter.io/firebase_messaging');
    firebaseMessagingChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });

    // Firebase App Check - simple mock to prevent errors
    const MethodChannel firebaseAppCheckChannel = MethodChannel('plugins.flutter.io/firebase_app_check');
    firebaseAppCheckChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
  }

  // Mock data
  static Map<String, dynamic> get mockFirebaseOptions => {
    'apiKey': 'test-api-key',
    'appId': 'test-app-id',
    'messagingSenderId': 'test-messaging-sender-id',
    'projectId': 'test-project-id',
    'databaseURL': 'https://test-project.firebaseio.com',
    'storageBucket': 'test-project.appspot.com',
  };

  static Map<String, dynamic> get mockProfileData => {
    'phoneNumber': '1234567890',
    'displayName': 'Test User',
    'photoUrl': 'https://example.com/photo.jpg',
    'lastUpdated': DateTime.now().toIso8601String(),
    'fcmToken': 'test-fcm-token',
  };
}

// Platform implementation mocks
class TestFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return TestFirebaseAppPlatform(
      name: name,
      options: FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-messaging-sender-id',
        projectId: 'test-project-id',
        storageBucket: 'test-project.appspot.com',
      ),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return [app()];
  }
}

class TestFirebaseAppPlatform extends FirebaseAppPlatform {
  TestFirebaseAppPlatform({
    required String name,
    required FirebaseOptions options,
  }) : super(name, options);
}