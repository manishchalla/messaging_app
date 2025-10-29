// profile_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cocolab_messaging/services/profile_service.dart';
import 'package:cocolab_messaging/models/user_profile.dart';
import 'profile_service_test.mocks.dart';

// Create a mock for TaskSnapshot manually
class MockTaskSnapshot extends Mock implements TaskSnapshot {}

@GenerateNiceMocks([
  MockSpec<DatabaseReference>(),
  MockSpec<DataSnapshot>(),
  MockSpec<FirebaseStorage>(),
  MockSpec<Reference>(),
  MockSpec<UploadTask>(),
  MockSpec<File>()
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize mocks at the top level
  late MockDatabaseReference mockDbRef;
  late MockFirebaseStorage mockStorage;
  late MockReference mockStorageRef;
  late MockUploadTask mockUploadTask;
  late MockDataSnapshot mockDataSnapshot;
  late MockFile mockFile;
  late ProfileService profileService;

  // Setup common mock behaviors
  setUp(() {
    // Initialize all mocks
    mockDbRef = MockDatabaseReference();
    mockStorage = MockFirebaseStorage();
    mockStorageRef = MockReference();
    mockUploadTask = MockUploadTask();
    mockDataSnapshot = MockDataSnapshot();
    mockFile = MockFile();

    // Setup common behaviors
    when(mockStorage.ref()).thenAnswer((_) => mockStorageRef);
    when(mockStorageRef.child(any)).thenAnswer((_) => mockStorageRef);
    when(mockDbRef.child(any)).thenAnswer((_) => mockDbRef);

    // Create service instance
    profileService = ProfileService(
        storage: mockStorage,
        db: mockDbRef
    );
  });

  group('ProfileService', () {
    test('uploadProfileImage uploads and returns URL', () async {
      // Arrange
      final downloadUrl = 'https://example.com/image.jpg';
      final taskSnapshot = MockTaskSnapshot();

      // Mock the entire chain of Future calls
      when(mockStorageRef.putFile(any)).thenAnswer((_) => mockUploadTask);
      when(mockUploadTask.then(any, onError: anyNamed('onError'))).thenAnswer(
              (invocation) {
            final Function callback = invocation.positionalArguments[0];
            return Future.value(callback(taskSnapshot));
          }
      );
      when(mockStorageRef.getDownloadURL()).thenAnswer((_) async => downloadUrl);

      // Act
      final result = await profileService.uploadProfileImage('user1', mockFile);

      // Assert
      expect(result, equals(downloadUrl));
      verify(mockStorageRef.putFile(any)).called(1);
    });

    test('updateProfile updates user profile', () async {
      // Arrange
      final profile = UserProfile(
        phoneNumber: '1234567890',
        displayName: 'Test User',
        lastUpdated: DateTime.now(),
      );
      when(mockDbRef.update(any)).thenAnswer((_) async => null);

      // Act
      await profileService.updateProfile('user1', profile);

      // Assert
      verify(mockDbRef.update(any)).called(1);
    });

    test('isPhoneNumberRegistered returns correct value', () async {
      // Arrange
      when(mockDbRef.orderByChild(any)).thenReturn(mockDbRef);
      when(mockDbRef.equalTo(any)).thenReturn(mockDbRef);
      when(mockDbRef.get()).thenAnswer((_) async => mockDataSnapshot);
      when(mockDataSnapshot.exists).thenReturn(true);

      // Act
      final result = await profileService.isPhoneNumberRegistered('1234567890');

      // Assert
      expect(result, isTrue);
    });
    test('isPhoneNumberUnique returns true when phone number does not exist', () async {
      // Arrange
      when(mockDbRef.child(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.orderByChild(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.equalTo(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.get()).thenAnswer((_) async => mockDataSnapshot);
      when(mockDataSnapshot.exists).thenReturn(false);

      // Act
      final result = await profileService.isPhoneNumberUnique('1234567890', 'user1');

      // Assert
      expect(result, isTrue);
      verify(mockDbRef.child('users')).called(1);
      verify(mockDbRef.orderByChild('phoneNumber')).called(1);
      verify(mockDbRef.equalTo('1234567890')).called(1);
    });

    test('isPhoneNumberUnique returns true when phone belongs to current user', () async {
      // Arrange
      final mockData = {
        'user1': {
          'phoneNumber': '1234567890',
          'displayName': 'Test User',
        }
      };

      when(mockDbRef.child(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.orderByChild(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.equalTo(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.get()).thenAnswer((_) async => mockDataSnapshot);
      when(mockDataSnapshot.exists).thenReturn(true);
      when(mockDataSnapshot.value).thenReturn(mockData);

      // Act
      final result = await profileService.isPhoneNumberUnique('1234567890', 'user1');

      // Assert
      expect(result, isTrue);
    });

    test('isPhoneNumberUnique returns false when phone belongs to another user', () async {
      // Arrange
      final mockData = {
        'user2': {
          'phoneNumber': '1234567890',
          'displayName': 'Another User',
        }
      };

      when(mockDbRef.child(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.orderByChild(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.equalTo(any)).thenAnswer((_) => mockDbRef);
      when(mockDbRef.get()).thenAnswer((_) async => mockDataSnapshot);
      when(mockDataSnapshot.exists).thenReturn(true);
      when(mockDataSnapshot.value).thenReturn(mockData);

      // Act
      final result = await profileService.isPhoneNumberUnique('1234567890', 'user1');

      // Assert
      expect(result, isFalse);
    });

    test('uploadProfileImage throws exception on error', () async {
      // Arrange
      when(mockStorageRef.putFile(any)).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
              () => profileService.uploadProfileImage('user1', mockFile),
          throwsA(isA<Exception>().having(
                  (e) => e.toString(),
              'message',
              contains('Failed to upload profile image')
          ))
      );
    });

    test('updateProfile throws exception on error', () async {
      // Arrange
      final profile = UserProfile(
        phoneNumber: '1234567890',
        displayName: 'Test User',
        lastUpdated: DateTime.now(),
      );
      when(mockDbRef.update(any)).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
              () => profileService.updateProfile('user1', profile),
          throwsA(isA<Exception>().having(
                  (e) => e.toString(),
              'message',
              contains('Failed to update profile')
          ))
      );
    });

    test('isPhoneNumberRegistered throws exception on error', () async {
      // Arrange
      when(mockDbRef.get()).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
              () => profileService.isPhoneNumberRegistered('1234567890'),
          throwsA(isA<Exception>().having(
                  (e) => e.toString(),
              'message',
              contains('Failed to check phone number registration')
          ))
      );
    });

    test('getProfile throws exception on error', () async {
      // Arrange
      when(mockDbRef.get()).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
              () => profileService.getProfile('user1'),
          throwsA(isA<Exception>().having(
                  (e) => e.toString(),
              'message',
              contains('Failed to fetch profile')
          ))
      );
    });

    test('getProfile returns profile when exists', () async {
      // Arrange
      final profileData = {
        'phoneNumber': '1234567890',
        'displayName': 'Test User',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      when(mockDbRef.get()).thenAnswer((_) async => mockDataSnapshot);
      when(mockDataSnapshot.exists).thenReturn(true);
      when(mockDataSnapshot.value).thenReturn(profileData);

      // Act
      final result = await profileService.getProfile('user1');

      // Assert
      expect(result, isNotNull);
      expect(result!.phoneNumber, equals('1234567890'));
    });
  });

}