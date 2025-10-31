extension StringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullNotEmpty => this != null && this!.isNotEmpty;

  /// Capitalize first letter
  String? get capitalize {
    if (this == null || this!.isEmpty) return this;
    return '${this![0].toUpperCase()}${this!.substring(1)}';
  }

  /// Capitalize all words
  String? get capitalizeWords {
    if (this == null || this!.isEmpty) return this;
    return this!
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Remove extra whitespace and normalize
  String? get normalize {
    if (this == null) return this;
    return this!.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Convert to title case
  String? get toTitleCase {
    if (this == null || this!.isEmpty) return this;
    return this!
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  /// Get initials from name
  String? get initials {
    if (this == null || this!.isEmpty) return '';
    
    final words = this!.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
    }
    
    final firstWord = words.first;
    final lastWord = words.last;
    
    return '${firstWord[0].toUpperCase()}${lastWord[0].toUpperCase()}';
  }

  /// Mask email for privacy
  String? get maskEmail {
    if (this == null || !this!.contains('@')) return this;
    
    final parts = this!.split('@');
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '***@$domain';
    }
    
    final maskedUsername = '${username.substring(0, 2)}***';
    return '$maskedUsername@$domain';
  }

  /// Mask phone number
  String? get maskPhone {
    if (this == null || this!.length < 4) return this;
    
    final lastFourDigits = this!.substring(this!.length - 4);
    final maskedDigits = '*' * (this!.length - 4);
    
    return '$maskedDigits$lastFourDigits';
  }

  /// Format phone number with dashes
  String? get formatPhone {
    if (this == null || this!.isEmpty) return this;
    
    final digits = this!.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 10) return this;
    
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    if (this == null) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(this!);
  }

  /// Check if string is a valid phone number
  bool get isValidPhone {
    if (this == null) return false;
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(this!);
  }

  /// Check if string is a valid URL
  bool get isValidUrl {
    if (this == null || this!.isEmpty) return false;
    try {
      final uri = Uri.parse(this!);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Check if string is a strong password
  bool get isStrongPassword {
    if (this == null || this!.length < 8) return false;
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(this!);
  }

  /// Remove all HTML tags
  String? get removeHtmlTags {
    if (this == null) return this;
    return this!.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Truncate string with ellipsis
  String? truncate(int maxLength, {String ellipsis = '...'}) {
    if (this == null || this!.length <= maxLength) return this;
    return '${this!.substring(0, maxLength)}$ellipsis';
  }

  /// Get safe substring
  String? safeSubstring(int startIndex, [int? endIndex]) {
    if (this == null) return this;
    
    final start = startIndex.clamp(0, this!.length);
    final end = endIndex != null 
        ? endIndex.clamp(start, this!.length)
        : this!.length;
    
    return this!.substring(start, end);
  }

  /// Replace multiple spaces with single space
  String? get replaceMultipleSpaces {
    if (this == null) return this;
    return this!.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Check if string contains any of the given substrings
  bool containsAny(List<String> substrings) {
    if (this == null || substrings.isEmpty) return false;
    
    return substrings.any((substring) => this!.contains(substring));
  }

  /// Check if string contains all of the given substrings
  bool containsAll(List<String> substrings) {
    if (this == null || substrings.isEmpty) return false;
    
    return substrings.every((substring) => this!.contains(substring));
  }

  /// Reverse string
  String? get reverse {
    if (this == null) return this;
    return this!.split('').reversed.join();
  }

  /// Get hash code of string
  int? get hash {
    if (this == null) return null;
    return this!.hashCode;
  }

  /// Check if string is palindrome
  bool get isPalindrome {
    if (this == null) return false;
    final cleaned = this!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned == cleaned.split('').reversed.join('');
  }

  /// Convert string to slug
  String? get toSlug {
    if (this == null) return this;
    return this!
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  /// Convert string to kebab-case
  String? get toKebabCase {
    if (this == null) return this;
    return this!
        .replaceAll(RegExp(r'([a-z0-9])([A-Z])'), r'$1-$2')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  /// Convert string to snake_case
  String? get toSnakeCase {
    if (this == null) return this;
    return this!
        .replaceAll(RegExp(r'([a-z0-9])([A-Z])'), r'$1_$2')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Convert string to camelCase
  String? get toCamelCase {
    if (this == null) return this;
    final words = this!
        .replaceAll(RegExp(r'[_-]'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty);
    
    if (words.isEmpty) return this;
    
    final firstWord = words.first.toLowerCase();
    final remainingWords = words
        .skip(1)
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
    
    return '$firstWord$remainingWords';
  }

  /// Get character count
  int? get characterCount {
    if (this == null) return null;
    return this!.length;
  }

  /// Get word count
  int? get wordCount {
    if (this == null || this!.trim().isEmpty) return 0;
    return this!.trim().split(RegExp(r'\s+')).length;
  }

  /// Check if string contains only digits
  bool get isNumeric {
    if (this == null) return false;
    return RegExp(r'^[0-9]+$').hasMatch(this!);
  }

  /// Check if string contains only letters
  bool get isAlpha {
    if (this == null) return false;
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this!);
  }

  /// Check if string contains only alphanumeric characters
  bool get isAlphaNumeric {
    if (this == null) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this!);
  }

  /// Check if string is a hex color
  bool get isHexColor {
    if (this == null) return false;
    final hexColorRegex = RegExp(r'^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexColorRegex.hasMatch(this!);
  }

  /// Convert hex color to Color object
  Color? toColor() {
    if (this == null || !this!.isHexColor) return null;
    
    var hexColor = this!;
    if (hexColor.startsWith('#')) {
      hexColor = hexColor.substring(1);
    }
    
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((char) => char + char).join();
    }
    
    final colorValue = int.parse(hexColor, radix: 16);
    return Color(colorValue);
  }

  /// Get line count
  int? get lineCount {
    if (this == null) return null;
    return this!.split('\n').length;
  }

  /// Get paragraph count
  int? get paragraphCount {
    if (this == null) return null;
    return this!.split('\n\n').length;
  }

  /// Remove diacritics
  String? get removeDiacritics {
    if (this == null) return this;
    return this!.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
  }

  /// Check if string starts with any of the given prefixes
  bool startsWithAny(List<String> prefixes) {
    if (this == null || prefixes.isEmpty) return false;
    return prefixes.any((prefix) => this!.startsWith(prefix));
  }

  /// Check if string ends with any of the given suffixes
  bool endsWithAny(List<String> suffixes) {
    if (this == null || suffixes.isEmpty) return false;
    return suffixes.any((suffix) => this!.endsWith(suffix));
  }
}