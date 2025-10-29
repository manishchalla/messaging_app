// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile.dart';
import '../contacts_grid/contacts_grid_screen.dart';
import 'otp_verification_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  final _profileService = ProfileService();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null && user.displayName != null) {
      _nameController.text = user.displayName!;
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleanedNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure exactly 10 digits
    if (cleanedNumber.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  // Format for Firebase Auth (E.164 format with country code)
  // This is what Firebase Auth needs for verification
  String _formatPhoneNumberForAuth(String input) {
    // Keep only digits
    String digits = input.replaceAll(RegExp(r'[^\d+]'), '');

    // Ensure we have exactly 10 digits
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    // Format as +1XXXXXXXXXX for US/CA numbers
    return '+1$digits';
  }

  // Format for database storage (just 10 digits)
  // This is what we'll store in the database
  String _formatPhoneNumberForStorage(String input) {
    // Keep only digits
    String digits = input.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure we have exactly 10 digits
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    return digits;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Format for both purposes
      final e164PhoneNumber = _formatPhoneNumberForAuth(_phoneController.text);
      final storagePhoneNumber = _formatPhoneNumberForStorage(_phoneController.text);

      // Check uniqueness
      final isUnique = await _profileService.isPhoneNumberUnique(
          storagePhoneNumber,
          user.uid
      );

      if (!isUnique) {
        setState(() {
          _errorMessage = 'This phone number is already registered by another user';
          _isSubmitting = false;
        });
        return;
      }

      // Navigate to OTP verification screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: e164PhoneNumber,  // Send E.164 format to Firebase Auth
              displayName: _nameController.text,
              userId: user.uid,
              photoUrl: user.photoURL,
              storagePhoneNumber: storagePhoneNumber,  // Also send the storage format
            ),
          ),
        ).then((_) {
          // Reset the loading state when returning from OTP screen
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Complete Your Profile'),
              automaticallyImplyLeading: false,
              expandedHeight: 150,
              pinned: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile image
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Hero(
                        tag: 'profile_image',
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue[800],
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email (read-only)
                        TextFormField(
                          initialValue: user?.email ?? '',
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            enabled: false,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter your full name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                          value?.isEmpty == true ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Phone number field
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '(555) 123-4567',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                            helperText: 'Enter 10 digits without country code',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _phoneController.clear(),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: _validatePhoneNumber,
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade800),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sign out option
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              await _authService.signOut();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}