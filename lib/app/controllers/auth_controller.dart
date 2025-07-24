import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';

class AuthController extends GetxController {
  late AuthService _authService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isAppleSignInAvailable = false.obs;
  final Rx<AuthStatus> _authStatus = AuthStatus.unknown.obs;
  final Rx<User?> _currentUser = Rx<User?>(null);

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isAppleSignInAvailable => _isAppleSignInAvailable.value;
  AuthStatus get authStatus => _authStatus.value;
  User? get currentUser => _currentUser.value;
  bool get isAuthenticated => _authStatus.value == AuthStatus.authenticated;

  // User display properties
  String get userDisplayName => _currentUser.value?.nickname ?? 'User';
  String get userEmail => _currentUser.value?.email ?? '';
  String get userInitials {
    if (_currentUser.value?.nickname != null) {
      return AppHelpers.getInitials(_currentUser.value!.nickname);
    }
    return 'U';
  }

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _initializeAuth();
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      AppHelpers.logUserAction('auth_initialization_started');
      _authStatus.value = AuthStatus.loading;

      // Check Apple Sign In availability
      _isAppleSignInAvailable.value = await _authService.isAppleSignInAvailable();
      AppHelpers.logUserAction('apple_signin_availability_checked', {
        'available': _isAppleSignInAvailable.value,
      });

      // Initialize auth service
      await _authService.initializeAuth();
      AppHelpers.logUserAction('auth_service_initialized');

      // Check if user is already logged in
      if (_authService.isLoggedIn) {
        _currentUser.value = _authService.currentUser;
        _authStatus.value = AuthStatus.authenticated;

        AppHelpers.logUserAction('existing_session_found', {
          'user_id': _currentUser.value?.id,
          'user_email': _currentUser.value?.email,
          'current_route': Get.currentRoute,
        });

        // Navigate to home if on login screen
        if (Get.currentRoute == AppRoutes.login || Get.currentRoute == '/') {
          AppHelpers.logUserAction('auto_navigating_to_home');
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        _authStatus.value = AuthStatus.unauthenticated;
        AppHelpers.logUserAction('no_existing_session');
      }

      AppHelpers.logUserAction('auth_initialization_completed', {
        'status': _authStatus.value.toString(),
        'has_user': _currentUser.value != null,
      });
    } catch (e) {
      _authStatus.value = AuthStatus.error;
      AppHelpers.logUserAction('auth_initialization_failed', {
        'error': e.toString(),
      });
      _showError('Failed to initialize authentication');
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    if (_isLoading.value) {
      AppHelpers.logUserAction('apple_signin_blocked_already_loading');
      return;
    }

    try {
      _isLoading.value = true;
      AppHelpers.logUserAction('apple_signin_started');

      final response = await _authService.signInWithApple();

      AppHelpers.logUserAction('apple_signin_response_received', {
        'success': response.success,
        'status_code': response.statusCode,
        'has_data': response.data != null,
        'error': response.error,
      });

      if (response.success && response.data != null) {
        _currentUser.value = response.data!.user;
        _authStatus.value = AuthStatus.authenticated;

        AppHelpers.logUserAction('apple_signin_success', {
          'user_id': response.data!.user.id,
          'user_email': response.data!.user.email,
          'user_nickname': response.data!.user.nickname,
        });

        AppHelpers.logUserAction('navigating_to_home_after_signin');
        Get.offAllNamed(AppRoutes.home);

        AppHelpers.showSuccessSnackbar(
          'Welcome, ${response.data!.user.nickname}!',
          title: 'Sign In Successful',
        );
      } else {
        _authStatus.value = AuthStatus.unauthenticated;
        AppHelpers.logUserAction('apple_signin_failed', {
          'error_message': response.error,
          'status_code': response.statusCode,
        });
        _showError(response.error ?? 'Apple Sign In failed');
      }
    } catch (e) {
      _authStatus.value = AuthStatus.error;
      AppHelpers.logUserAction('apple_signin_exception', {
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      });
      _showError('An unexpected error occurred during sign in');
    } finally {
      _isLoading.value = false;
      AppHelpers.logUserAction('apple_signin_completed');
    }
  }

  /// Logout user
  Future<void> logout() async {
    if (_isLoading.value) {
      AppHelpers.logUserAction('logout_blocked_already_loading');
      return;
    }

    try {
      _isLoading.value = true;
      AppHelpers.logUserAction('logout_started', {
        'user_id': _currentUser.value?.id,
        'user_email': _currentUser.value?.email,
      });

      await _authService.logout();
      AppHelpers.logUserAction('auth_service_logout_completed');

      _currentUser.value = null;
      _authStatus.value = AuthStatus.unauthenticated;

      AppHelpers.logUserAction('logout_success');
    } catch (e) {
      AppHelpers.logUserAction('logout_exception', {
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      });
      _showError('An error occurred during logout');
    } finally {
      _isLoading.value = false;
      AppHelpers.logUserAction('logout_completed');
    }
  }

  /// Validate current session
  Future<bool> validateSession() async {
    try {
      AppHelpers.logUserAction('session_validation_started');

      final isValid = await _authService.validateSession();

      AppHelpers.logUserAction('session_validation_result', {
        'is_valid': isValid,
        'current_user_exists': _currentUser.value != null,
      });

      if (!isValid) {
        AppHelpers.logUserAction('invalid_session_detected_clearing_state');
        _currentUser.value = null;
        _authStatus.value = AuthStatus.unauthenticated;
      }

      return isValid;
    } catch (e) {
      AppHelpers.logUserAction('session_validation_exception', {
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      });
      return false;
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    try {
      AppHelpers.logUserAction('refresh_user_data_started', {
        'current_user_id': _currentUser.value?.id,
      });

      final response = await _authService.refreshUserData();

      AppHelpers.logUserAction('refresh_user_data_response', {
        'success': response.success,
        'status_code': response.statusCode,
        'has_data': response.data != null,
      });

      if (response.success && response.data != null) {
        _currentUser.value = response.data!;
        AppHelpers.logUserAction('user_data_refreshed_successfully', {
          'user_id': response.data!.id,
        });
      } else if (response.statusCode == 401) {
        // Session expired, logout
        AppHelpers.logUserAction('session_expired_during_refresh_logging_out');
        await logout();
      } else {
        AppHelpers.logUserAction('refresh_user_data_failed', {
          'error': response.error,
          'status_code': response.statusCode,
        });
      }
    } catch (e) {
      AppHelpers.logUserAction('refresh_user_data_exception', {
        'error': e.toString(),
        'error_type': e.runtimeType.toString(),
      });
    }
  }

  /// Handle authentication required scenarios
  void handleAuthRequired() {
    if (!isAuthenticated) {
      AppHelpers.showWarningSnackbar(
        'Please sign in to continue',
        title: 'Authentication Required',
      );
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Show logout confirmation dialog
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

  /// Show error message
  void _showError(String message) {
    AppHelpers.showErrorSnackbar(
      message,
      title: 'Authentication Error',
    );
  }
}

/// Authentication status enum
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  error,
}