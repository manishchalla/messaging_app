import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import '../models/user_profile.dart';
import 'profile_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) :
        _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to clear any existing state
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print("Error signing out from Google: $e");
      }

      // Now sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        final UserCredential userCredential = await _auth.signInWithCredential(credential);

        // Save FCM token after login
        await saveFcmToken(userCredential.user!.uid);

        return userCredential;
      } catch (e) {
        print("Error signing in with credential: $e");

        // If error indicates credential is associated with different account,
        // try to handle by force-disconnecting Google account
        if (e.toString().contains("already associated with different")) {
          try {
            // Force disconnect and try again
            await _googleSignIn.disconnect();
            await _googleSignIn.signOut();

            // Try sign-in again after force disconnect
            final newGoogleUser = await _googleSignIn.signIn();
            if (newGoogleUser == null) return null;

            final newGoogleAuth = await newGoogleUser.authentication;
            final newCredential = GoogleAuthProvider.credential(
              accessToken: newGoogleAuth.accessToken,
              idToken: newGoogleAuth.idToken,
            );

            final newUserCredential = await _auth.signInWithCredential(newCredential);
            await saveFcmToken(newUserCredential.user!.uid);
            return newUserCredential;
          } catch (retryError) {
            print("Error in retry sign-in: $retryError");
            rethrow;
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print("Error in Google sign-in: $e");
      throw Exception('Error signing in with Google: $e');
    }
  }

// Helper to convert email to a valid database key
  String _emailToKey(String email) {
    return email.replaceAll('.', ',').replaceAll('@', '_at_');
  }


  // Update user profile in Firebase Database
  Future<void> updateUserProfile(String displayName, String phoneNumber) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        final profile = UserProfile(
          phoneNumber: phoneNumber,
          displayName: displayName,
          photoUrl: user.photoURL,
          lastUpdated: DateTime.now(),
        );
        await ProfileService().updateProfile(user.uid, profile);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Save FCM token in the database
  Future<void> saveFcmToken(String userId) async {
    try {
      // Retrieve the FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $fcmToken");

      if (fcmToken != null) {
        // Fetch the current user profile
        final userProfile = await ProfileService().getProfile(userId);

        // Update the profile with the new FCM token
        final updatedProfile = UserProfile(
          phoneNumber: userProfile?.phoneNumber ?? '',
          displayName: userProfile?.displayName,
          photoUrl: userProfile?.photoUrl,
          lastUpdated: DateTime.now(),
          fcmToken: fcmToken, // Include the FCM token
        );

        // Save the updated profile in the database
        await ProfileService().updateProfile(userId, updatedProfile);
        print("FCM Token saved successfully for user: $userId");
      } else {
        print("Failed to retrieve FCM token.");
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  // Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}