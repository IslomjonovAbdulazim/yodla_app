import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:http_parser/http_parser.dart';

import '../models/api_response_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService extends getx.GetxService {
  late Dio _dio;
  late StorageService _storageService;

  @override
  void onInit() {
    super.onInit();
    _storageService = getx.Get.find<StorageService>();
    _initializeDio();
  }

  MediaType _detectContentType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    } else if (ext.endsWith('.png')) {
      return MediaType('image', 'png');
    } else if (ext.endsWith('.heic')) {
      return MediaType('image', 'heic');
    } else if (ext.endsWith('.heif')) {
      return MediaType('image', 'heif');
    } else {
      return MediaType('application', 'octet-stream'); // fallback
    }
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_createAuthInterceptor());
    _dio.interceptors.add(_createLoggingInterceptor());
    _dio.interceptors.add(_createErrorInterceptor());
  }

  /// Authentication interceptor - adds JWT token to requests
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized - token expired
        if (error.response?.statusCode == 401) {
          await _handleTokenExpiry();
        }
        handler.next(error);
      },
    );
  }

  /// Logging interceptor for debugging
  Interceptor _createLoggingInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (object) {
        // Only log in debug mode
        if (AppConstants.baseUrl.contains('localhost') ||
            AppConstants.baseUrl.contains('railway.app')) {
          print('[API] $object');
        }
      },
    );
  }

  /// Error handling interceptor
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // Handle common errors
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          error = error.copyWith(
            message: 'Connection timeout. Please check your internet connection.',
          );
        } else if (error.type == DioExceptionType.connectionError) {
          error = error.copyWith(
            message: 'No internet connection. Please check your network.',
          );
        }

        handler.next(error);
      },
    );
  }

  /// Handle token expiry
  Future<void> _handleTokenExpiry() async {
    _storageService.logout();
    getx.Get.offAllNamed('/login');
    // TODO: Show token expired message
  }

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
        T Function(Map<String, dynamic>)? fromJson,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (fromJson != null) {
        final data = fromJson(response.data);
        return ApiResponse.success(data: data, statusCode: response.statusCode);
      } else {
        return ApiResponse.success(data: response.data, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse.error(error: e.toString());
    }
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        T Function(Map<String, dynamic>)? fromJson,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (fromJson != null) {
        final responseData = fromJson(response.data);
        return ApiResponse.success(data: responseData, statusCode: response.statusCode);
      } else {
        return ApiResponse.success(data: response.data, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse.error(error: e.toString());
    }
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        T Function(Map<String, dynamic>)? fromJson,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (fromJson != null) {
        final responseData = fromJson(response.data);
        return ApiResponse.success(data: responseData, statusCode: response.statusCode);
      } else {
        return ApiResponse.success(data: response.data, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse.error(error: e.toString());
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
      String endpoint, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        T Function(Map<String, dynamic>)? fromJson,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (fromJson != null) {
        final responseData = fromJson(response.data);
        return ApiResponse.success(data: responseData, statusCode: response.statusCode);
      } else {
        return ApiResponse.success(data: response.data, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse.error(error: e.toString());
    }
  }

  /// Upload file (multipart)
  Future<ApiResponse<T>> uploadFile<T>(
      String endpoint, {
        required File file,
        required String fileKey,
        Map<String, dynamic>? data,
        T Function(Map<String, dynamic>)? fromJson,
        ProgressCallback? onProgress,
      }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        if (data != null) ...data,
        fileKey: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: _detectContentType(fileName),
        ),
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: onProgress,
      );

      if (fromJson != null) {
        final responseData = fromJson(response.data);
        return ApiResponse.success(data: responseData, statusCode: response.statusCode);
      } else {
        return ApiResponse.success(data: response.data, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse.error(error: e.toString());
    }
  }

  /// Download file
  Future<ApiResponse<String>> downloadFile(
      String endpoint,
      String savePath, {
        ProgressCallback? onProgress,
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      final response = await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onProgress,
      );

      return ApiResponse.success(
        data: savePath,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse.error(error: e.toString());
    }
  }

  /// Health check
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return await get<Map<String, dynamic>>(
      ApiEndpoints.health,
      fromJson: (json) => json,
    );
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Update base URL (for switching environments)
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Get current base URL
  String get baseUrl => _dio.options.baseUrl;

  /// Check if token exists
  bool get hasAuthToken {
    return _dio.options.headers.containsKey('Authorization');
  }

  /// Get current auth token
  String? get authToken {
    final authHeader = _dio.options.headers['Authorization'] as String?;
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }
    return null;
  }

  /// Cancel all requests
  void cancelAllRequests([String? reason]) {
    _dio.interceptors.clear();
  }

  /// Create cancel token for specific request
  CancelToken createCancelToken() {
    return CancelToken();
  }

  /// Handle network connectivity
  bool get isConnected {
    // This would typically check actual connectivity
    // For now, we'll assume connected if we can make requests
    return true;
  }

  /// Retry mechanism for failed requests
  Future<ApiResponse<T>> retry<T>(
      Future<ApiResponse<T>> Function() request, {
        int maxRetries = 3,
        Duration delay = const Duration(seconds: 1),
      }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final response = await request();
        if (response.success) {
          return response;
        }

        // Don't retry on client errors (4xx)
        if (response.statusCode != null &&
            response.statusCode! >= 400 &&
            response.statusCode! < 500) {
          return response;
        }

        attempts++;
        if (attempts < maxRetries) {
          await Future.delayed(delay * attempts);
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          return ApiResponse.error(error: e.toString());
        }
        await Future.delayed(delay * attempts);
      }
    }

    return ApiResponse.error(error: 'Max retry attempts exceeded');
  }

  /// Batch requests
  Future<List<ApiResponse<dynamic>>> batchRequests(
      List<Future<ApiResponse<dynamic>>> requests
      ) async {
    try {
      return await Future.wait(requests);
    } catch (e) {
      return requests.map((r) => ApiResponse.error(error: e.toString())).toList();
    }
  }

  /// Cache management
  final Map<String, CacheItem> _cache = {};

  /// Get from cache or make request
  Future<ApiResponse<T>> getWithCache<T>(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
        T Function(Map<String, dynamic>)? fromJson,
        Duration cacheDuration = const Duration(minutes: 5),
      }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParameters);
    final cachedItem = _cache[cacheKey];

    if (cachedItem != null && !cachedItem.isExpired) {
      return ApiResponse.success(data: cachedItem.data as T);
    }

    final response = await get<T>(
      endpoint,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );

    if (response.success) {
      _cache[cacheKey] = CacheItem(
        data: response.data,
        expiresAt: DateTime.now().add(cacheDuration),
      );
    }

    return response;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Clear expired cache items
  void clearExpiredCache() {
    _cache.removeWhere((key, item) => item.isExpired);
  }

  String _generateCacheKey(String endpoint, Map<String, dynamic>? params) {
    final paramsString = params?.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&') ?? '';
    return '$endpoint?$paramsString';
  }
}

/// Cache item for request caching
class CacheItem {
  final dynamic data;
  final DateTime expiresAt;

  CacheItem({
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Request configuration for advanced usage
class RequestConfig {
  final Duration? timeout;
  final int? maxRetries;
  final bool useCache;
  final Duration? cacheDuration;
  final Map<String, String>? headers;
  final CancelToken? cancelToken;

  const RequestConfig({
    this.timeout,
    this.maxRetries,
    this.useCache = false,
    this.cacheDuration,
    this.headers,
    this.cancelToken,
  });
}

/// Error codes for consistent error handling
class ApiErrorCodes {
  static const String networkError = 'NETWORK_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String validationError = 'VALIDATION_ERROR';
  static const String timeoutError = 'TIMEOUT_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';

  static String fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
        return unauthorized;
      case 403:
        return forbidden;
      case 404:
        return notFound;
      case 422:
        return validationError;
      case 500:
      case 502:
      case 503:
      case 504:
        return serverError;
      default:
        return unknownError;
    }
  }
}