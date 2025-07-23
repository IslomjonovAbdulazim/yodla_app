import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/api_response_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';

class UserController extends GetxController {
  late AuthService _authService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isUpdatingProfile = false.obs;
  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserStats?> _userStats = Rx<UserStats?>(null);

  // Form controllers
  final TextEditingController nicknameController = TextEditingController();

  // Form validation
  final RxMap<String, String?> _validationErrors = <String, String?>{}.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isUpdatingProfile => _isUpdatingProfile.value;
  User? get user => _user.value;
  UserStats? get userStats => _userStats.value;
  Map<String, String?> get validationErrors => _validationErrors;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _initializeUser();
  }

  @override
  void onClose() {
    nicknameController.dispose();
    super.onClose();
  }

  /// Initialize user data
  void _initializeUser() {
    // Get current user from auth service
    _user.value = _authService.currentUser;

    if (_user.value != null) {
      nicknameController.text = _user.value!.nickname;
      _loadUserProfile();
    }

    AppHelpers.logUserAction('user_controller_initialized', {
      'has_user': _user.value != null,
      'user_id': _user.value?.id,
    });
  }

  /// Load user profile with statistics
  Future<void> _loadUserProfile() async {
    if (_user.value == null) return;

    try {
      _isLoading.value = true;

      AppHelpers.logUserAction('load_user_profile_attempt', {
        'user_id': _user.value!.id,
      });

      final stats = await _authService.getUserStats();

      if (stats.success && stats.data != null) {
        _userStats.value = stats.data!;

        AppHelpers.logUserAction('load_user_profile_success', {
          'user_id': _user.value!.id,
          'total_words': stats.data!.totalWords,
          'total_folders': stats.data!.totalFolders,
          'total_quizzes': stats.data!.totalQuizzes,
        });
      } else {
        AppHelpers.logUserAction('load_user_profile_failed', {
          'user_id': _user.value!.id,
          'error': stats.error,
        });

        if (stats.statusCode != 401) {
          AppHelpers.showErrorSnackbar(
            stats.error ?? 'Failed to load user profile',
            title: 'Profile Error',
          );
        }
      }
    } catch (e) {
      AppHelpers.logUserAction('load_user_profile_exception', {
        'user_id': _user.value?.id,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while loading profile',
        title: 'Profile Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    try {
      AppHelpers.logUserAction('refresh_profile_attempt', {
        'user_id': _user.value?.id,
      });

      // Refresh user data from auth service
      await _authService.refreshUserData();

      // Update local user data
      _user.value = _authService.currentUser;

      if (_user.value != null) {
        nicknameController.text = _user.value!.nickname;
      }

      // Reload profile with stats
      await _loadUserProfile();

      AppHelpers.logUserAction('refresh_profile_success', {
        'user_id': _user.value?.id,
      });

      AppHelpers.showSuccessSnackbar(
        'Profile refreshed successfully',
        title: 'Profile Updated',
      );
    } catch (e) {
      AppHelpers.logUserAction('refresh_profile_exception', {
        'user_id': _user.value?.id,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to refresh profile',
        title: 'Refresh Error',
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile() async {
    try {
      if (_isUpdatingProfile.value) return;

      // Validate form
      if (!_validateProfileForm()) {
        return;
      }

      _isUpdatingProfile.value = true;
      _clearValidationErrors();

      final newNickname = nicknameController.text.trim();

      AppHelpers.logUserAction('update_profile_attempt', {
        'user_id': _user.value?.id,
        'new_nickname': newNickname,
        'old_nickname': _user.value?.nickname,
      });

      final response = await _authService.updateProfile(newNickname);

      if (response.success && response.data != null) {
        _user.value = response.data!;

        AppHelpers.logUserAction('update_profile_success', {
          'user_id': response.data!.id,
          'new_nickname': newNickname,
        });

        AppHelpers.showSuccessSnackbar(
          'Profile updated successfully',
          title: 'Profile Updated',
        );

        // Go back to previous screen
        Get.back();
      } else {
        AppHelpers.logUserAction('update_profile_failed', {
          'user_id': _user.value?.id,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to update profile',
          title: 'Update Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('update_profile_exception', {
        'user_id': _user.value?.id,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while updating profile',
        title: 'Update Error',
      );
    } finally {
      _isUpdatingProfile.value = false;
    }
  }

  /// Validate profile form
  bool _validateProfileForm() {
    final errors = <String, String?>{};

    // Validate nickname
    final nicknameError = Validators.nickname(nicknameController.text);
    if (nicknameError != null) {
      errors['nickname'] = nicknameError;
    }

    _validationErrors.assignAll(errors);

    if (errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError != null) {
        AppHelpers.showErrorSnackbar(firstError, title: 'Validation Error');
      }
      return false;
    }

    return true;
  }

  /// Clear validation errors
  void _clearValidationErrors() {
    _validationErrors.clear();
  }

  /// Get validation error for field
  String? getFieldError(String fieldName) {
    return _validationErrors[fieldName];
  }

  /// Check if field has error
  bool hasFieldError(String fieldName) {
    return _validationErrors[fieldName] != null;
  }

  /// Reset nickname to original value
  void resetNickname() {
    if (_user.value != null) {
      nicknameController.text = _user.value!.nickname;
      _clearValidationErrors();
    }
  }

  /// Get user initials
  String get userInitials {
    if (_user.value?.nickname != null) {
      return AppHelpers.getInitials(_user.value!.nickname);
    }
    return 'U';
  }

  /// Get user display name
  String get userDisplayName {
    return _user.value?.nickname ?? 'User';
  }

  /// Get user email
  String get userEmail {
    return _user.value?.email ?? '';
  }

  /// Get account creation date
  String get accountCreatedDate {
    if (_user.value?.createdAt != null) {
      return AppHelpers.formatDate(_user.value!.createdAt);
    }
    return '';
  }

  /// Get formatted account creation date
  String get formattedCreationDate {
    if (_user.value?.createdAt != null) {
      return AppHelpers.formatRelativeTime(_user.value!.createdAt);
    }
    return '';
  }

  /// Check if nickname has been changed
  bool get hasNicknameChanged {
    if (_user.value == null) return false;
    return nicknameController.text.trim() != _user.value!.nickname;
  }

  /// Get user statistics summary
  Map<String, dynamic> get statisticsSummary {
    if (_userStats.value == null) {
      return {
        'total_folders': 0,
        'total_words': 0,
        'total_quizzes': 0,
        'words_by_category': {
          'not_known': 0,
          'normal': 0,
          'strong': 0,
        },
      };
    }

    return {
      'total_folders': _userStats.value!.totalFolders,
      'total_words': _userStats.value!.totalWords,
      'total_quizzes': _userStats.value!.totalQuizzes,
      'words_by_category': {
        'not_known': _userStats.value!.wordsByCategory.notKnown,
        'normal': _userStats.value!.wordsByCategory.normal,
        'strong': _userStats.value!.wordsByCategory.strong,
      },
    };
  }

  /// Get learning progress percentage
  double get learningProgress {
    if (_userStats.value == null) return 0.0;

    final stats = _userStats.value!.wordsByCategory;
    final total = stats.total;

    if (total == 0) return 0.0;

    // Progress based on normal + strong words
    final learned = stats.normal + stats.strong;
    return (learned / total) * 100;
  }

  /// Get mastery percentage (strong words only)
  double get masteryPercentage {
    if (_userStats.value == null) return 0.0;

    final stats = _userStats.value!.wordsByCategory;
    final total = stats.total;

    if (total == 0) return 0.0;

    return (stats.strong / total) * 100;
  }

  /// Get vocabulary level based on total words
  String get vocabularyLevel {
    final totalWords = _userStats.value?.totalWords ?? 0;

    if (totalWords >= 1000) {
      return 'Expert';
    } else if (totalWords >= 500) {
      return 'Advanced';
    } else if (totalWords >= 200) {
      return 'Intermediate';
    } else if (totalWords >= 50) {
      return 'Beginner';
    } else {
      return 'Starter';
    }
  }

  /// Get learning streak (placeholder - would need backend support)
  int get learningStreak {
    // This would typically come from backend tracking daily quiz activity
    return 0;
  }

  /// Get achievement badges (placeholder)
  List<String> get achievements {
    final achievements = <String>[];
    final stats = _userStats.value;

    if (stats != null) {
      // Word count achievements
      if (stats.totalWords >= 100) achievements.add('Century Scholar');
      if (stats.totalWords >= 500) achievements.add('Vocabulary Master');
      if (stats.totalWords >= 1000) achievements.add('Word Wizard');

      // Quiz achievements
      if (stats.totalQuizzes >= 10) achievements.add('Quiz Enthusiast');
      if (stats.totalQuizzes >= 50) achievements.add('Quiz Master');
      if (stats.totalQuizzes >= 100) achievements.add('Quiz Legend');

      // Mastery achievements
      if (masteryPercentage >= 50) achievements.add('Half Master');
      if (masteryPercentage >= 80) achievements.add('Almost Perfect');
      if (masteryPercentage >= 95) achievements.add('Perfectionist');

      // Folder organization
      if (stats.totalFolders >= 5) achievements.add('Organizer');
      if (stats.totalFolders >= 10) achievements.add('Super Organizer');
    }

    return achievements;
  }

  /// Export user data
  Future<void> exportUserData() async {
    try {
      AppHelpers.logUserAction('export_user_data_attempt', {
        'user_id': _user.value?.id,
      });

      final response = await _authService.exportUserData();

      if (response.success && response.data != null) {
        // Convert to formatted string
        final userData = response.data!;
        final exportText = _formatExportData(userData);

        await AppHelpers.copyToClipboard(exportText);

        AppHelpers.logUserAction('export_user_data_success', {
          'user_id': _user.value?.id,
        });

        AppHelpers.showSuccessSnackbar(
          'User data copied to clipboard',
          title: 'Export Complete',
        );
      } else {
        AppHelpers.logUserAction('export_user_data_failed', {
          'user_id': _user.value?.id,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to export user data',
          title: 'Export Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('export_user_data_exception', {
        'user_id': _user.value?.id,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while exporting data',
        title: 'Export Error',
      );
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      // Show confirmation dialog
      final confirmed = await AppHelpers.showConfirmationDialog(
        title: 'Delete Account',
        message: 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        confirmText: 'Delete Account',
        cancelText: 'Cancel',
        confirmColor: Colors.red,
      );

      if (!confirmed) return;

      AppHelpers.showLoadingDialog(message: 'Deleting account...');

      AppHelpers.logUserAction('delete_account_attempt', {
        'user_id': _user.value?.id,
      });

      final response = await _authService.deleteAccount();

      AppHelpers.hideLoadingDialog();

      if (response.success) {
        AppHelpers.logUserAction('delete_account_success', {
          'user_id': _user.value?.id,
        });

        AppHelpers.showSuccessSnackbar(
          'Account deleted successfully',
          title: 'Account Deleted',
        );

        // Reset user data
        _user.value = null;
        _userStats.value = null;
        nicknameController.clear();
        _clearValidationErrors();
      } else {
        AppHelpers.logUserAction('delete_account_failed', {
          'user_id': _user.value?.id,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to delete account',
          title: 'Delete Failed',
        );
      }
    } catch (e) {
      AppHelpers.hideLoadingDialog();

      AppHelpers.logUserAction('delete_account_exception', {
        'user_id': _user.value?.id,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while deleting account',
        title: 'Delete Error',
      );
    }
  }

  /// Format export data
  String _formatExportData(Map<String, dynamic> userData) {
    final buffer = StringBuffer();

    buffer.writeln('=== User Data Export ===');
    buffer.writeln('Export Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    buffer.writeln('User Information:');
    buffer.writeln('- ID: ${userData['id']}');
    buffer.writeln('- Email: ${userData['email']}');
    buffer.writeln('- Nickname: ${userData['nickname']}');
    buffer.writeln('- Created: ${userData['created_at']}');
    buffer.writeln('');

    if (_userStats.value != null) {
      final stats = _userStats.value!;
      buffer.writeln('Statistics:');
      buffer.writeln('- Total Folders: ${stats.totalFolders}');
      buffer.writeln('- Total Words: ${stats.totalWords}');
      buffer.writeln('- Total Quizzes: ${stats.totalQuizzes}');
      buffer.writeln('- Words Not Known: ${stats.wordsByCategory.notKnown}');
      buffer.writeln('- Words Normal: ${stats.wordsByCategory.normal}');
      buffer.writeln('- Words Strong: ${stats.wordsByCategory.strong}');
      buffer.writeln('- Learning Progress: ${learningProgress.toStringAsFixed(1)}%');
      buffer.writeln('- Mastery: ${masteryPercentage.toStringAsFixed(1)}%');
      buffer.writeln('- Vocabulary Level: $vocabularyLevel');
      buffer.writeln('');
    }

    buffer.writeln('Achievements:');
    for (final achievement in achievements) {
      buffer.writeln('- $achievement');
    }

    return buffer.toString();
  }

  /// Show profile completion dialog
  void showProfileCompletionDialog() {
    if (_user.value == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Complete Your Profile'),
        content: const Text(
          'Complete your profile to get the most out of the app. Add a nickname and start building your vocabulary!',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.toNamed(AppRoutes.profile);
            },
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );
  }

  /// Check if profile needs completion
  bool get needsProfileCompletion {
    return _user.value != null &&
        (_user.value!.nickname.isEmpty || _user.value!.nickname == 'User');
  }

  /// Get user color for avatar
  Color get userAvatarColor {
    if (_user.value?.email != null) {
      return AppHelpers.generateAvatarColor(_user.value!.email);
    }
    return AppColors.primary;
  }
}