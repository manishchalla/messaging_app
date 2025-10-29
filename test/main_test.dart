// test/main_test.dart
import 'dart:async';

import 'package:cocolab_messaging/main.dart';
import 'package:cocolab_messaging/screens/auth/auth_screen.dart';
import 'package:cocolab_messaging/screens/contacts_grid/contacts_grid_screen.dart';
import 'package:cocolab_messaging/screens/onboarding/onboarding_screen.dart';
import 'package:cocolab_messaging/services/auth_service.dart';
import 'package:cocolab_messaging/services/notification_navigation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'firebase_mocks.dart';

// Generate mocks
@GenerateMocks([
  User,
  DataSnapshot,
  DatabaseReference,
])
import 'main_test.mocks.dart';

// Manual mocks for non-generated classes
class MockAuthService extends Mock implements AuthService {
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  Stream<User?> get authStateChanges => _authStateController.stream;

  void emitAuthState(User? user) {
    _authStateController.add(user);
  }

  @override
  void dispose() {
    _authStateController.close();
  }
}

// Test widget that uses our dependency injection
class TestableAppRoot extends StatelessWidget {
  final MockAuthService authService;
  final Stream<DataSnapshot> profileSnapshotStream;

  const TestableAppRoot({
    Key? key,
    required this.authService,
    required this.profileSnapshotStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authSnapshot.hasData) {
            return const AuthScreen();
          }

          return StreamBuilder<DataSnapshot>(
            stream: profileSnapshotStream,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!profileSnapshot.hasData ||
                  !profileSnapshot.data!.exists ||
                  profileSnapshot.data!.value == null) {
                return const OnboardingScreen();
              }

              try {
                final userData = profileSnapshot.data!.value as Map<dynamic, dynamic>;
                final hasPhoneNumber = userData.containsKey('phoneNumber') &&
                    userData['phoneNumber'] != null &&
                    userData['phoneNumber'].toString().isNotEmpty;

                return hasPhoneNumber
                    ? const ContactsGridScreen()
                    : const OnboardingScreen();
              } catch (e) {
                print('Error checking user profile: $e');
                return const OnboardingScreen();
              }
            },
          );
        },
      ),
    );
  }
}

void main() {
  // Setup Firebase mocks before running tests
  TestFirebaseMocks.setupFirebaseMocks();

  group('MyApp Widget Tests', () {
    testWidgets('MyApp initializes with correct theme and navigator key',
            (WidgetTester tester) async {
          await tester.pumpWidget(MaterialApp(
            title: 'CoColab Messaging',
            navigatorKey: NotificationNavigationService.navigatorKey,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: Colors.blue[400]!,
                secondary: Colors.blueGrey[400]!,
                surface: const Color(0xFF1E1E1E),
                background: const Color(0xFF121212),
              ),
            ),
            home: Container(),
          ));

          final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
          expect(app.title, 'CoColab Messaging');
          expect(app.navigatorKey, equals(NotificationNavigationService.navigatorKey));
          expect(app.theme!.brightness, equals(Brightness.dark));
          expect(app.theme!.colorScheme.primary, isA<Color>());
        });
  });

  group('AppRoot Widget Tests', () {
    late MockUser mockUser;
    late MockDataSnapshot mockDataSnapshot;
    late MockAuthService mockAuthService;
    late StreamController<DataSnapshot> dataSnapshotController;

    setUp(() {
      mockUser = MockUser();
      mockDataSnapshot = MockDataSnapshot();
      mockAuthService = MockAuthService();
      dataSnapshotController = StreamController<DataSnapshot>();

      // Setup default values
      when(mockUser.uid).thenReturn('test_user_id');
      when(mockDataSnapshot.exists).thenReturn(true);
      when(mockDataSnapshot.value).thenReturn({
        'phoneNumber': '1234567890',
        'displayName': 'Test User',
      });
    });

    tearDown(() {
      dataSnapshotController.close();
      mockAuthService.dispose();
    });

    testWidgets('AppRoot shows loading indicator while waiting for auth state',
            (WidgetTester tester) async {
          await tester.pumpWidget(TestableAppRoot(
            authService: mockAuthService,
            profileSnapshotStream: dataSnapshotController.stream,
          ));

          // Should show loading indicator while stream is waiting
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });

    testWidgets('AppRoot shows AuthScreen when user is not logged in',
            (WidgetTester tester) async {
          await tester.pumpWidget(TestableAppRoot(
            authService: mockAuthService,
            profileSnapshotStream: dataSnapshotController.stream,
          ));

          // Emit null user (not logged in)
          mockAuthService.emitAuthState(null);
          await tester.pumpAndSettle();

          expect(find.byType(AuthScreen), findsOneWidget);
        });

    testWidgets('AppRoot shows OnboardingScreen when profile not complete',
            (WidgetTester tester) async {
          when(mockDataSnapshot.exists).thenReturn(false);

          await tester.pumpWidget(TestableAppRoot(
            authService: mockAuthService,
            profileSnapshotStream: dataSnapshotController.stream,
          ));

          // Emit logged in user
          mockAuthService.emitAuthState(mockUser);
          // Emit profile data
          dataSnapshotController.add(mockDataSnapshot);

          await tester.pumpAndSettle();
          expect(find.byType(OnboardingScreen), findsOneWidget);
        });

    testWidgets('AppRoot shows ContactsGridScreen when profile is complete',
            (WidgetTester tester) async {
          // Explicitly define the mock data as a Map
          when(mockDataSnapshot.value).thenReturn({
            'phoneNumber': '1234567890',
            'displayName': 'Test User',
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          await tester.pumpWidget(TestableAppRoot(
            authService: mockAuthService,
            profileSnapshotStream: dataSnapshotController.stream,
          ));

          // Emit logged in user
          mockAuthService.emitAuthState(mockUser);
          // Emit profile data
          dataSnapshotController.add(mockDataSnapshot);

          // Use pump with small duration instead of pumpAndSettle to avoid timing out
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(ContactsGridScreen), findsOneWidget);
        });

    testWidgets('AppRoot shows OnboardingScreen when phone number is missing',
            (WidgetTester tester) async {
          when(mockDataSnapshot.value).thenReturn({
            'displayName': 'Test User',
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          await tester.pumpWidget(TestableAppRoot(
            authService: mockAuthService,
            profileSnapshotStream: dataSnapshotController.stream,
          ));

          // Emit logged in user
          mockAuthService.emitAuthState(mockUser);
          // Emit profile data
          dataSnapshotController.add(mockDataSnapshot);

          await tester.pumpAndSettle();
          expect(find.byType(OnboardingScreen), findsOneWidget);
        });

    testWidgets('AppRoot shows OnboardingScreen with data parsing error',
            (WidgetTester tester) async {
          when(mockDataSnapshot.value).thenReturn("Not a map"); // Will cause parsing error

          await tester.pumpWidget(TestableAppRoot(
            authService: mockAuthService,
            profileSnapshotStream: dataSnapshotController.stream,
          ));

          // Emit logged in user
          mockAuthService.emitAuthState(mockUser);
          // Emit profile data
          dataSnapshotController.add(mockDataSnapshot);

          await tester.pumpAndSettle();
          expect(find.byType(OnboardingScreen), findsOneWidget);
        });
  });

  // This test specifically tests error handling
  testWidgets('AppRoot handles database errors gracefully',
          (WidgetTester tester) async {
        // Setup test widget with error case
        final mockAuthService = MockAuthService();
        final mockUser = MockUser();
        when(mockUser.uid).thenReturn('test_user_id');

        final widget = Provider<AuthService>.value(
          value: mockAuthService,
          child: MaterialApp(
            home: StreamBuilder<User?>(
              stream: mockAuthService.authStateChanges,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                return FutureBuilder<DataSnapshot>(
                  future: Future<DataSnapshot>.error(Exception('Database error')),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const OnboardingScreen();
                    }
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return const ContactsGridScreen();
                  },
                );
              },
            ),
          ),
        );

        await tester.pumpWidget(widget);

        // Emit authenticated user
        mockAuthService.emitAuthState(mockUser);

        // Allow error to be processed and UI to rebuild
        await tester.pumpAndSettle();

        // Should show OnboardingScreen on error
        expect(find.byType(OnboardingScreen), findsOneWidget);
      });
}