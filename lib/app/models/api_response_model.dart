import 'package:dio/dio.dart';

/// Generic API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.meta,
  });

  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
      meta: meta,
    );
  }

  factory ApiResponse.error({
    required String error,
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode ?? 500,
      meta: meta,
    );
  }

  /// Create ApiResponse from Dio Response
  factory ApiResponse.fromResponse(Response response, T data) {
    return ApiResponse<T>(
      success: response.statusCode! >= 200 && response.statusCode! < 300,
      data: data,
      statusCode: response.statusCode,
      message: response.statusMessage,
    );
  }

  /// Create error response from Dio Error
  factory ApiResponse.fromError(DioException error) {
    String errorMessage;
    int statusCode = 500;

    if (error.response != null) {
      statusCode = error.response!.statusCode ?? 500;

      // Extract error message from response
      if (error.response!.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        errorMessage = data['detail'] ??
            data['message'] ??
            data['error'] ??
            error.message ??
            'Unknown error occurred';
      } else {
        errorMessage = error.response!.statusMessage ?? 'Unknown error occurred';
      }
    } else {
      // Network errors
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Send timeout';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Receive timeout';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Network connection failed';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled';
          break;
        default:
          errorMessage = error.message ?? 'Network error occurred';
      }
    }

    return ApiResponse<T>(
      success: false,
      error: errorMessage,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, data: $data, message: $message, error: $error, statusCode: $statusCode}';
  }
}

/// Pagination metadata for list responses
class PaginationMeta {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNext;
  final bool hasPrevious;

  PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      itemsPerPage: json['items_per_page'] ?? 20,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'total_pages': totalPages,
      'total_items': totalItems,
      'items_per_page': itemsPerPage,
      'has_next': hasNext,
      'has_previous': hasPrevious,
    };
  }
}

/// List Response wrapper with pagination
class ListResponse<T> {
  final List<T> items;
  final int totalCount;
  final PaginationMeta? pagination;

  ListResponse({
    required this.items,
    required this.totalCount,
    this.pagination,
  });

  factory ListResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    final itemsList = json['items'] as List<dynamic>? ??
        json['data'] as List<dynamic>? ??
        json['results'] as List<dynamic>? ??
        [];

    return ListResponse<T>(
      items: itemsList.map((item) => fromJsonT(item as Map<String, dynamic>)).toList(),
      totalCount: json['total_count'] ?? json['total'] ?? itemsList.length,
      pagination: json['pagination'] != null
          ? PaginationMeta.fromJson(json['pagination'])
          : null,
    );
  }
}

/// Error details for validation errors
class ValidationError {
  final String field;
  final String message;
  final dynamic value;

  ValidationError({
    required this.field,
    required this.message,
    this.value,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      'value': value,
    };
  }
}

/// Exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final List<ValidationError>? validationErrors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.validationErrors,
  });

  factory ApiException.fromResponse(Response response) {
    String message = 'Unknown error occurred';
    String? errorCode;
    List<ValidationError>? validationErrors;

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      message = data['detail'] ?? data['message'] ?? data['error'] ?? message;
      errorCode = data['error_code'];

      // Handle validation errors
      if (data['validation_errors'] is List) {
        validationErrors = (data['validation_errors'] as List)
            .map((e) => ValidationError.fromJson(e))
            .toList();
      }
    }

    return ApiException(
      message: message,
      statusCode: response.statusCode,
      errorCode: errorCode,
      validationErrors: validationErrors,
    );
  }

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode, Code: $errorCode)';
  }

  bool get isNetworkError => statusCode == null;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422 || (validationErrors?.isNotEmpty ?? false);
}