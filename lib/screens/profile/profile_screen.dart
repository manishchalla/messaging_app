import 'dart:io';
import 'package:cocolab_messaging/screens/profile/profile_form.dart';
import 'package:cocolab_messaging/screens/profile/profile_picture_editor.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService? authService;
  final ProfileService? profileService;

  const ProfileScreen({
    super.key,
    this.authService,
    this.profileService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthService _authService = AuthService();
  late ProfileService _profileService = ProfileService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    // Use provided services or default to instantiated services
    _authService = widget.authService ?? AuthService();
    _profileService = widget.profileService ?? ProfileService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _profileService.getProfile(user.uid);
        if (profile != null) {
          setState(() {
            _nameController.text = profile.displayName ?? '';
            _phoneController.text = profile.phoneNumber ?? '';
            _photoUrl = profile.photoUrl;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isUpdating = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Normalize the phone number
        final normalizedPhoneNumber = _normalizePhoneNumber(_phoneController.text);

        // Check if the phone number is unique (excluding the current user)
        final isUnique = await _profileService.isPhoneNumberUnique(
          normalizedPhoneNumber,
          user.uid, // Pass the current user's ID
        );
        if (!isUnique) {
          _showSnackBar('This phone number is already registered.');
          return;
        }

        // Fetch the existing profile to preserve the fcmToken
        final existingProfile = await _profileService.getProfile(user.uid);
        final existingFcmToken = existingProfile?.fcmToken;

        // Create the updated user profile
        final profile = UserProfile(
          phoneNumber: normalizedPhoneNumber,
          displayName: _nameController.text.isNotEmpty ? _nameController.text : 'Unknown',
          photoUrl: _photoUrl,
          lastUpdated: DateTime.now(),
          fcmToken: existingFcmToken, // Preserve the existing fcmToken
        );

        // Save the updated profile to Firebase
        await _profileService.updateProfile(user.uid, profile);
        _showSnackBar('Profile updated successfully');
        await _loadUserData(); // Refresh the UI with updated data
      }
    } catch (e) {
      _showSnackBar('Failed to update profile: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<String> _promptForPhoneNumber() async {
    String? phoneNumber;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Identity'),
        content: TextField(
          keyboardType: TextInputType.phone,
          onChanged: (value) => phoneNumber = value,
          decoration: const InputDecoration(labelText: 'Enter your phone number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (phoneNumber != null && phoneNumber!.isNotEmpty) {
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (phoneNumber == null || phoneNumber!.isEmpty) {
      throw Exception('Phone number is required for verification.');
    }
    return phoneNumber!;
  }


// Helper method to verify user identity
  Future<String?> _verifyUserIdentity() async {
    final userProfile = await _profileService.getProfile(_authService.currentUser!.uid);
    if (userProfile == null) {
      _showSnackBar('Could not retrieve your profile.');
      return null;
    }

    String? enteredPhoneNumber;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Identity'),
        content: TextField(
          keyboardType: TextInputType.phone,
          onChanged: (value) => enteredPhoneNumber = value,
          decoration: const InputDecoration(labelText: 'Enter your phone number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (enteredPhoneNumber != null && enteredPhoneNumber!.isNotEmpty) {
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (enteredPhoneNumber == null || enteredPhoneNumber!.isEmpty) {
      return null;
    }

    // Compare normalized phone numbers
    final normalizedEntered = _normalizePhoneNumber(enteredPhoneNumber!);
    final normalizedStored = _normalizePhoneNumber(userProfile.phoneNumber);

    if (normalizedEntered != normalizedStored) {
      _showSnackBar('Phone number does not match. Please try again.');
      return null;
    }

    return enteredPhoneNumber;
  }


  String _normalizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except the '+' sign
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ProfilePictureEditor(
              photoUrl: _photoUrl,
              onImagePicked: (File? imageFile) async {
                if (imageFile != null) {
                  final user = _authService.currentUser;
                  if (user != null) {
                    final newPhotoUrl =
                    await _profileService.uploadProfileImage(user.uid, imageFile);
                    setState(() => _photoUrl = newPhotoUrl);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            ProfileForm(
              nameController: _nameController,
              phoneController: _phoneController,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isUpdating ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_isUpdating ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}