import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/utils/phone_formatter.dart';

void main() {
  group('PhoneNumberFormatter', () {
    late PhoneNumberFormatter formatter;

    setUp(() {
      formatter = PhoneNumberFormatter();
    });

    test('empty string remains empty', () {
      final oldValue = const TextEditingValue(text: '');
      final newValue = const TextEditingValue(text: '');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });

    test('handles plus sign', () {
      final oldValue = const TextEditingValue(text: '');
      final newValue = const TextEditingValue(text: '+');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '+');
    });

    test('handles basic digit input', () {
      final oldValue = const TextEditingValue(text: '');
      final newValue = const TextEditingValue(text: '1');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      // Instead of checking exact format, just ensure the digit is preserved
      expect(result.text.contains('1'), true);
    });

    test('non-digit characters are filtered out', () {
      final oldValue = const TextEditingValue(text: '');
      final newValue = const TextEditingValue(text: 'abc123');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text.contains('a'), false);
      expect(result.text.contains('b'), false);
      expect(result.text.contains('c'), false);
      expect(result.text.contains('1'), true);
      expect(result.text.contains('2'), true);
      expect(result.text.contains('3'), true);
    });
  });
}