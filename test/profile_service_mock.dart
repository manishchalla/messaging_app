// test/mocks/profile_service_mock.dart
import 'package:cocolab_messaging/services/profile_service.dart';
import 'package:mockito/mockito.dart';

// Import your UserProfile class if it's in a separate file
// If UserProfile is defined within profile_service.dart, you don't need this import
import 'package:cocolab_messaging/models/user_profile.dart';  // Adjust path as needed

class MockProfileService extends Mock implements ProfileService {
  @override
  Future<String> getPhotoUrl() async => 'https://example.com/mock-photo.jpg';

  @override
  Future<void> uploadProfilePhoto(dynamic file) async {
    // Do nothing in tests
  }

  @override
  Future<void> updateProfile(String userId, UserProfile profile) async {
    // Do nothing in tests
  }

  @override
  Stream<Map<String, dynamic>> watchUserProfile(String userId) {
    return Stream.value({
      'displayName': 'Test User',
      'phoneNumber': '1234567890',
      'photoUrl': 'https://example.com/mock-photo.jpg',
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }
}