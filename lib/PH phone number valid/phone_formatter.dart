import 'package:flutter/services.dart';

class PhoneFormatter {
  /// Formats a phone number with spaces: 09123456789 -> 0912 345 6789
  static String formatWithSpaces(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';

    // Remove all non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If it's 11 digits, format as 0912 345 6789
    if (cleanNumber.length == 11) {
      return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4, 7)} ${cleanNumber.substring(7)}';
    }

    // If it's 10 digits, format as 912 345 6789
    if (cleanNumber.length == 10) {
      return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';
    }

    // Return original if not standard length
    return phoneNumber;
  }

  /// Creates a TextInputFormatter for phone number input with automatic spacing
  static TextInputFormatter get phoneNumberFormatter {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      // Remove all non-digit characters
      String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

      // Limit to 11 digits
      if (newText.length > 11) {
        newText = newText.substring(0, 11);
      }

      // Format with spaces
      String formatted = '';
      if (newText.isNotEmpty) {
        if (newText.length <= 4) {
          formatted = newText;
        } else if (newText.length <= 7) {
          formatted = '${newText.substring(0, 4)} ${newText.substring(4)}';
        } else {
          formatted =
              '${newText.substring(0, 4)} ${newText.substring(4, 7)} ${newText.substring(7)}';
        }
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  /// Cleans a formatted phone number by removing spaces
  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }
}
