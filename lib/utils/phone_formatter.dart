import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  final String mask;
  final String separator;

  PhoneNumberFormatter({
    this.mask = '+# (###) ###-####',
    this.separator = '#',
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue
      ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Strip all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle the case where the user is typing a new '+' at the beginning
    if (newValue.text.length > oldValue.text.length &&
        newValue.text.startsWith('+') &&
        !oldValue.text.startsWith('+')) {
      return newValue;
    }

    // Build the formatted string
    final formattedText = _formatByMask(digitsOnly);

    // Calculate the new cursor position
    final cursorPosition = newValue.selection.start;
    final oldFormattedLength = oldValue.text.length;
    final newFormattedLength = formattedText.length;
    final digitsOnlyLength = digitsOnly.length;
    final oldDigitsOnlyLength = oldValue.text.replaceAll(RegExp(r'[^\d+]'), '').length;

    int newCursorOffset = cursorPosition;

    // Adjust cursor position based on added/removed formatting characters
    if (digitsOnlyLength > oldDigitsOnlyLength) {
      // Adding digits
      newCursorOffset += (newFormattedLength - oldFormattedLength);
    } else if (digitsOnlyLength < oldDigitsOnlyLength) {
      // Removing digits
      newCursorOffset -= (oldFormattedLength - newFormattedLength);
    }

    // Make sure the cursor position is valid
    newCursorOffset = newCursorOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }

  String _formatByMask(String digits) {
    if (digits.isEmpty) return '';

    // Keep track of mask position and digit position
    int maskIndex = 0;
    int digitIndex = 0;
    final formattedText = StringBuffer();

    // Handle the first character being a +
    if (digits.startsWith('+')) {
      formattedText.write('+');
      digitIndex = 1;
      maskIndex = 1; // Skip the first # in the mask
    }

    // Process the rest of the string
    while (maskIndex < mask.length && digitIndex < digits.length) {
      if (mask[maskIndex] == separator) {
        // This is a placeholder for a digit
        formattedText.write(digits[digitIndex]);
        digitIndex++;
      } else {
        // This is a formatting character
        formattedText.write(mask[maskIndex]);
      }
      maskIndex++;
    }

    return formattedText.toString();
  }
}