import 'constants.dart';

class Validators {
  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.emailRequired;
    }

    if (!AppRegex.email.hasMatch(value)) {
      return ErrorMessages.emailInvalid;
    }

    return null;
  }

  /// Nickname validation
  static String? nickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.nicknameRequired;
    }

    if (value.trim().length > 50) {
      return ErrorMessages.nicknameTooLong;
    }

    return null;
  }

  /// Folder name validation
  static String? folderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.folderNameRequired;
    }

    if (value.trim().length > 100) {
      return ErrorMessages.folderNameTooLong;
    }

    return null;
  }

  /// Folder description validation (optional)
  static String? folderDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Description too long (max 500 characters)';
    }

    return null;
  }

  /// English word validation - Matches backend validate_english_word
  static String? englishWord(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.wordRequired;
    }

    final cleanValue = value.trim();

    if (cleanValue.length < 2) {
      return 'Word must be at least 2 characters long';
    }

    if (cleanValue.length > 50) {
      return 'Word too long (max 50 characters)';
    }

    if (!AppRegex.englishWord.hasMatch(cleanValue)) {
      return ErrorMessages.invalidEnglishWord;
    }

    return null;
  }

  /// Translation validation (Uzbek)
  static String? translation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.translationRequired;
    }

    final cleanValue = value.trim();

    if (cleanValue.length < 1) {
      return 'Translation cannot be empty';
    }

    if (cleanValue.length > 100) {
      return 'Translation too long (max 100 characters)';
    }

    return null;
  }

  /// Example sentence validation (optional)
  static String? exampleSentence(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final cleanValue = value.trim();

      if (cleanValue.length < 5) {
        return 'Example sentence too short (min 5 characters)';
      }

      if (cleanValue.length > 200) {
        return 'Example sentence too long (max 200 characters)';
      }

      // Basic English text validation
      if (!AppRegex.englishText.hasMatch(cleanValue)) {
        return 'Example sentence contains invalid characters';
      }
    }

    return null;
  }

  /// Required field validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    return null;
  }

  /// Minimum length validation
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.length < minLength) {
      return '${fieldName ?? 'Field'} must be at least $minLength characters';
    }
    return null;
  }

  /// Maximum length validation
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be at most $maxLength characters';
    }
    return null;
  }

  /// Combine multiple validators
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) return result;
    }
    return null;
  }

  /// Password validation (for future use)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return 'Password too long (max 128 characters)';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Phone number validation (international format)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Number validation
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }

    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Field'} must be a valid number';
    }

    return null;
  }

  /// Integer validation
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }

    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'Field'} must be a valid integer';
    }

    return null;
  }

  /// Range validation for numbers
  static String? numberRange(String? value, num min, num max, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return '${fieldName ?? 'Field'} must be a valid number';
    }

    if (numValue < min || numValue > max) {
      return '${fieldName ?? 'Field'} must be between $min and $max';
    }

    return null;
  }

  /// Date validation
  static String? date(String? value, {String? format}) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return format != null
          ? 'Please enter date in $format format'
          : 'Please enter a valid date';
    }
  }

  /// Age validation
  static String? age(String? value) {
    final error = integer(value, fieldName: 'Age');
    if (error != null) return error;

    final ageValue = int.parse(value!);
    if (ageValue < 0 || ageValue > 150) {
      return 'Please enter a valid age';
    }

    return null;
  }

  /// Credit card number validation (basic)
  static String? creditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit card number is required';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Please enter a valid credit card number';
    }

    // Luhn algorithm check
    if (!_isValidLuhn(digitsOnly)) {
      return 'Please enter a valid credit card number';
    }

    return null;
  }

  /// Custom validation function
  static String? custom(String? value, bool Function(String?) validator, String errorMessage) {
    if (!validator(value)) {
      return errorMessage;
    }
    return null;
  }

  /// Helper method for Luhn algorithm (credit card validation)
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);

      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }

      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}

/// Form validation mixin for controllers
mixin FormValidationMixin {
  /// Validate a single field
  String? validateField(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }

  /// Validate multiple fields
  Map<String, String?> validateFields(Map<String, List<String? Function(String?)>> fieldValidators, Map<String, String?> values) {
    final errors = <String, String?>{};

    fieldValidators.forEach((fieldName, validators) {
      final value = values[fieldName];
      errors[fieldName] = validateField(value, validators);
    });

    return errors;
  }

  /// Check if form has any errors
  bool hasErrors(Map<String, String?> errors) {
    return errors.values.any((error) => error != null);
  }

  /// Get first error message
  String? getFirstError(Map<String, String?> errors) {
    return errors.values.firstWhere((error) => error != null, orElse: () => null);
  }
}

/// Common validator combinations
class CommonValidators {
  /// Email field validators
  static List<String? Function(String?)> get email => [
    Validators.required,
    Validators.email,
  ];

  /// Password field validators
  static List<String? Function(String?)> get password => [
    Validators.password,
  ];

  /// Required text field validators
  static List<String? Function(String?)> requiredText({int? minLength, int? maxLength}) => [
    Validators.required,
    if (minLength != null) (value) => Validators.minLength(value, minLength),
    if (maxLength != null) (value) => Validators.maxLength(value, maxLength),
  ];

  /// English word validators
  static List<String? Function(String?)> get englishWord => [
    Validators.englishWord,
  ];

  /// Translation validators
  static List<String? Function(String?)> get translation => [
    Validators.translation,
  ];

  /// Folder name validators
  static List<String? Function(String?)> get folderName => [
    Validators.folderName,
  ];

  /// Nickname validators
  static List<String? Function(String?)> get nickname => [
    Validators.nickname,
  ];
}