import 'dart:async' as async_timer;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'constants.dart';
import 'app_colors.dart';

class AppHelpers {
  /// Format date to readable string
  static String formatDate(DateTime date, {String? format}) {
    final formatter = DateFormat(format ?? 'MMM dd, yyyy');
    return formatter.format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime dateTime, {String? format}) {
    final formatter = DateFormat(format ?? 'MMM dd, yyyy HH:mm');
    return formatter.format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1
          ? ''
          : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1
          ? ''
          : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format duration to readable string - Matches backend format_duration
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  /// Calculate accuracy percentage - Matches backend calculate_accuracy
  static int calculateAccuracy(int correct, int total) {
    if (total == 0) return 0;
    return ((correct / total) * 100).round();
  }

  /// Format percentage for display
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Generate random string
  static String generateRandomString(int length) {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
          (_) => characters.codeUnitAt(random.nextInt(characters.length)),
    ));
  }

  /// Generate session ID - Matches backend generate_session_id
  static String generateSessionId({String prefix = 'session'}) {
    final timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    final randomPart = generateRandomString(8);
    return '${prefix}_${timestamp}_$randomPart';
  }

  /// Clean text input - Matches backend clean_text
  static String cleanText(String text) {
    if (text.isEmpty) return '';

    // Remove extra whitespace
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove special characters except basic punctuation
    cleaned = cleaned.replaceAll(RegExp(r"[^\w\s\.\,\!\?\-\']"), '');

    return cleaned;
    }

  /// Validate English word - Matches backend validate_english_word
  static bool validateEnglishWord(String word) {
    return AppRegex.englishWord.hasMatch(word.trim());
  }

  /// Normalize answer for comparison - Matches backend normalize_answer
  static String normalizeAnswer(String answer) {
    if (answer.isEmpty) return '';

    // Convert to lowercase and strip whitespace
    String normalized = answer.toLowerCase().trim();

    // Remove extra spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove common punctuation
    normalized = normalized.replaceAll(RegExp(r'[.,!?;:]'), '');

    return normalized;
  }

  /// Shuffle letters for anagram - Matches backend shuffle_letters
  static String shuffleLetters(String word) {
    final letters = word.toLowerCase().split('');
    final shuffled = List<String>.from(letters);

    // Ensure the shuffled version is different from original
    int attempts = 0;
    while (shuffled.join() == word.toLowerCase() && attempts < 10) {
      shuffled.shuffle();
      attempts++;
    }

    return shuffled.join().toUpperCase();
  }

  /// Get word difficulty - Matches backend get_word_difficulty
  static String getWordDifficulty(String word) {
    final length = word.length;

    if (length <= 4) {
      return 'easy';
    } else if (length <= 7) {
      return 'medium';
    } else {
      return 'hard';
    }
  }

  /// Format quiz time for display - Matches backend format_quiz_time
  static String formatQuizTime(int seconds) {
    if (seconds < 10) {
      return '${seconds}s (Fast!)';
    } else if (seconds < 30) {
      return '${seconds}s (Good)';
    } else {
      return '${seconds}s';
    }
  }

  /// Truncate text to specified length
  static String truncateText(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Get initials from name
  static String getInitials(String name, {int maxChars = 2}) {
    final words = name.trim().split(RegExp(r'\s+'));
    String initials = '';

    for (int i = 0; i < words.length && i < maxChars; i++) {
      if (words[i].isNotEmpty) {
        initials += words[i][0].toUpperCase();
      }
    }

    return initials;
  }

  /// Get color for word category - Matches backend categories
  static Color getCategoryColor(WordCategory category) {
    switch (category) {
      case WordCategory.notKnown:
        return AppColors.notKnownColor;
      case WordCategory.normal:
        return AppColors.normalColor;
      case WordCategory.strong:
        return AppColors.strongColor;
    }
  }

  /// Get color for quiz type
  static Color getQuizTypeColor(QuizType quizType) {
    switch (quizType) {
      case QuizType.anagram:
        return AppColors.anagramColor;
      case QuizType.translationBlitz:
        return AppColors.translationBlitzColor;
      case QuizType.wordBlitz:
        return AppColors.wordBlitzColor;
      case QuizType.reading:
        return AppColors.readingColor;
    }
  }

  /// Get color for voice agent topic
  static Color getVoiceAgentColor(VoiceAgentTopic topic) {
    switch (topic) {
      case VoiceAgentTopic.cars:
        return AppColors.carsColor;
      case VoiceAgentTopic.football:
        return AppColors.footballColor;
      case VoiceAgentTopic.travel:
        return AppColors.travelColor;
    }
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Validate file size and type for images
  static bool isValidImageFile(String fileName, int fileSize) {
    // Check file size (max 5MB)
    if (fileSize > AppConstants.maxImageSize) {
      return false;
    }

    // Check file extension
    final extension = fileName
        .split('.')
        .last
        .toLowerCase();
    return AppConstants.allowedImageTypes.contains(extension);
  }

  /// Extract file extension
  static String getFileExtension(String fileName) {
    return fileName
        .split('.')
        .last
        .toLowerCase();
  }

  /// Generate avatar color based on string
  static Color generateAvatarColor(String text) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.carsColor,
      AppColors.footballColor,
      AppColors.travelColor,
      AppColors.anagramColor,
      AppColors.translationBlitzColor,
      AppColors.wordBlitzColor,
      AppColors.readingColor,
    ];

    final hash = text.hashCode;
    return colors[hash.abs() % colors.length];
  }

  /// Format large numbers (e.g., 1K, 1.2M)
  static String formatLargeNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      final k = number / 1000;
      return k == k.toInt() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = number / 1000000;
      return m == m.toInt() ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }

  /// Parse JSON safely
  static Map<String, dynamic>? parseJson(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON string safely
  static String? toJsonString(Map<String, dynamic> data) {
    try {
      return json.encode(data);
    } catch (e) {
      return null;
    }
  }

  /// Debounce function calls
  static void debounce(String key, VoidCallback callback,
      {Duration delay = const Duration(milliseconds: 300)}) {
    if (_debounceTimers.containsKey(key)) {
      _debounceTimers[key]?.cancel();
    }

    _debounceTimers[key] = async_timer.Timer(delay, callback);
  }

  static final Map<String, async_timer.Timer> _debounceTimers = {};

  /// Throttle function calls
  static void throttle(String key, VoidCallback callback,
      {Duration duration = const Duration(milliseconds: 300)}) {
    if (_throttleTimestamps.containsKey(key)) {
      final lastCall = _throttleTimestamps[key]!;
      if (DateTime.now().difference(lastCall) < duration) {
        return;
      }
    }

    _throttleTimestamps[key] = DateTime.now();
    callback();
  }

  static final Map<String, DateTime> _throttleTimestamps = {};

  /// Show success snackbar
  static void showSuccessSnackbar(String message, {String title = 'Success'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar(String message, {String title = 'Error'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Show warning snackbar
  static void showWarningSnackbar(String message, {String title = 'Warning'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.warning,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Show info snackbar
  static void showInfoSnackbar(String message, {String title = 'Info'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.info,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Show loading dialog
  static void showLoadingDialog({String message = 'Loading...'}) {
    Get.dialog(
      AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? AppColors.error,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Focus next field
  static void focusNextField(FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(Get.context!).requestFocus(nextFocus);
  }

  /// Unfocus all fields
  static void unfocusAll() {
    FocusScope.of(Get.context!).unfocus();
  }

  /// Haptic feedback
  static void hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Check if string is URL
  static bool isUrl(String text) {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );
    return urlRegex.hasMatch(text);
  }

  /// Check if string is email
  static bool isEmail(String text) {
    return AppRegex.email.hasMatch(text);
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackbar('Copied to clipboard');
  }

  /// Log user action for analytics
  static void logUserAction(String action, [Map<String, dynamic>? parameters]) {
    // Implement analytics logging here
    debugPrint(
        'User Action: $action ${parameters != null ? '- $parameters' : ''}');
  }

  /// Safe area top padding
  static double get safeAreaTop => Get.mediaQuery.padding.top;

  /// Safe area bottom padding
  static double get safeAreaBottom => Get.mediaQuery.padding.bottom;

  /// Screen width
  static double get screenWidth => Get.width;

  /// Screen height
  static double get screenHeight => Get.height;

  /// Is tablet
  static bool get isTablet => Get.width > 600;

  /// Is phone
  static bool get isPhone => Get.width <= 600;

  /// Check if dark mode
  static bool get isDarkMode => Get.isDarkMode;

  /// Get platform
  static String get platform => GetPlatform.isIOS ? 'iOS' : 'Android';
}

/// Extensions for convenience
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is empty or null
  bool get isNullOrEmpty => isEmpty;

  /// Remove all whitespace
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Check if string contains only digits
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Check if string is a valid email
  bool get isValidEmail => AppRegex.email.hasMatch(this);

  /// Check if string is a valid English word
  bool get isValidEnglishWord => AppRegex.englishWord.hasMatch(this);
}

extension ListExtensions<T> on List<T> {
  /// Get random element
  T get random => this[Random().nextInt(length)];

  /// Shuffle list in place
  void shuffleInPlace() => shuffle();

  /// Get list without null values
  List<T> get withoutNulls => where((item) => item != null).toList();
}

extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month &&
        day == yesterday.day;
  }

  /// Format as relative time
  String get relativeTime => AppHelpers.formatRelativeTime(this);
}