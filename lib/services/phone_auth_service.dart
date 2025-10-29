// lib/services/phone_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';

class PhoneAuthService {
  final FirebaseAuth _auth;

  // Singleton pattern
  static final PhoneAuthService _instance = PhoneAuthService._internal();
  factory PhoneAuthService() => _instance;
  PhoneAuthService._internal() : _auth = FirebaseAuth.instance;

  // Dependency injection constructor for testing
  @visibleForTesting
  PhoneAuthService.test(this._auth);

  // Start phone verification process
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationCompleted,
    required Function(String) onVerificationFailed,
    required Function() onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification
        try {
          await _auth.currentUser?.updatePhoneNumber(credential);
          onVerificationCompleted('Phone number verified automatically');
        } catch (e) {
          onVerificationFailed('Auto-verification failed: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onVerificationFailed('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onCodeAutoRetrievalTimeout();
      },
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP
  Future<bool> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      // Create credential
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Link phone number to current user
      await _auth.currentUser?.updatePhoneNumber(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle specific error cases
      if (e.code == 'invalid-verification-code') {
        throw Exception('The verification code is invalid. Please try again.');
      } else if (e.code == 'session-expired') {
        throw Exception('The verification code has expired. Please request a new code.');
      } else {
        throw Exception('Verification failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Verification failed. Please try again.');
    }
  }

  // For development/testing - mock verification
  Future<bool> mockVerifyOTP({
    required String smsCode,
  }) async {
    try {
      // In real implementation, verify against verificationId
      // For testing, accept any 6-digit code
      await Future.delayed(const Duration(seconds: 1));

      // For testing purposes only
      return smsCode.length == 6;
    } catch (e) {
      return false;
    }
  }
}