class PhoneValidator {
  static String _digitsOnly(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in input.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  // Philippine mobile number patterns
  static const List<String> _philippineMobilePrefixes = [
    '0905', '0906', '0907', '0908', '0909', // Globe/TM
    '0910',
    '0911',
    '0912',
    '0913',
    '0914',
    '0915',
    '0916',
    '0917',
    '0918',
    '0919',
    '0920',
    '0921',
    '0922',
    '0923',
    '0924',
    '0925',
    '0926',
    '0927',
    '0928',
    '0929',
    '0930',
    '0931',
    '0932',
    '0933',
    '0934',
    '0935',
    '0936',
    '0937',
    '0938',
    '0939',
    '0940',
    '0941',
    '0942',
    '0943',
    '0944',
    '0945',
    '0946',
    '0947',
    '0948',
    '0949',
    '0950',
    '0951',
    '0952',
    '0953',
    '0954',
    '0955',
    '0956',
    '0957',
    '0958',
    '0959',
    '0960',
    '0961',
    '0962',
    '0963',
    '0964',
    '0965',
    '0966',
    '0967',
    '0968',
    '0969',
    '0970',
    '0971',
    '0972',
    '0973',
    '0974',
    '0975',
    '0976',
    '0977',
    '0978',
    '0979',
    '0980',
    '0981',
    '0982',
    '0983',
    '0984',
    '0985',
    '0986',
    '0987',
    '0988',
    '0989',
    '0990',
    '0991',
    '0992',
    '0993',
    '0994',
    '0995',
    '0996',
    '0997',
    '0998',
    '0999',
    // Smart/Sun
    '0813',
    '0817',
    '0821',
    '0823',
    '0824',
    '0825',
    '0826',
    '0827',
    '0828',
    '0829',
    '0830',
    '0831',
    '0832',
    '0833',
    '0834',
    '0835',
    '0836',
    '0837',
    '0838',
    '0839',
    '0840',
    '0841',
    '0842',
    '0843',
    '0844',
    '0845',
    '0846',
    '0847',
    '0848',
    '0849',
    '0850',
    '0851',
    '0852',
    '0853',
    '0854',
    '0855',
    '0856',
    '0857',
    '0858',
    '0859',
    '0860',
    '0861',
    '0862',
    '0863',
    '0864',
    '0865',
    '0866',
    '0867',
    '0868',
    '0869',
    '0870',
    '0871',
    '0872',
    '0873',
    '0874',
    '0875',
    '0876',
    '0877',
    '0878',
    '0879',
    '0880',
    '0881',
    '0882',
    '0883',
    '0884',
    '0885',
    '0886',
    '0887',
    '0888',
    '0889',
    '0890',
    '0891',
    '0892',
    '0893',
    '0894',
    '0895',
    '0896',
    '0897',
    '0898',
    '0899',
    // DITO
    '0895', '0896', '0897', '0898', '0899',
    // GOMO
    '0927', '0928', '0929',
  ];

  /// Validates if a phone number is a valid Philippine mobile number
  /// Returns true if valid, false otherwise
  static bool isValidPhilippineMobile(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;

    // Remove all non-digit characters
    String cleanNumber = _digitsOnly(phoneNumber);

    // Check if it's exactly 11 digits
    if (cleanNumber.length != 11) return false;

    // Check if it starts with 0
    if (!cleanNumber.startsWith('0')) return false;

    // Check if the first 4 digits match any Philippine mobile prefix
    String prefix = cleanNumber.substring(0, 4);
    return _philippineMobilePrefixes.contains(prefix);
  }

  /// Validates if a phone number is a valid Philippine mobile number
  /// Returns a validation result with error message if invalid
  static PhoneValidationResult validatePhilippineMobile(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'Phone number is required',
      );
    }

    // Remove all non-digit characters
    String cleanNumber = _digitsOnly(phoneNumber);

    // Check if it's exactly 11 digits
    if (cleanNumber.length != 11) {
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'Phone number must be exactly 11 digits',
      );
    }

    // Check if it starts with 0
    if (!cleanNumber.startsWith('0')) {
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'Philippine mobile numbers must start with 0',
      );
    }

    // Check if the first 4 digits match any Philippine mobile prefix
    String prefix = cleanNumber.substring(0, 4);
    if (!_philippineMobilePrefixes.contains(prefix)) {
      return PhoneValidationResult(
        isValid: false,
        errorMessage:
            'Invalid Philippine mobile number prefix. Must be a valid Globe, Smart, DITO, or GOMO number',
      );
    }

    return PhoneValidationResult(isValid: true);
  }

  /// Formats a Philippine mobile number for display
  /// Input: 09123456789
  /// Output: +63 912 345 6789
  static String formatPhilippineMobile(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';

    String cleanNumber = _digitsOnly(phoneNumber);

    if (cleanNumber.length == 11 && cleanNumber.startsWith('0')) {
      // Remove the leading 0 and add +63
      String withoutZero = cleanNumber.substring(1);
      return '+63 ${withoutZero.substring(0, 3)} ${withoutZero.substring(3, 6)} ${withoutZero.substring(6)}';
    }

    return phoneNumber; // Return original if not in expected format
  }

  /// Cleans a phone number by removing all non-digit characters
  static String cleanPhoneNumber(String phoneNumber) {
    return _digitsOnly(phoneNumber);
  }
}

class PhoneValidationResult {
  final bool isValid;
  final String? errorMessage;

  PhoneValidationResult({required this.isValid, this.errorMessage});
}
