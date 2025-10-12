import 'package:flutter_test/flutter_test.dart';
import 'package:capstone/utils/phone_validator.dart';

void main() {
  group('PhoneValidator Tests', () {
    test('Valid Philippine mobile numbers', () {
      // Test Globe/TM numbers
      expect(PhoneValidator.isValidPhilippineMobile('09123456789'), true);
      expect(PhoneValidator.isValidPhilippineMobile('09171234567'), true);
      expect(PhoneValidator.isValidPhilippineMobile('09271234567'), true);

      // Test Smart/Sun numbers
      expect(
        PhoneValidator.isValidPhilippineMobile('08123456789'),
        false,
      ); // Invalid prefix
      expect(PhoneValidator.isValidPhilippineMobile('08171234567'), true);
      expect(PhoneValidator.isValidPhilippineMobile('08211234567'), true);

      // Test DITO numbers
      expect(PhoneValidator.isValidPhilippineMobile('08951234567'), true);
      expect(PhoneValidator.isValidPhilippineMobile('08961234567'), true);

      // Test GOMO numbers
      expect(PhoneValidator.isValidPhilippineMobile('09271234567'), true);
      expect(PhoneValidator.isValidPhilippineMobile('09281234567'), true);
    });

    test('Invalid Philippine mobile numbers', () {
      // Too short
      expect(PhoneValidator.isValidPhilippineMobile('0912345678'), false);

      // Too long
      expect(PhoneValidator.isValidPhilippineMobile('091234567890'), false);

      // Doesn't start with 0
      expect(PhoneValidator.isValidPhilippineMobile('19123456789'), false);

      // Invalid prefix
      expect(PhoneValidator.isValidPhilippineMobile('08001234567'), false);
      expect(PhoneValidator.isValidPhilippineMobile('09991234567'), false);

      // Empty string
      expect(PhoneValidator.isValidPhilippineMobile(''), false);

      // Non-numeric characters
      expect(PhoneValidator.isValidPhilippineMobile('0912-345-6789'), false);
    });

    test('Phone validation with error messages', () {
      // Valid number
      final validResult = PhoneValidator.validatePhilippineMobile(
        '09123456789',
      );
      expect(validResult.isValid, true);
      expect(validResult.errorMessage, null);

      // Empty number
      final emptyResult = PhoneValidator.validatePhilippineMobile('');
      expect(emptyResult.isValid, false);
      expect(emptyResult.errorMessage, 'Phone number is required');

      // Wrong length
      final wrongLengthResult = PhoneValidator.validatePhilippineMobile(
        '0912345678',
      );
      expect(wrongLengthResult.isValid, false);
      expect(
        wrongLengthResult.errorMessage,
        'Phone number must be exactly 11 digits',
      );

      // Doesn't start with 0
      final noZeroResult = PhoneValidator.validatePhilippineMobile(
        '19123456789',
      );
      expect(noZeroResult.isValid, false);
      expect(
        noZeroResult.errorMessage,
        'Philippine mobile numbers must start with 0',
      );

      // Invalid prefix
      final invalidPrefixResult = PhoneValidator.validatePhilippineMobile(
        '08001234567',
      );
      expect(invalidPrefixResult.isValid, false);
      expect(
        invalidPrefixResult.errorMessage,
        'Invalid Philippine mobile number prefix. Must be a valid Globe, Smart, DITO, or GOMO number',
      );
    });

    test('Phone number formatting', () {
      expect(
        PhoneValidator.formatPhilippineMobile('09123456789'),
        '+63 912 345 6789',
      );
      expect(
        PhoneValidator.formatPhilippineMobile('08171234567'),
        '+63 817 123 4567',
      );
      expect(PhoneValidator.formatPhilippineMobile(''), '');
      expect(
        PhoneValidator.formatPhilippineMobile('1234567890'),
        '1234567890',
      ); // Invalid format, return original
    });

    test('Phone number cleaning', () {
      expect(PhoneValidator.cleanPhoneNumber('0912-345-6789'), '09123456789');
      expect(
        PhoneValidator.cleanPhoneNumber('+63 912 345 6789'),
        '639123456789',
      );
      expect(PhoneValidator.cleanPhoneNumber('0912 345 6789'), '09123456789');
      expect(PhoneValidator.cleanPhoneNumber('0912.345.6789'), '09123456789');
      expect(PhoneValidator.cleanPhoneNumber('0912(345)6789'), '09123456789');
    });
  });
}
