import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:yodla_app/app/routes/app_routes.dart';

import '../models/api_response_model.dart';
import '../models/user_model.dart';
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

  /// Sign in with Apple - Direct backend authentication only
  Future<ApiResponse<AuthResponse>> signInWithApple({String? nickname}) async {
    try {
      // Check if Sign in with Apple is available
      if (!await SignInWithApple.isAvailable()) {
        return ApiResponse.error(
          error: 'Sign in with Apple is not available on this device',
        );
      }

      AppHelpers.logUserAction('apple_signin_attempt_started');

      // Request Apple credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      AppHelpers.logUserAction('apple_credential_received', {
        'has_identity_token': credential.identityToken != null,
        'has_email': credential.email != null,
        'has_given_name': credential.givenName != null,
        'user_identifier': credential.userIdentifier,
      });

      // Validate required fields
      if (credential.identityToken == null) {
        return ApiResponse.error(
          error: 'Failed to get identity token from Apple',
        );
      }

      // Extract nickname from Apple response if not provided
      String? finalNickname = nickname;
      if (finalNickname == null) {
        if (credential.givenName != null && credential.givenName!.isNotEmpty) {
          final givenName = credential.givenName ?? '';
          final familyName = credential.familyName ?? '';
          finalNickname = '$givenName $familyName'.trim();
          if (finalNickname.isEmpty) {
            finalNickname = null;
          }
        }

        // Fallback to email or user identifier
        if (finalNickname == null) {
          if (credential.email != null) {
            finalNickname = credential.email!.split('@')[0];
          } else {
            finalNickname = credential.userIdentifier ?? 'Apple User';
          }
        }
      }

      // Create request
      final request = AppleSignInRequest(
        identityToken: credential.identityToken!,
        userIdentifier: credential.userIdentifier ?? 'unknown_user',
        nickname: finalNickname,
      );

      AppHelpers.logUserAction('sending_to_backend', {
        'user_identifier': credential.userIdentifier,
        'has_nickname': finalNickname != null,
        'nickname': finalNickname,
      });

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
      } else {
        AppHelpers.logUserAction('apple_backend_auth_failed', {
          'error': response.error,
          'status_code': response.statusCode,
        });
      }

      return response;

    } on SignInWithAppleAuthorizationException catch (e) {
      final errorMessage = _handleAppleAuthError(e);

      AppHelpers.logUserAction('apple_sign_in_error', {
        'error_code': e.code.toString(),
        'error_message': errorMessage,
      });

      return ApiResponse.error(error: errorMessage);
    } catch (e) {
      AppHelpers.logUserAction('apple_sign_in_unexpected_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Handle Apple authorization errors
  String _handleAppleAuthError(SignInWithAppleAuthorizationException e) {
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        return 'Sign in was cancelled';
      case AuthorizationErrorCode.failed:
        return 'Sign in failed';
      case AuthorizationErrorCode.invalidResponse:
        return 'Invalid response from Apple';
      case AuthorizationErrorCode.notHandled:
        return 'Sign in not handled';
      case AuthorizationErrorCode.unknown:
      default:
        return 'Unknown error occurred during sign in';
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      AppHelpers.logUserAction('logout_started');

      // Clear API token
      _apiService.clearAuthToken();

      // Clear stored data
      _storageService.logout();

      // Navigate to login
      Get.offAllNamed(AppRoutes.login);

      AppHelpers.logUserAction('logout_completed');
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
        AppHelpers.logUserAction('invalid_user_data_cleared', {
          'error': e.toString(),
        });

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
        AppHelpers.logUserAction('session_validation_no_login');
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

        AppHelpers.logUserAction('session_validation_success');
        return true;
      } else {
        // Session invalid, logout if unauthorized
        if (response.statusCode == 401) {
          AppHelpers.logUserAction('session_expired_logging_out');
          await logout();
        }

        AppHelpers.logUserAction('session_validation_failed', {
          'status_code': response.statusCode,
          'error': response.error,
        });

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

  /// Initialize auth service
  Future<void> initializeAuth() async {
    try {
      if (isLoggedIn) {
        // Set API token from storage
        final token = _storageService.getToken();
        if (token != null) {
          _apiService.setAuthToken(token);
        }

        // Validate session in background
        validateSession().then((isValid) {
          AppHelpers.logUserAction('background_session_validation', {
            'is_valid': isValid,
          });
        });

        AppHelpers.logUserAction('auth_initialized', {
          'has_token': token != null,
          'has_user_data': _storageService.hasUserData(),
        });
      } else {
        AppHelpers.logUserAction('auth_initialized_no_session');
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

  /// Delete account
  Future<ApiResponse<bool>> deleteAccount() async {
    try {
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

  /// Export user data
  Future<ApiResponse<Map<String, dynamic>>> exportUserData() async {
    try {
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