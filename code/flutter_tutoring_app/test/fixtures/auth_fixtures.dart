import '../test_config.dart';

/// Authentication test fixtures for consistent test data
class AuthFixtures {
  // Valid test users
  static const validStudentUser = {
    'id': 'student-123',
    'email': 'student@example.com',
    'password': 'StudentPassword123!',
    'role': 'student',
    'firstName': 'John',
    'lastName': 'Doe',
    'profilePicture': 'https://example.com/avatar1.jpg',
    'createdAt': '2024-01-01T00:00:00Z',
    'lastLoginAt': '2024-01-01T00:00:00Z',
    'isEmailVerified': true,
    'isActive': true,
  };

  static const validTutorUser = {
    'id': 'tutor-456',
    'email': 'tutor@example.com',
    'password': 'TutorPassword123!',
    'role': 'tutor',
    'firstName': 'Jane',
    'lastName': 'Smith',
    'profilePicture': 'https://example.com/avatar2.jpg',
    'createdAt': '2024-01-01T00:00:00Z',
    'lastLoginAt': '2024-01-01T00:00:00Z',
    'isEmailVerified': true,
    'isActive': true,
    'specializations': ['Mathematics', 'Physics', 'Chemistry'],
    'hourlyRate': 50.00,
    'rating': 4.8,
    'totalReviews': 150,
  };

  static const validAdminUser = {
    'id': 'admin-789',
    'email': 'admin@example.com',
    'password': 'AdminPassword123!',
    'role': 'admin',
    'firstName': 'Admin',
    'lastName': 'User',
    'profilePicture': 'https://example.com/avatar3.jpg',
    'createdAt': '2024-01-01T00:00:00Z',
    'lastLoginAt': '2024-01-01T00:00:00Z',
    'isEmailVerified': true,
    'isActive': true,
    'permissions': ['manage_users', 'manage_assignments', 'view_analytics'],
  };

  // Invalid test data
  static const invalidUserEmail = {
    'email': 'invalid-email',
    'password': 'ValidPassword123!',
  };

  static const invalidUserPassword = {
    'email': 'valid@example.com',
    'password': 'weak', // Too short
  };

  static const emptyUser = {
    'email': '',
    'password': '',
  };

  // Authentication tokens
  static const validAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';
  static const expiredAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.expired.token';
  static const invalidAccessToken = 'invalid.token';
  static const validRefreshToken = 'refresh_token_123456789';

  // Authentication responses
  static const successfulLoginResponse = {
    'success': true,
    'data': {
      'user': validStudentUser,
      'accessToken': validAccessToken,
      'refreshToken': validRefreshToken,
      'expiresIn': 3600,
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const successfulRegisterResponse = {
    'success': true,
    'data': {
      'message': 'User registered successfully',
      'userId': 'student-123',
      'verificationEmailSent': true,
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const failedLoginResponse = {
    'success': false,
    'error': {
      'code': 'INVALID_CREDENTIALS',
      'message': 'Invalid email or password',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const emailExistsResponse = {
    'success': false,
    'error': {
      'code': 'EMAIL_ALREADY_EXISTS',
      'message': 'Email address is already registered',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const emailNotVerifiedResponse = {
    'success': false,
    'error': {
      'code': 'EMAIL_NOT_VERIFIED',
      'message': 'Please verify your email address before logging in',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const accountLockedResponse = {
    'success': false,
    'error': {
      'code': 'ACCOUNT_LOCKED',
      'message': 'Account is temporarily locked due to too many failed login attempts',
      'lockoutDuration': 900, // 15 minutes
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  // Password reset fixtures
  static const passwordResetRequest = {
    'email': 'user@example.com',
  };

  static const passwordResetResponse = {
    'success': true,
    'data': {
      'message': 'Password reset email sent',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const passwordResetConfirm = {
    'token': 'reset_token_123',
    'newPassword': 'NewPassword123!',
  };

  static const passwordResetSuccessResponse = {
    'success': true,
    'data': {
      'message': 'Password reset successfully',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  // Profile update fixtures
  static const profileUpdateRequest = {
    'firstName': 'Updated',
    'lastName': 'Name',
    'profilePicture': 'https://example.com/new-avatar.jpg',
  };

  static const profileUpdateResponse = {
    'success': true,
    'data': {
      'user': {
        ...validStudentUser,
        ...profileUpdateRequest,
      },
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  // Social login fixtures
  static const googleLoginRequest = {
    'provider': 'google',
    'idToken': 'google_id_token_123',
  };

  static const facebookLoginRequest = {
    'provider': 'facebook',
    'accessToken': 'facebook_access_token_123',
  };

  static const socialLoginResponse = {
    'success': true,
    'data': {
      'user': validStudentUser,
      'accessToken': validAccessToken,
      'refreshToken': validRefreshToken,
      'isNewUser': false,
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  // Biometric authentication fixtures
  static const biometricAuthRequest = {
    'userId': 'student-123',
    'biometricType': 'fingerprint',
  };

  static const biometricAuthResponse = {
    'success': true,
    'data': {
      'biometricToken': 'biometric_token_123',
      'expiresIn': 86400, // 24 hours
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  // Session management fixtures
  static const activeSession = {
    'id': 'session-123',
    'userId': 'student-123',
    'deviceId': 'device-123',
    'ipAddress': '192.168.1.1',
    'userAgent': 'Mozilla/5.0 (test)',
    'startedAt': '2024-01-01T00:00:00Z',
    'lastActivityAt': '2024-01-01T00:00:00Z',
    'isActive': true,
  };

  static const sessionsListResponse = {
    'success': true,
    'data': {
      'sessions': [activeSession],
      'currentSessionId': 'session-123',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  // Helper methods
  static Map<String, dynamic> createUser({
    String? id,
    String? email,
    String? role,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'id': id ?? 'user-123',
      'email': email ?? 'test@example.com',
      'role': role ?? 'student',
      'firstName': 'Test',
      'lastName': 'User',
      'createdAt': DateTime.now().toIso8601String(),
      'isEmailVerified': true,
      'isActive': true,
      ...?additionalData,
    };
  }

  static Map<String, dynamic> createAuthResponse({
    bool success = true,
    Map<String, dynamic>? data,
    String? errorCode,
    String? errorMessage,
  }) {
    if (success) {
      return {
        'success': true,
        'data': data ?? {
          'user': validStudentUser,
          'accessToken': validAccessToken,
          'refreshToken': validRefreshToken,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      return {
        'success': false,
        'error': {
          'code': errorCode ?? 'UNKNOWN_ERROR',
          'message': errorMessage ?? 'An unknown error occurred',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  static bool isValidToken(String token) {
    return token.split('.').length == 3;
  }
}