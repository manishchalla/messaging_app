import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/models/user_profile.dart';

void main() {
  group('UserProfile Tests', () {
    test('creates UserProfile from map', () {
      final map = {
        'phoneNumber': '1234567890',
        'displayName': 'Test User',
        'photoUrl': 'https://example.com/photo.jpg',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.phoneNumber, '1234567890');
      expect(profile.displayName, 'Test User');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
    });

    test('converts UserProfile to map', () {
      final now = DateTime.now();
      final profile = UserProfile(
        phoneNumber: '1234567890',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        lastUpdated: now,
      );

      final map = profile.toMap();

      expect(map['phoneNumber'], '1234567890');
      expect(map['displayName'], 'Test User');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['lastUpdated'], now.toIso8601String());
    });
  });
}