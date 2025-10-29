// lib/screens/onboarding/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/phone_auth_service.dart';
import '../../services/profile_service.dart';
import '../contacts_grid/contacts_grid_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber; // E.164 format for Firebase Auth
  final String displayName;
  final String userId;
  final String? photoUrl;
  final String storagePhoneNumber; // 10-digit format for database

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.displayName,
    required this.userId,
    this.photoUrl,
    required this.storagePhoneNumber,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _profileService = ProfileService();
  final _phoneAuthService = PhoneAuthService();

  String? _verificationId;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use Firebase Phone Auth in production
      await _phoneAuthService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your phone number')),
          );
          _startResendTimer();
        },
        onVerificationCompleted: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          _saveProfileAndNavigate();
        },
        onVerificationFailed: (error) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        },
        onCodeAutoRetrievalTimeout: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP auto-retrieval timed out')),
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP: $e';
        _isLoading = false;
      });
    }
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool verified;

      if (_verificationId != null) {
        // Use Firebase Phone Auth in production
        verified = await _phoneAuthService.verifyOTP(
          verificationId: _verificationId!,
          smsCode: otp,
        );
      } else {
        // Fallback to mock verification for testing
        verified = await _phoneAuthService.mockVerifyOTP(smsCode: otp);
      }

      if (verified) {
        await _saveProfileAndNavigate();
      } else {
        setState(() {
          _errorMessage = 'Invalid verification code';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileAndNavigate() async {
    try {
      // Create user profile with verified status - use storage format (10 digits)
      final userProfile = UserProfile(
        phoneNumber: widget.storagePhoneNumber,
        displayName: widget.displayName,
        photoUrl: widget.photoUrl,
        lastUpdated: DateTime.now(),
        fcmToken: null, // Will be handled by AuthService later
      );

      // Save the profile
      await _profileService.updateProfile(widget.userId, userProfile);

      // Save FCM token
      await _authService.saveFcmToken(widget.userId);

      if (mounted) {
        // Navigate to contacts screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ContactsGridScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile: $e';
        _isLoading = false;
      });
    }
  }

  // New method to normalize phone number to just 10 digits
  // For Firebase Auth we need country code, but for storage we don't want it
  String _normalizePhoneNumber(String phoneNumber) {
    // Keep only digits
    String digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure we have exactly 10 digits, taking the last 10 if longer
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    return digits;
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      // Clear existing OTP fields
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      await _sendOtp();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend OTP: $e';
        _isResending = false;
      });
    }
  }

  void _cancelVerification() {
    _timer?.cancel();

    // Pop with result so the previous screen knows we cancelled
    Navigator.pop(context, 'cancelled');
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Phone'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : _cancelVerification,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header illustration
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 30),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 70,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  // Title and instructions
                  Text(
                    'Phone Verification',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ve sent a verification code to',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      widget.phoneNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // OTP input fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                          (index) => SizedBox(
                        width: 45,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              // Move to next field
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                // Last field filled, hide keyboard
                                FocusScope.of(context).unfocus();
                              }
                            } else if (value.isEmpty && index > 0) {
                              // Backspace pressed, move to previous field
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                          validator: (value) =>
                          value?.isEmpty == true ? '' : null,
                        ),
                      ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
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

                  const SizedBox(height: 30),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'VERIFY AND CONTINUE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel button (new)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: _cancelVerification,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timer and resend button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: _resendCountdown > 0 ? null : _resendOtp,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _isResending
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                            : Text(
                          _resendCountdown > 0
                              ? 'Resend in $_resendCountdown s'
                              : 'Resend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _resendCountdown > 0
                                ? theme.colorScheme.onSurface.withOpacity(0.5)
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Help text
                  Text(
                    'Please enter the 6-digit code sent to your phone number for verification.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}