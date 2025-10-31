import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'TutorFlow';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'https://api.tutorflow.com/v1';
  static const String apiKey = 'your-api-key-here';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  // Database Configuration
  static const String databaseName = 'tutorflow.db';
  static const int databaseVersion = 1;
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Screen Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
}

class AppRoutes {
  // Authentication
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Main
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  
  // Tutoring
  static const String tutors = '/tutors';
  static const String tutorProfile = '/tutor-profile';
  static const String bookSession = '/book-session';
  static const String sessionDetails = '/session-details';
  
  // Learning
  static const String courses = '/courses';
  static const String courseDetails = '/course-details';
  static const String lessons = '/lessons';
  static const String assignments = '/assignments';
  
  // Profile
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  
  // Chat
  static const String chat = '/chat';
  static const String chatList = '/chat-list';
}

class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  
  // User
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  
  // Tutors
  static const String tutors = '/tutors';
  static const String tutorDetails = '/tutors/{id}';
  
  // Sessions
  static const String sessions = '/sessions';
  static const String bookSession = '/sessions/book';
  static const String sessionHistory = '/sessions/history';
  
  // Courses
  static const String courses = '/courses';
  static const String courseDetails = '/courses/{id}';
  
  // Messages
  static const String messages = '/messages';
  static const String sendMessage = '/messages/send';
}

class StorageKeys {
  static const String token = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String onboarding = 'onboarding_completed';
  static const String notifications = 'notifications_enabled';
}

class ValidationConstants {
  static const RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static const RegExp phoneRegExp = RegExp(
    r'^\+?[\d\s\-\(\)]{10,}$',
  );
  
  static const RegExp passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
}

class ApiStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int serverError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
}

class Colors {
  // Primary Colors
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4338CA);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
}

class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class BorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0;
}

class FontSizes {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double md = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class FontWeights {
  static const FontWeight light = FontWeight.w300;
  static const FontWeight normal = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.textPrimary,
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.gray900,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.gray900,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}