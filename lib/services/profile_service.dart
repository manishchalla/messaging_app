import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseStorage _storage;
  final DatabaseReference _db;

  ProfileService({
    FirebaseStorage? storage,
    DatabaseReference? db,
  }) :
        _storage = storage ?? FirebaseStorage.instance,
        _db = db ?? FirebaseDatabase.instance.ref();


  // Upload profile image to Firebase Storage and return the download URL
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final storageRef = _storage.ref().child('profile_images/${userId}').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Update user profile in Firebase Realtime Database
  Future<void> updateProfile(String userId, UserProfile profile) async {
    try {
      await _db.child('users').child(userId).update(profile.toMap());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Check if a phone number is registered
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      final snapshot = await _db.child('users')
          .orderByChild('phoneNumber')
          .equalTo(phoneNumber)
          .get();
      return snapshot.exists;
    } catch (e) {
      throw Exception('Failed to check phone number registration: $e');
    }
  }

  // Check if a phone number is unique (excluding the current user)
  Future<bool> isPhoneNumberUnique(String phoneNumber, String currentUserId) async {
    try {
      final snapshot = await _db.child('users')
          .orderByChild('phoneNumber')
          .equalTo(phoneNumber)
          .get();

      if (!snapshot.exists) {
        return true; // Phone number is unique
      }

      // Check if the phone number belongs to the current user
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final userIds = data.keys.toList();
      return userIds.length == 1 && userIds.first == currentUserId;
    } catch (e) {
      throw Exception('Failed to check phone number uniqueness: $e');
    }
  }

  // Fetch user profile data from Firebase Realtime Database
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final snapshot = await _db.child('users').child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }
}