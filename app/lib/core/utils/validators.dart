import 'package:flutter/foundation.dart';

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  bool get hasError => !isValid && errorMessage != null;
}

/// Email validator
class EmailValidator {
  static const String _emailPattern = 
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  static ValidationResult validate(String? email) {
    if (email == null || email.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Email is required',
      );
    }

    final emailRegex = RegExp(_emailPattern);
    if (!emailRegex.hasMatch(email)) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid email address',
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// Password validator
class PasswordValidator {
  static const int _minLength = 8;

  static ValidationResult validate(String? password) {
    if (password == null || password.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password is required',
      );
    }

    if (password.length < _minLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Password must be at least $_minLength characters long',
      );
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one uppercase letter',
      );
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one lowercase letter',
      );
    }

    if (!password.contains(RegExp(r'\d'))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one number',
      );
    }

    if (!password.contains(RegExp(r'[@$!%*?&]'))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one special character',
      );
    }

    return const ValidationResult(isValid: true);
  }

  static ValidationResult validateStrength(String? password) {
    if (password == null || password.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password is required',
      );
    }

    int score = 0;

    // Length check
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;

    // Character type checks
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'\d'))) score += 1;
    if (password.contains(RegExp(r'[@$!%*?&]'))) score += 1;

    String strength;
    String? errorMessage;

    if (score >= 6) {
      strength = 'Strong';
    } else if (score >= 4) {
      strength = 'Medium';
    } else {
      strength = 'Weak';
      errorMessage = 'Password is too weak. Please choose a stronger password.';
    }

    return ValidationResult(
      isValid: score >= 4,
      errorMessage: errorMessage,
    );
  }
}

/// Phone number validator
class PhoneValidator {
  static ValidationResult validate(String? phone) {
    if (phone == null || phone.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Phone number is required',
      );
    }

    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it starts with + for international format
    if (cleanedPhone.startsWith('+')) {
      // International format: +[country code][number]
      if (cleanedPhone.length < 8) {
        return const ValidationResult(
          isValid: false,
          errorMessage: 'Please enter a valid phone number',
        );
      }
    } else {
      // Domestic format
      if (cleanedPhone.length < 10) {
        return const ValidationResult(
          isValid: false,
          errorMessage: 'Phone number must be at least 10 digits',
        );
      }
    }

    return const ValidationResult(isValid: true);
  }
}

/// Name validator
class NameValidator {
  static ValidationResult validate(String? name) {
    if (name == null || name.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Name is required',
      );
    }

    if (name.trim().isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Name cannot be empty',
      );
    }

    if (name.length < 2) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Name must be at least 2 characters long',
      );
    }

    if (name.length > 50) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Name must be less than 50 characters',
      );
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Name can only contain letters, spaces, hyphens, and apostrophes',
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// URL validator
class UrlValidator {
  static ValidationResult validate(String? url) {
    if (url == null || url.isEmpty) {
      return const ValidationResult(isValid: true); // URL is optional
    }

    try {
      final uri = Uri.parse(url);
      if (!['http', 'https'].contains(uri.scheme)) {
        return const ValidationResult(
          isValid: false,
          errorMessage: 'URL must start with http:// or https://',
        );
      }
      return const ValidationResult(isValid: true);
    } catch (e) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid URL',
      );
    }
  }
}

/// File size validator
class FileSizeValidator {
  static ValidationResult validate({
    int? fileSizeInBytes,
    int? maxSizeInMB = 10,
  }) {
    if (fileSizeInBytes == null) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'File size is required',
      );
    }

    final maxSizeInBytes = maxSizeInMB! * 1024 * 1024;

    if (fileSizeInBytes > maxSizeInBytes) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'File size must be less than ${maxSizeInMB}MB',
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// Age validator
class AgeValidator {
  static ValidationResult validate(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Birth date is required',
      );
    }

    try {
      final date = DateTime.parse(birthDate);
      final now = DateTime.now();
      final age = now.year - date.year;

      if (age < 13) {
        return const ValidationResult(
          isValid: false,
          errorMessage: 'You must be at least 13 years old',
        );
      }

      if (age > 120) {
        return const ValidationResult(
          isValid: false,
          errorMessage: 'Please enter a valid birth date',
        );
      }

      return const ValidationResult(isValid: true);
    } catch (e) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid birth date',
      );
    }
  }
}

/// Credit card validator
class CreditCardValidator {
  static ValidationResult validate(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Card number is required',
      );
    }

    final cleanedNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedNumber.length < 13 || cleanedNumber.length > 19) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid card number',
      );
    }

    // Luhn algorithm check
    if (!_isValidLuhnNumber(cleanedNumber)) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid card number',
      );
    }

    return const ValidationResult(isValid: true);
  }

  static bool _isValidLuhnNumber(String number) {
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit / 10).floor() + digit % 10;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  static ValidationResult validateExpiryDate(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Expiry date is required',
      );
    }

    final parts = expiryDate.split('/');
    if (parts.length != 2) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter expiry date in MM/YY format',
      );
    }

    try {
      final month = int.parse(parts[0]);
      final year = int.parse('20${parts[1]}');

      if (month < 1 || month > 12) {
        return const ValidationResult(
          isValid: false,
          errorMessage: 'Please enter a valid month',
        );
      }

      final now = DateTime.now();
      final expiry = DateTime(year, month);

      if (expiry.isBefore(now)) {
        return const ValidationResult(
          isValid: false,
          errorMessage: 'Card has expired',
        );
      }

      return const ValidationResult(isValid: true);
    } catch (e) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid expiry date',
      );
    }
  }

  static ValidationResult validateCVV(String? cvv) {
    if (cvv == null || cvv.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'CVV is required',
      );
    }

    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'CVV must be 3 or 4 digits',
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// Generic required field validator
class RequiredFieldValidator {
  static ValidationResult validate(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName is required',
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// Minimum length validator
class MinLengthValidator {
  static ValidationResult validate(
    String? value, {
    required int minLength,
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName is required',
      );
    }

    if (value.length < minLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName must be at least $minLength characters long',
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// Maximum length validator
class MaxLengthValidator {
  static ValidationResult validate(
    String? value, {
    required int maxLength,
    String fieldName = 'Field',
  }) {
    if (value == null) {
      return ValidationResult(isValid: true); // Optional field
    }

    if (value.length > maxLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName must be less than $maxLength characters',
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// Pattern validator
class PatternValidator {
  static ValidationResult validate(
    String? value, {
    required RegExp pattern,
    String errorMessage = 'Invalid format',
    String? fieldName,
    bool allowEmpty = true,
  }) {
    if (value == null || value.isEmpty) {
      if (allowEmpty) {
        return const ValidationResult(isValid: true);
      }
      return ValidationResult(
        isValid: false,
        errorMessage: '${fieldName ?? 'Field'} is required',
      );
    }

    if (!pattern.hasMatch(value)) {
      return ValidationResult(
        isValid: false,
        errorMessage: errorMessage,
      );
    }

    return const ValidationResult(isValid: true);
  }
}

/// Composed validator that combines multiple validators
class ComposedValidator {
  final List<ValidationResult Function(String?)> _validators;

  ComposedValidator(this._validators);

  ValidationResult validate(String? value) {
    for (final validator in _validators) {
      final result = validator(value);
      if (!result.isValid) {
        return result;
      }
    }
    return const ValidationResult(isValid: true);
  }
}

/// Common validation patterns
class ValidationPatterns {
  static const RegExp email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static const RegExp phone = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
  static const RegExp url = RegExp(r'https?://[^\s$.?#].[^\s]*');
  static const RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
  static const RegExp numeric = RegExp(r'^[0-9]+$');
  static const RegExp alphabetic = RegExp(r'^[a-zA-Z]+$');
  static const RegExp hexColor = RegExp(r'^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
  static const RegExp postalCode = RegExp(r'^[0-9]{5}(-[0-9]{4})?$');
  static const RegExp username = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
}