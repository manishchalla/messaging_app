import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cocolab_messaging/services/phone_auth_service.dart';
import 'dart:async';

@GenerateMocks([FirebaseAuth, User, PhoneAuthCredential])
import 'phone_auth_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockPhoneAuthCredential mockCredential;
  late PhoneAuthService service;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockCredential = MockPhoneAuthCredential();

    when(mockAuth.currentUser).thenReturn(mockUser);
    service = PhoneAuthService.test(mockAuth);
  });

  group('PhoneAuthService', () {
    test('verifyPhoneNumber calls Firebase verifyPhoneNumber and triggers codeSent', () async {
      // Arrange
      final completer = Completer<void>();

      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) {
        // Simulate codeSent callback being triggered
        final codeSent = _.namedArguments[#codeSent] as Function(String, int?);
        codeSent('test-verification-id', null);
        return Future.value();
      });

      // Act
      await service.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        onCodeSent: (verificationId) {
          expect(verificationId, equals('test-verification-id'));
          completer.complete();
        },
        onVerificationCompleted: (_) {},
        onVerificationFailed: (_) {},
        onCodeAutoRetrievalTimeout: () {},
      );

      // Wait for the callback to be triggered
      await completer.future;

      // Assert
      verify(mockAuth.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: const Duration(seconds: 60),
      )).called(1);
    });

    test('verifyPhoneNumber triggers verificationCompleted callback', () async {
      // Arrange
      final completer = Completer<void>();

      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) {
        // Simulate verificationCompleted callback being triggered
        final verificationCompleted = _.namedArguments[#verificationCompleted] as Function(PhoneAuthCredential);
        verificationCompleted(mockCredential);
        return Future.value();
      });

      when(mockUser.updatePhoneNumber(any)).thenAnswer((_) => Future.value());

      // Act
      await service.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        onCodeSent: (_) {},
        onVerificationCompleted: (message) {
          expect(message, equals('Phone number verified automatically'));
          completer.complete();
        },
        onVerificationFailed: (_) {},
        onCodeAutoRetrievalTimeout: () {},
      );

      // Wait for the callback to be triggered
      await completer.future;

      // Assert
      verify(mockAuth.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: const Duration(seconds: 60),
      )).called(1);
      verify(mockUser.updatePhoneNumber(mockCredential)).called(1);
    });

    test('verifyPhoneNumber handles error in verificationCompleted', () async {
      // Arrange
      final completer = Completer<void>();

      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) {
        // Simulate verificationCompleted callback being triggered with error
        final verificationCompleted = _.namedArguments[#verificationCompleted] as Function(PhoneAuthCredential);
        verificationCompleted(mockCredential);
        return Future.value();
      });

      when(mockUser.updatePhoneNumber(any)).thenThrow(Exception('Test error'));

      // Act
      await service.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        onCodeSent: (_) {},
        onVerificationCompleted: (_) {},
        onVerificationFailed: (message) {
          expect(message, contains('Auto-verification failed'));
          completer.complete();
        },
        onCodeAutoRetrievalTimeout: () {},
      );

      // Wait for the callback to be triggered
      await completer.future;

      // Assert
      verify(mockAuth.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: const Duration(seconds: 60),
      )).called(1);
      verify(mockUser.updatePhoneNumber(mockCredential)).called(1);
    });

    test('verifyPhoneNumber triggers verificationFailed callback', () async {
      // Arrange
      final completer = Completer<void>();
      final authException = FirebaseAuthException(code: 'invalid-phone-number', message: 'Invalid phone number');

      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) {
        // Simulate verificationFailed callback being triggered
        final verificationFailed = _.namedArguments[#verificationFailed] as Function(FirebaseAuthException);
        verificationFailed(authException);
        return Future.value();
      });

      // Act
      await service.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        onCodeSent: (_) {},
        onVerificationCompleted: (_) {},
        onVerificationFailed: (message) {
          expect(message, contains('Invalid phone number'));
          completer.complete();
        },
        onCodeAutoRetrievalTimeout: () {},
      );

      // Wait for the callback to be triggered
      await completer.future;

      // Assert
      verify(mockAuth.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: const Duration(seconds: 60),
      )).called(1);
    });

    test('verifyPhoneNumber triggers codeAutoRetrievalTimeout callback', () async {
      // Arrange
      final completer = Completer<void>();

      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) {
        // Simulate codeAutoRetrievalTimeout callback being triggered
        final codeAutoRetrievalTimeout = _.namedArguments[#codeAutoRetrievalTimeout] as Function(String);
        codeAutoRetrievalTimeout('test-verification-id');
        return Future.value();
      });

      // Act
      await service.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        onCodeSent: (_) {},
        onVerificationCompleted: (_) {},
        onVerificationFailed: (_) {},
        onCodeAutoRetrievalTimeout: () {
          completer.complete();
        },
      );

      // Wait for the callback to be triggered
      await completer.future;

      // Assert
      verify(mockAuth.verifyPhoneNumber(
        phoneNumber: '+11234567890',
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        timeout: const Duration(seconds: 60),
      )).called(1);
    });

    test('verifyOTP returns true when authentication succeeds', () async {
      // Arrange
      when(mockUser.updatePhoneNumber(any)).thenAnswer((_) => Future.value());

      // Act
      final result = await service.verifyOTP(
        verificationId: 'test-verification-id',
        smsCode: '123456',
      );

      // Assert
      expect(result, isTrue);
      verify(mockUser.updatePhoneNumber(any)).called(1);
    });

    test('verifyOTP throws exception for invalid code', () async {
      // Arrange
      when(mockUser.updatePhoneNumber(any)).thenThrow(
          FirebaseAuthException(code: 'invalid-verification-code', message: 'Invalid code')
      );

      // Act & Assert
      expect(
            () => service.verifyOTP(
          verificationId: 'test-verification-id',
          smsCode: '123456',
        ),
        throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('verification code is invalid')
        )),
      );
    });

    test('verifyOTP throws exception for expired session', () async {
      // Arrange
      when(mockUser.updatePhoneNumber(any)).thenThrow(
          FirebaseAuthException(code: 'session-expired', message: 'Session expired')
      );

      // Act & Assert
      expect(
            () => service.verifyOTP(
          verificationId: 'test-verification-id',
          smsCode: '123456',
        ),
        throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('verification code has expired')
        )),
      );
    });

    test('verifyOTP throws exception for other Firebase errors', () async {
      // Arrange
      when(mockUser.updatePhoneNumber(any)).thenThrow(
          FirebaseAuthException(code: 'other-error', message: 'Some other error')
      );

      // Act & Assert
      expect(
            () => service.verifyOTP(
          verificationId: 'test-verification-id',
          smsCode: '123456',
        ),
        throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Verification failed: Some other error')
        )),
      );
    });

    test('verifyOTP throws exception for non-Firebase errors', () async {
      // Arrange
      when(mockUser.updatePhoneNumber(any)).thenThrow(Exception('Generic error'));

      // Act & Assert
      expect(
            () => service.verifyOTP(
          verificationId: 'test-verification-id',
          smsCode: '123456',
        ),
        throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Verification failed. Please try again.')
        )),
      );
    });

    test('mockVerifyOTP returns true for 6-digit code', () async {
      final result = await service.mockVerifyOTP(smsCode: '123456');
      expect(result, isTrue);
    });

    test('mockVerifyOTP returns false for non-6-digit code', () async {
      final result = await service.mockVerifyOTP(smsCode: '12345');
      expect(result, isFalse);
    });
  });
}