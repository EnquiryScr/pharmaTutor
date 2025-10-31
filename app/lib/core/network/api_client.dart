import 'package:dio/dio.dart';

/// Base API client that provides common functionality for all API clients
class ApiClient {
  final Dio _dio;
  
  ApiClient(this._dio) {
    _configureDio();
  }

  void _configureDio() {
    // Set up base configuration
    _dio.options.baseUrl = 'https://api.tutorflow.com/v1';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authentication token if available
          // final token = await getAuthToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Handle responses globally
          handler.next(response);
        },
        onError: (error, handler) {
          // Handle errors globally
          _handleDioError(error);
          handler.next(error);
        },
      ),
    );
  }

  void _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        throw ApiException('Connection timeout', ApiExceptionType.timeout);
      case DioExceptionType.sendTimeout:
        throw ApiException('Send timeout', ApiExceptionType.timeout);
      case DioExceptionType.receiveTimeout:
        throw ApiException('Receive timeout', ApiExceptionType.timeout);
      case DioExceptionType.badResponse:
        throw ApiException(
          'Server error: ${error.response?.statusCode}',
          ApiExceptionType.serverError,
        );
      case DioExceptionType.cancel:
        throw ApiException('Request cancelled', ApiExceptionType.cancelled);
      case DioExceptionType.connectionError:
        throw ApiException('Connection error', ApiExceptionType.networkError);
      default:
        throw ApiException('Unknown error', ApiExceptionType.unknown);
    }
  }

  // Generic GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'GET request failed',
        _mapDioExceptionType(e.type),
      );
    }
  }

  // Generic POST request
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'POST request failed',
        _mapDioExceptionType(e.type),
      );
    }
  }

  // Generic PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'PUT request failed',
        _mapDioExceptionType(e.type),
      );
    }
  }

  // Generic DELETE request
  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'DELETE request failed',
        _mapDioExceptionType(e.type),
      );
    }
  }

  // Generic PATCH request
  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'PATCH request failed',
        _mapDioExceptionType(e.type),
      );
    }
  }

  // Upload file
  Future<T> uploadFile<T>(
    String endpoint,
    String filePath, {
    String? fileName,
    String? contentType,
    Map<String, dynamic>? additionalData,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final fileNameToSend = fileName ?? filePath.split('/').last;
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileNameToSend,
          contentType: contentType != null 
              ? ContentType.parse(contentType) 
              : null,
        ),
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'File upload failed',
        _mapDioExceptionType(e.type),
      );
    }
  }

  // Download file
  Future<String> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        onReceiveProgress: onReceiveProgress,
      );

      if (response.statusCode == 200) {
        return savePath;
      } else {
        throw ApiException(
          'Download failed with status: ${response.statusCode}',
          ApiExceptionType.serverError,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'File download failed',
        _mapDioExceptionType(e.type),
      );
    }
  }

  // Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Remove authentication token
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Handle response and map to appropriate type
  T _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      
      if (fromJson != null && data is Map<String, dynamic>) {
        return fromJson(data);
      }
      
      return data as T;
    } else {
      throw ApiException(
        'Server error: ${response.statusCode}',
        ApiExceptionType.serverError,
      );
    }
  }

  ApiExceptionType _mapDioExceptionType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiExceptionType.timeout;
      case DioExceptionType.badResponse:
        return ApiExceptionType.serverError;
      case DioExceptionType.cancel:
        return ApiExceptionType.cancelled;
      case DioExceptionType.connectionError:
        return ApiExceptionType.networkError;
      default:
        return ApiExceptionType.unknown;
    }
  }

  // Get current base URL
  String get baseUrl => _dio.options.baseUrl;
}

/// API Exception class for handling different types of API errors
class ApiException implements Exception {
  final String message;
  final ApiExceptionType type;
  final int? statusCode;
  final Map<String, dynamic>? data;

  const ApiException(
    this.message, {
    required this.type,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException{message: $message, type: $type, statusCode: $statusCode}';
  }

  bool get isNetworkError => type == ApiExceptionType.networkError;
  bool get isTimeout => type == ApiExceptionType.timeout;
  bool get isServerError => type == ApiExceptionType.serverError;
  bool get isCancelled => type == ApiExceptionType.cancelled;
  bool get isUnknown => type == ApiExceptionType.unknown;

  /// Check if error is due to authentication issues
  bool get isAuthError => 
      statusCode == 401 || statusCode == 403 || message.contains('unauthorized');

  /// Check if error is due to validation issues
  bool get isValidationError => 
      statusCode == 400 || message.contains('validation');

  /// Check if error is due to not found
  bool get isNotFound => statusCode == 404;

  /// Check if error is due to conflict
  bool get isConflict => statusCode == 409;

  /// Check if error is due to server maintenance
  bool get isServerMaintenance => 
      statusCode == 503 || message.contains('maintenance');
}

/// API Exception types
enum ApiExceptionType {
  networkError,
  timeout,
  serverError,
  cancelled,
  unknown,
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.metadata,
  });

  factory ApiResponse.success({
    T? data,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      metadata: metadata,
    );
  }

  factory ApiResponse.error({
    String? error,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      message: json['message'],
      error: json['error'],
      statusCode: json['statusCode'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'error': error,
      'statusCode': statusCode,
      'metadata': metadata,
    };
  }
}

/// Generic paginated API response
class PaginatedApiResponse<T> {
  final List<T>? data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? message;

  const PaginatedApiResponse({
    this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.message,
  });

  factory PaginatedApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return PaginatedApiResponse<T>(
      data: json['data'] != null
          ? (json['data'] as List<dynamic>)
              .map((item) => fromJsonT != null 
                  ? fromJsonT(item) 
                  : item as T)
              .toList()
          : null,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 20,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.map((item) => item.toString()).toList(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
      'message': message,
    };
  }
}