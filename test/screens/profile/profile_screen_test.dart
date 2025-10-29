import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cocolab_messaging/screens/profile/profile_screen.dart';
import 'package:cocolab_messaging/services/auth_service.dart';
import 'package:cocolab_messaging/services/profile_service.dart';
import 'package:cocolab_messaging/models/user_profile.dart';
import 'package:cocolab_messaging/screens/profile/profile_picture_editor.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for User class
import 'package:network_image_mock/network_image_mock.dart';

import 'profile_screen_test.mocks.dart';

@GenerateMocks([AuthService, ProfileService, File])
void main() {
  late MockAuthService mockAuthService;
  late MockProfileService mockProfileService;
  late User mockUser;
  late MockFile mockFile;

  setUp(() {
    mockAuthService = MockAuthService();
    mockProfileService = MockProfileService();
    mockFile = MockFile();

    // Create a proper mock User instead of MockUser
    mockUser = MockUser(
      uid: 'test-user-id',
      displayName: 'Test User',
      photoURL: 'https://example.com/photo.jpg',
    );

    // Set up default mock behaviors
    when(mockAuthService.currentUser).thenReturn(mockUser);

    when(mockProfileService.getProfile(argThat(equals('test-user-id')))).thenAnswer((_) async =>
        UserProfile(
          phoneNumber: '1234567890',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          lastUpdated: DateTime.now(),
        )
    );

    when(mockProfileService.isPhoneNumberUnique(
        argThat(equals('1234567890')),
        argThat(equals('test-user-id'))
    )).thenAnswer((_) async => true);

    when(mockProfileService.uploadProfileImage(
        argThat(equals('test-user-id')),
        argThat(equals(mockFile))
    )).thenAnswer((_) async => 'https://example.com/new-photo.jpg');

    when(mockProfileService.updateProfile(
      argThat(equals('test-user-id')),
      argThat(isA<UserProfile>()),
    )).thenAnswer((_) async {});

    when(mockAuthService.signOut()).thenAnswer((_) async {});
  });

  // Helper function to build the widget under test with required mocks
  Widget createTestableWidget() {
    return MaterialApp(
      home: Scaffold(
        body: ProfileScreen(
          authService: mockAuthService,
          profileService: mockProfileService,
        ),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('loads user data on initialization', (WidgetTester tester) async {
      mockNetworkImagesFor(() async {
        // Arrange & Act
        await tester.pumpWidget(createTestableWidget());

        // Wait for async operations to complete
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Verify text fields have correct initial values
        final nameField = tester.widget<TextField>(find.byType(TextField).at(0));
        expect(nameField.controller!.text, 'Test User');

        final phoneField = tester.widget<TextField>(find.byType(TextField).at(1));
        expect(phoneField.controller!.text, '1234567890');

        // Verify profile service was called
        verify(mockProfileService.getProfile(argThat(equals('test-user-id')))).called(1);
      });
    });

    testWidgets('displays loading indicator while fetching profile', (WidgetTester tester) async {
      mockNetworkImagesFor(() async {
        // Arrange - Delay the profile fetch
        final completer = Completer<UserProfile>();
        when(mockProfileService.getProfile(argThat(equals('test-user-id')))).thenAnswer((_) => completer.future);

        // Act - Start building widget but don't complete future yet
        await tester.pumpWidget(createTestableWidget());

        // Assert - Circular progress indicator should be visible initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Now complete the future
        completer.complete(UserProfile(
          phoneNumber: '1234567890',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          lastUpdated: DateTime.now(),
        ));

        // Wait for the async operation to complete
        await tester.pumpAndSettle();

        // Loading indicator should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    testWidgets('handles profile update correctly', (WidgetTester tester) async {
      mockNetworkImagesFor(() async {
        // Arrange
        await tester.pumpWidget(createTestableWidget());

        await tester.pumpAndSettle();

        // Act - Change name and press save
        await tester.enterText(find.byType(TextField).at(0), 'Updated Name');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockProfileService.isPhoneNumberUnique(
            argThat(equals('1234567890')),
            argThat(equals('test-user-id'))
        )).called(1);

        // Capture and verify the profile that was passed to updateProfile
        final captureVerifier = verify(mockProfileService.updateProfile(
            'test-user-id',
            captureAny
        ));

        expect(captureVerifier.captured.length, 1);
        final capturedProfile = captureVerifier.captured.first as UserProfile;
        expect(capturedProfile.displayName, 'Updated Name');
        expect(capturedProfile.phoneNumber, '1234567890');
      });
    });

    testWidgets('handles profile picture update correctly', (WidgetTester tester) async {
      mockNetworkImagesFor(() async {
        // Arrange
        await tester.pumpWidget(createTestableWidget());

        await tester.pumpAndSettle();

        // Find profile picture editor widget
        final profilePictureEditor = find.byType(ProfilePictureEditor);
        expect(profilePictureEditor, findsOneWidget);

        // Act - Simulate the widget's callback directly
        final picWidget = tester.widget<ProfilePictureEditor>(profilePictureEditor);
        picWidget.onImagePicked(mockFile);

        // Wait for async operations
        await tester.pumpAndSettle();

        // Assert
        verify(mockProfileService.uploadProfileImage(
            argThat(equals('test-user-id')),
            argThat(equals(mockFile))
        )).called(1);
      });
    });

    testWidgets('shows error when phone number is not unique', (WidgetTester tester) async {
      mockNetworkImagesFor(() async {
        // Arrange - Set up the mock to return false for phone number uniqueness
        when(mockProfileService.isPhoneNumberUnique(
            argThat(equals('1234567890')),
            argThat(equals('test-user-id'))
        )).thenAnswer((_) async => false);

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Act - Change name and press save
        await tester.enterText(find.byType(TextField).at(0), 'Updated Name');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockProfileService.isPhoneNumberUnique('1234567890', 'test-user-id')).called(1);

        // Verify error is shown (SnackBar)
        expect(find.text('This phone number is already registered.'), findsOneWidget);

        // Verify profile was not updated
        verifyNever(mockProfileService.updateProfile(
            argThat(equals('test-user-id')),
            argThat(isA<UserProfile>())
        ));
      });
    });

    testWidgets('handles error in profile fetch', (WidgetTester tester) async {
      mockNetworkImagesFor(() async {
        // Arrange
        when(mockProfileService.getProfile(argThat(equals('test-user-id'))))
            .thenAnswer((_) => Future.error(Exception('Network error')));

        // Act
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Assert - In a scaffold context, the error should be shown in a SnackBar
        expect(find.text('Failed to load profile: Exception: Network error'), findsOneWidget);

        // Verify the screen is not in loading state
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  });
}

// Mock Firebase User class for testing
class MockUser extends Mock implements User {
  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  MockUser({required this.uid, this.displayName, this.photoURL});
}
