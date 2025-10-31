import 'dart:async';
import 'package:dio/dio.dart';
import '../utils/base_model.dart';
import 'api_client.dart';

/// Authentication API client for handling auth-related requests
class AuthApiClient {
  final Dio _dio;
  final ApiClient _apiClient;

  AuthApiClient(this._dio) : _apiClient = ApiClient(_dio);

  // Login user
  Future<ApiResponse<AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return ApiResponse<AuthResult>.fromJson(
        response.data,
        (json) => AuthResult.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Login failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Register new user
  Future<ApiResponse<AuthResult>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      return ApiResponse<AuthResult>.fromJson(
        response.data,
        (json) => AuthResult.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Registration failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _dio.post('/auth/logout');
      
      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Logout failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Refresh authentication token
  Future<ApiResponse<AuthResult>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      return ApiResponse<AuthResult>.fromJson(
        response.data,
        (json) => AuthResult.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Token refresh failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Forgot password
  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {
          'email': email,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Password reset request failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Reset password
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Password reset failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Verify email
  Future<ApiResponse<void>> verifyEmail(String token) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {
          'token': token,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Email verification failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Resend verification email
  Future<ApiResponse<void>> resendVerificationEmail(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-verification',
        data: {
          'email': email,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Resend verification failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Password change failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Get current user profile
  Future<ApiResponse<UserModel>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (json) => UserModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Failed to get user profile',
        ApiExceptionType.serverError,
      );
    }
  }

  // Update user profile
  Future<ApiResponse<UserModel>> updateProfile({
    String? name,
    String? phone,
    String? bio,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/profile',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
        },
      );

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (json) => UserModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Profile update failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Upload profile avatar
  Future<ApiResponse<String>> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/auth/upload-avatar',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return ApiResponse<String>.fromJson(
        response.data,
        (json) => json['avatarUrl'] as String,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Avatar upload failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Delete user account
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final response = await _dio.delete('/auth/account');

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Account deletion failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Update notification preferences
  Future<ApiResponse<void>> updateNotificationPreferences({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/notification-preferences',
        data: {
          if (emailNotifications != null) 'emailNotifications': emailNotifications,
          if (pushNotifications != null) 'pushNotifications': pushNotifications,
          if (smsNotifications != null) 'smsNotifications': smsNotifications,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Notification preferences update failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Get authentication status
  Future<ApiResponse<Map<String, dynamic>>> getAuthStatus() async {
    try {
      final response = await _dio.get('/auth/status');

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Failed to get auth status',
        ApiExceptionType.serverError,
      );
    }
  }

  // Enable two-factor authentication
  Future<ApiResponse<Map<String, String>>> enableTwoFactor() async {
    try {
      final response = await _dio.post('/auth/enable-2fa');

      return ApiResponse<Map<String, String>>.fromJson(
        response.data,
        (json) => Map<String, String>.from(json),
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Failed to enable 2FA',
        ApiExceptionType.serverError,
      );
    }
  }

  // Verify two-factor authentication code
  Future<ApiResponse<void>> verifyTwoFactor(String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-2fa',
        data: {
          'code': code,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? '2FA verification failed',
        ApiExceptionType.serverError,
      );
    }
  }

  // Disable two-factor authentication
  Future<ApiResponse<void>> disableTwoFactor(String password) async {
    try {
      final response = await _dio.post(
        '/auth/disable-2fa',
        data: {
          'password': password,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data,
        null,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Failed to disable 2FA',
        ApiExceptionType.serverError,
      );
    }
  }
}

/// User model (placeholder - should match the actual UserModel from models)
class UserModel extends BaseModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? bio;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.bio,
    this.avatar,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'bio': bio,
      'avatar': avatar,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, name, phone, bio, avatar];
}

/// Auth result model (placeholder - should match the actual AuthResult from repositories)
class AuthResult extends BaseModel {
  final String? token;
  final String? refreshToken;
  final UserModel? user;
  final bool success;
  final String? message;

  const AuthResult({
    this.token,
    this.refreshToken,
    this.user,
    required this.success,
    this.message,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
      'success': success,
      'message': message,
    };
  }

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] != null 
          ? UserModel.fromJson(json['user'])
          : null,
      success: json['success'] as bool,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken, user, success, message];
}