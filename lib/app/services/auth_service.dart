import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/api_response_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends GetxService {
  late ApiService _apiService;
  late StorageService _storageService;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
  }

  /// Sign in with Apple
  Future<ApiResponse<AuthResponse>> signInWithApple({String? nickname}) async {
    try {
      // Check if Sign in with Apple is available
      if (!await SignInWithApple.isAvailable()) {
        return ApiResponse.error(
          error: 'Sign in with Apple is not available on this device',
        );
      }

      // Request Apple credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Validate required fields
      if (credential.identityToken == null) {
        return ApiResponse.error(
          error: 'Failed to get identity token from Apple',
        );
      }

      // Extract nickname from Apple response if not provided
      String? finalNickname = nickname;
      if (finalNickname == null && credential.givenName != null) {
        final givenName = credential.givenName ?? '';
        final familyName = credential.familyName ?? '';
        finalNickname = '$givenName $familyName'.trim();
        if (finalNickname.isEmpty) {
          finalNickname = null;
        }
      }

      // Create request
      final request = AppleSignInRequest(
        identityToken: credential.identityToken!,
        userIdentifier: credential.userIdentifier ?? 'unknown_user',
        nickname: finalNickname,
      );

      // Send to backend
      final response = await _apiService.post<AuthResponse>(
        ApiEndpoints.appleSignIn,
        data: request.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Store token and user data
        await _storeAuthData(response.data!);

        // Set API token
        _apiService.setAuthToken(response.data!.accessToken);

        AppHelpers.logUserAction('apple_sign_in_success', {
          'user_id': response.data!.user.id,
          'email': response.data!.user.email,
        });
      }

      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      String errorMessage;
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          errorMessage = 'Sign in was cancelled';
          break;
        case AuthorizationErrorCode.failed:
          errorMessage = 'Sign in failed';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'Invalid response from Apple';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage = 'Sign in not handled';
          break;
        case AuthorizationErrorCode.unknown:
        default:
          errorMessage = 'Unknown error occurred during sign in';
          break;
      }

      AppHelpers.logUserAction('apple_sign_in_error', {
        'error_code': e.code.toString(),
        'error_message': errorMessage,
      });

      return ApiResponse.error(error: errorMessage);
    } catch (e) {
      AppHelpers.logUserAction('apple_sign_in_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Test login for development
  Future<ApiResponse<AuthResponse>> testLogin({
    required String email,
    String nickname = 'Test User',
  }) async {
    try {
      // Only allow in debug mode
      if (!AppConstants.baseUrl.contains('localhost') &&
          !AppConstants.baseUrl.contains('railway.app')) {
        return ApiResponse.error(
          error: 'Test login is only available in development mode',
        );
      }

      final request = TestLoginRequest(
        email: email,
        nickname: nickname,
      );

      final response = await _apiService.post<AuthResponse>(
        ApiEndpoints.testLogin,
        data: request.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Store token and user data
        await _storeAuthData(response.data!);

        // Set API token
        _apiService.setAuthToken(response.data!.accessToken);

        AppHelpers.logUserAction('test_login_success', {
          'user_id': response.data!.user.id,
          'email': response.data!.user.email,
        });
      }

      return response;
    } catch (e) {
      AppHelpers.logUserAction('test_login_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Test login failed: ${e.toString()}',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Clear API token
      _apiService.clearAuthToken();

      // Clear stored data
      _storageService.logout();

      // Log action
      AppHelpers.logUserAction('logout');

      // Navigate to login
      Get.offAllNamed(AppRoutes.login);

      AppHelpers.showSuccessSnackbar('Logged out successfully');
    } catch (e) {
      AppHelpers.logUserAction('logout_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar('Error during logout');
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    return _storageService.isLoggedIn() && _apiService.hasAuthToken;
  }

  /// Get current user
  User? get currentUser {
    final userData = _storageService.getUserData();
    if (userData != null) {
      try {
        return User.fromJson(userData);
      } catch (e) {
        // Invalid user data, clear it
        _storageService.removeUserData();
        return null;
      }
    }
    return null;
  }

  /// Get current token
  String? get currentToken {
    return _storageService.getToken();
  }

  /// Refresh user data from server
  Future<ApiResponse<User>> refreshUserData() async {
    try {
      final response = await _apiService.get<UserProfileResponse>(
        ApiEndpoints.userProfile,
        fromJson: (json) => UserProfileResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        final user = response.data!.user;

        // Update stored user data
        _storageService.setUserData(user.toJson());

        AppHelpers.logUserAction('user_data_refreshed', {
          'user_id': user.id,
        });

        return ApiResponse.success(data: user);
      }

      return ApiResponse.error(
        error: response.error ?? 'Failed to refresh user data',
      );
    } catch (e) {
      AppHelpers.logUserAction('refresh_user_data_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to refresh user data: ${e.toString()}',
      );
    }
  }

  /// Validate current session
  Future<bool> validateSession() async {
    try {
      if (!isLoggedIn) {
        return false;
      }

      // Try to fetch user profile to validate token
      final response = await _apiService.get<UserProfileResponse>(
        ApiEndpoints.userProfile,
        fromJson: (json) => UserProfileResponse.fromJson(json),
      );

      if (response.success) {
        // Update user data if successful
        if (response.data != null) {
          _storageService.setUserData(response.data!.user.toJson());
        }
        return true;
      } else {
        // Session invalid, logout
        if (response.statusCode == 401) {
          await logout();
        }
        return false;
      }
    } catch (e) {
      AppHelpers.logUserAction('validate_session_error', {
        'error': e.toString(),
      });

      return false;
    }
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile(String nickname) async {
    try {
      final request = UpdateProfileRequest(nickname: nickname);

      final response = await _apiService.put<UserUpdateResponse>(
        ApiEndpoints.updateProfile,
        data: request.toJson(),
        fromJson: (json) => UserUpdateResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        final updatedUser = response.data!.user;

        // Update stored user data
        _storageService.setUserData(updatedUser.toJson());

        AppHelpers.logUserAction('profile_updated', {
          'user_id': updatedUser.id,
          'new_nickname': nickname,
        });

        return ApiResponse.success(data: updatedUser);
      }

      return ApiResponse.error(
        error: response.error ?? 'Failed to update profile',
      );
    } catch (e) {
      AppHelpers.logUserAction('update_profile_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Store authentication data
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    try {
      // Store token
      _storageService.setToken(authResponse.accessToken);

      // Store user data
      _storageService.setUserData(authResponse.user.toJson());

      AppHelpers.logUserAction('auth_data_stored', {
        'user_id': authResponse.user.id,
      });
    } catch (e) {
      AppHelpers.logUserAction('store_auth_data_error', {
        'error': e.toString(),
      });

      throw Exception('Failed to store authentication data: ${e.toString()}');
    }
  }

  /// Initialize auth service (check existing session)
  Future<void> initializeAuth() async {
    try {
      if (isLoggedIn) {
        // Set API token from storage
        final token = _storageService.getToken();
        if (token != null) {
          _apiService.setAuthToken(token);
        }

        // Validate session in background
        validateSession();

        AppHelpers.logUserAction('auth_initialized', {
          'has_token': token != null,
          'has_user_data': _storageService.hasUserData(),
        });
      }
    } catch (e) {
      AppHelpers.logUserAction('auth_init_error', {
        'error': e.toString(),
      });

      // Clear invalid data
      _storageService.logout();
      _apiService.clearAuthToken();
    }
  }

  /// Handle authentication errors
  void handleAuthError(ApiResponse response) {
    if (response.statusCode == 401) {
      // Token expired or invalid
      logout();
      AppHelpers.showErrorSnackbar(
        'Your session has expired. Please login again.',
        title: 'Session Expired',
      );
    } else if (response.statusCode == 403) {
      // Forbidden
      AppHelpers.showErrorSnackbar(
        'You do not have permission to perform this action.',
        title: 'Access Denied',
      );
    } else {
      // Generic error
      AppHelpers.showErrorSnackbar(
        response.error ?? 'Authentication error occurred',
        title: 'Authentication Error',
      );
    }
  }

  /// Check if Apple Sign In is available
  Future<bool> isAppleSignInAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      AppHelpers.logUserAction('apple_signin_availability_error', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Get user statistics
  Future<ApiResponse<UserStats>> getUserStats() async {
    try {
      final response = await _apiService.get<UserProfileResponse>(
        ApiEndpoints.userProfile,
        fromJson: (json) => UserProfileResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!.stats);
      }

      return ApiResponse.error(
        error: response.error ?? 'Failed to get user statistics',
      );
    } catch (e) {
      AppHelpers.logUserAction('get_user_stats_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to get user statistics: ${e.toString()}',
      );
    }
  }

  /// Delete account (for future implementation)
  Future<ApiResponse<bool>> deleteAccount() async {
    try {
      // This would typically call a delete account endpoint
      // For now, just logout
      await logout();

      AppHelpers.logUserAction('account_deleted');

      return ApiResponse.success(data: true);
    } catch (e) {
      AppHelpers.logUserAction('delete_account_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  /// Export user data (for GDPR compliance)
  Future<ApiResponse<Map<String, dynamic>>> exportUserData() async {
    try {
      // This would typically call an export endpoint
      final userData = _storageService.getUserData();

      if (userData != null) {
        AppHelpers.logUserAction('user_data_exported');
        return ApiResponse.success(data: userData);
      }

      return ApiResponse.error(error: 'No user data found');
    } catch (e) {
      AppHelpers.logUserAction('export_user_data_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to export user data: ${e.toString()}',
      );
    }
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

/// Authentication result
class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final String? token;

  AuthResult({
    required this.success,
    this.error,
    this.user,
    this.token,
  });

  factory AuthResult.success({required User user, required String token}) {
    return AuthResult(
      success: true,
      user: user,
      token: token,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'AuthResult{success: $success, error: $error, user: $user, token: ${token?.substring(0, 10)}...}';
  }
}