import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('Android options are correctly configured', () {
      final androidOptions = DefaultFirebaseOptions.getAndroidOptions();
      expect(androidOptions, equals(DefaultFirebaseOptions.android));
      expect(androidOptions.apiKey, equals('AIzaSyBHSUYTYlBXn_W83dviRr5JL6TbJmtzADY'));
      expect(androidOptions.appId, equals('1:606308628937:android:d1dc048fb053ad0bb35018'));
    });

    test('iOS options are correctly configured', () {
      final iosOptions = DefaultFirebaseOptions.getIOSOptions();
      expect(iosOptions, equals(DefaultFirebaseOptions.ios));
      expect(iosOptions.apiKey, equals('AIzaSyDfWRDIrHc18g21SHMlKpVP6Bh9ZEhHX8g'));
      expect(iosOptions.appId, equals('1:606308628937:ios:339145ec50251d6db35018'));
    });

    test('macOS options are correctly configured', () {
      final macosOptions = DefaultFirebaseOptions.getMacOSOptions();
      expect(macosOptions, equals(DefaultFirebaseOptions.macos));
      expect(macosOptions.apiKey, equals('AIzaSyDfWRDIrHc18g21SHMlKpVP6Bh9ZEhHX8g'));
      expect(macosOptions.appId, equals('1:606308628937:ios:339145ec50251d6db35018'));
    });

    test('Windows options are correctly configured', () {
      final windowsOptions = DefaultFirebaseOptions.getWindowsOptions();
      expect(windowsOptions, equals(DefaultFirebaseOptions.windows));
      expect(windowsOptions.apiKey, equals('AIzaSyBOt-ZQE_CB1kRVm74S-aCl9MRWWpeE0Oo'));
      expect(windowsOptions.appId, equals('1:606308628937:web:9c31a8ee5924316bb35018'));
    });

    test('Linux platform throws correct error', () {
      expect(
          DefaultFirebaseOptions.throwLinuxError,
          throwsA(isA<UnsupportedError>().having(
                  (e) => e.message,
              'message',
              contains('DefaultFirebaseOptions have not been configured for linux')
          ))
      );
    });

    test('Default/unknown platform throws correct error', () {
      expect(
          DefaultFirebaseOptions.throwDefaultError,
          throwsA(isA<UnsupportedError>().having(
                  (e) => e.message,
              'message',
              equals('DefaultFirebaseOptions are not supported for this platform.')
          ))
      );
    });

    // Test web options
    test('Web options are correctly configured', () {
      final webOptions = DefaultFirebaseOptions.web;
      expect(webOptions.apiKey, equals('AIzaSyBOt-ZQE_CB1kRVm74S-aCl9MRWWpeE0Oo'));
      expect(webOptions.appId, equals('1:606308628937:web:121dbfff45756ab0b35018'));
      expect(webOptions.projectId, equals('cocolab-40e6f'));
    });

    // Test currentPlatform based on actual test platform
    test('currentPlatform returns options for the current platform', () {
      final currentOptions = DefaultFirebaseOptions.currentPlatform;
      expect(currentOptions, isA<FirebaseOptions>());
      expect(currentOptions.projectId, equals('cocolab-40e6f'));
    });
  });
}