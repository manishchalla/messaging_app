// lib/models/user_profile.dart
class UserProfile {
  final String phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final DateTime lastUpdated;
  final String? fcmToken;

  UserProfile({
    required this.phoneNumber,
    this.displayName,
    this.photoUrl,
    required this.lastUpdated,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastUpdated': lastUpdated.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      fcmToken: map['fcmToken'],
    );
  }
}