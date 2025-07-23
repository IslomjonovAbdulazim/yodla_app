import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/api_response_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart' hide AppRoutes;
import '../utils/helpers.dart';
import '../utils/validators.dart';

class AuthController extends GetxController with FormValidationMixin {
  late AuthService _authService;
  late StorageService _storageService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isAppleSignInAvailable = false.obs;
  final Rx<AuthStatus> _authStatus = AuthStatus.unknown.obs;
  final Rx<User?> _currentUser = Rx<User?>(null);

  // Form controllers for test login
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();

  // Form validation
  final RxMap<String, String?> _validationErrors = <String, String?>{}.obs;

  // Getters
  bool get isLoading => _isLoading.value;

  bool get isAppleSignInAvailable => _isAppleSignInAvailable.value;

  AuthStatus get authStatus => _authStatus.value;

  User? get currentUser => _currentUser.value;

  Map<String, String?> get validationErrors => _validationErrors;

  bool get isAuthenticated => _authStatus.value == AuthStatus.authenticated;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _storageService = Get.find<StorageService>();
    _initializeAuth();
  }

  @override
  void onClose() {
    emailController.dispose();
    nicknameController.dispose();
    super.onClose();
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      _authStatus.value = AuthStatus.loading;

      // Check Apple Sign In availability
      _isAppleSignInAvailable.value = await _authService
          .isAppleSignInAvailable();

      // Initialize auth service
      await _authService.initializeAuth();

      // Check if user is already logged in
      if (_authService.isLoggedIn) {
        _currentUser.value = _authService.currentUser;
        _authStatus.value = AuthStatus.authenticated;

        // Navigate to home if already on login screen
        if (Get.currentRoute == AppRoutes.login || Get.currentRoute == '/') {
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        _authStatus.value = AuthStatus.unauthenticated;
      }

      AppHelpers.logUserAction('auth_initialized', {
        'status': _authStatus.value.toString(),
        'has_current_user': _currentUser.value != null,
        'apple_signin_available': _isAppleSignInAvailable.value,
      });
    } catch (e) {
      _authStatus.value = AuthStatus.error;

      AppHelpers.logUserAction('auth_init_error', {'error': e.toString()});

      AppHelpers.showErrorSnackbar(
        'Failed to initialize authentication',
        title: 'Initialization Error',
      );
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple({String? nickname}) async {
    try {
      if (_isLoading.value) return;

      _isLoading.value = true;
      _clearValidationErrors();

      AppHelpers.logUserAction('apple_signin_attempt', {
        'has_nickname': nickname != null,
      });

      final response = await _authService.signInWithApple(nickname: nickname);

      if (response.success && response.data != null) {
        _currentUser.value = response.data!.user;
        _authStatus.value = AuthStatus.authenticated;

        AppHelpers.logUserAction('apple_signin_success', {
          'user_id': response.data!.user.id,
          'user_email': response.data!.user.email,
        });

        // Navigate to home
        Get.offAllNamed(AppRoutes.home);

        AppHelpers.showSuccessSnackbar(
          'Welcome, ${response.data!.user.nickname}!',
          title: 'Sign In Successful',
        );
      } else {
        _authStatus.value = AuthStatus.unauthenticated;

        AppHelpers.logUserAction('apple_signin_failed', {
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Apple Sign In failed',
          title: 'Sign In Failed',
        );
      }
    } catch (e) {
      _authStatus.value = AuthStatus.error;

      AppHelpers.logUserAction('apple_signin_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred during sign in',
        title: 'Sign In Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Test login for development
  Future<void> testLogin() async {
    try {
      if (_isLoading.value) return;

      // Validate form
      if (!_validateTestLoginForm()) {
        return;
      }

      _isLoading.value = true;
      _clearValidationErrors();

      final email = emailController.text.trim();
      final nickname = nicknameController.text.trim();

      AppHelpers.logUserAction('test_login_attempt', {
        'email': email,
        'nickname': nickname,
      });

      final response = await _authService.testLogin(
        email: email,
        nickname: nickname,
      );

      if (response.success && response.data != null) {
        _currentUser.value = response.data!.user;
        _authStatus.value = AuthStatus.authenticated;

        AppHelpers.logUserAction('test_login_success', {
          'user_id': response.data!.user.id,
          'user_email': response.data!.user.email,
        });

        // Navigate to home
        Get.offAllNamed(AppRoutes.home);

        AppHelpers.showSuccessSnackbar(
          'Welcome, ${response.data!.user.nickname}!',
          title: 'Test Login Successful',
        );
      } else {
        _authStatus.value = AuthStatus.unauthenticated;

        AppHelpers.logUserAction('test_login_failed', {
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Test login failed',
          title: 'Login Failed',
        );
      }
    } catch (e) {
      _authStatus.value = AuthStatus.error;

      AppHelpers.logUserAction('test_login_exception', {'error': e.toString()});

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred during test login',
        title: 'Login Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      if (_isLoading.value) return;

      _isLoading.value = true;

      AppHelpers.logUserAction('logout_attempt', {
        'user_id': _currentUser.value?.id,
      });

      await _authService.logout();

      _currentUser.value = null;
      _authStatus.value = AuthStatus.unauthenticated;

      // Clear form
      _clearForm();

      AppHelpers.logUserAction('logout_success');
    } catch (e) {
      AppHelpers.logUserAction('logout_exception', {'error': e.toString()});

      AppHelpers.showErrorSnackbar(
        'An error occurred during logout',
        title: 'Logout Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update user profile
  Future<void> updateProfile(String nickname) async {
    try {
      if (_isLoading.value) return;

      // Validate nickname
      final error = Validators.nickname(nickname);
      if (error != null) {
        AppHelpers.showErrorSnackbar(error, title: 'Validation Error');
        return;
      }

      _isLoading.value = true;

      AppHelpers.logUserAction('update_profile_attempt', {
        'user_id': _currentUser.value?.id,
        'new_nickname': nickname,
      });

      final response = await _authService.updateProfile(nickname);

      if (response.success && response.data != null) {
        _currentUser.value = response.data!;

        AppHelpers.logUserAction('update_profile_success', {
          'user_id': response.data!.id,
          'new_nickname': nickname,
        });

        AppHelpers.showSuccessSnackbar(
          'Profile updated successfully',
          title: 'Profile Updated',
        );
      } else {
        AppHelpers.logUserAction('update_profile_failed', {
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to update profile',
          title: 'Update Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('update_profile_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while updating profile',
        title: 'Update Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    try {
      AppHelpers.logUserAction('refresh_user_data_attempt', {
        'user_id': _currentUser.value?.id,
      });

      final response = await _authService.refreshUserData();

      if (response.success && response.data != null) {
        _currentUser.value = response.data!;

        AppHelpers.logUserAction('refresh_user_data_success', {
          'user_id': response.data!.id,
        });
      } else {
        AppHelpers.logUserAction('refresh_user_data_failed', {
          'error': response.error,
        });

        // Handle auth errors
        if (response.statusCode == 401) {
          await logout();
        }
      }
    } catch (e) {
      AppHelpers.logUserAction('refresh_user_data_exception', {
        'error': e.toString(),
      });
    }
  }

  /// Validate session
  Future<bool> validateSession() async {
    try {
      AppHelpers.logUserAction('validate_session_attempt');

      final isValid = await _authService.validateSession();

      if (!isValid) {
        _currentUser.value = null;
        _authStatus.value = AuthStatus.unauthenticated;
      }

      AppHelpers.logUserAction('validate_session_result', {
        'is_valid': isValid,
      });

      return isValid;
    } catch (e) {
      AppHelpers.logUserAction('validate_session_exception', {
        'error': e.toString(),
      });

      return false;
    }
  }

  /// Validate test login form
  bool _validateTestLoginForm() {
    final errors = validateFields(
      {'email': CommonValidators.email, 'nickname': CommonValidators.nickname},
      {'email': emailController.text, 'nickname': nicknameController.text},
    );

    _validationErrors.assignAll(errors);

    if (hasErrors(errors)) {
      final firstError = getFirstError(errors);
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

  /// Clear form
  void _clearForm() {
    emailController.clear();
    nicknameController.clear();
    _clearValidationErrors();
  }

  /// Get validation error for field
  String? getFieldError(String fieldName) {
    return _validationErrors[fieldName];
  }

  /// Check if field has error
  bool hasFieldError(String fieldName) {
    return _validationErrors[fieldName] != null;
  }

  /// Handle authentication required
  void handleAuthRequired() {
    if (!isAuthenticated) {
      AppHelpers.showWarningSnackbar(
        'Please sign in to continue',
        title: 'Authentication Required',
      );

      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Handle API errors
  void handleApiError(ApiResponse response) {
    _authService.handleAuthError(response);
  }

  /// Show confirmation dialog before logout
  Future<void> showLogoutConfirmation() async {
    final confirmed = await AppHelpers.showConfirmationDialog(
      title: 'Confirm Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
    );

    if (confirmed) {
      await logout();
    }
  }

  /// Auto-fill test login (for development)
  void autoFillTestLogin() {
    emailController.text = 'test@example.com';
    nicknameController.text = 'Test User';
    _clearValidationErrors();
  }

  /// Check if running in debug mode
  bool get isDebugMode {
    return AppConstants.baseUrl.contains('localhost') ||
        AppConstants.baseUrl.contains('railway.app');
  }

  /// Get user initials
  String get userInitials {
    if (_currentUser.value?.nickname != null) {
      return AppHelpers.getInitials(_currentUser.value!.nickname);
    }
    return 'U';
  }

  /// Get user display name
  String get userDisplayName {
    return _currentUser.value?.nickname ?? 'User';
  }

  /// Get user email
  String get userEmail {
    return _currentUser.value?.email ?? '';
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    final user = _currentUser.value;
    return user != null && user.nickname.isNotEmpty && user.email.isNotEmpty;
  }

  /// Get account creation date
  String get accountCreatedDate {
    if (_currentUser.value?.createdAt != null) {
      return AppHelpers.formatDate(_currentUser.value!.createdAt);
    }
    return '';
  }

  /// Force logout (for testing)
  Future<void> forceLogout() async {
    try {
      await _authService.logout();
      _currentUser.value = null;
      _authStatus.value = AuthStatus.unauthenticated;
      _clearForm();

      AppHelpers.logUserAction('force_logout');

      AppHelpers.showInfoSnackbar('Logged out successfully');
    } catch (e) {
      AppHelpers.logUserAction('force_logout_error', {'error': e.toString()});
    }
  }

  /// Reset authentication state
  void resetAuthState() {
    _currentUser.value = null;
    _authStatus.value = AuthStatus.unknown;
    _clearForm();
    _clearValidationErrors();

    AppHelpers.logUserAction('auth_state_reset');
  }
}
