import 'package:flutter_test/flutter_test.dart';

/// Global test configuration for the Flutter tutoring platform
class TestConfig {
  // Environment configuration
  static const String testEnvironment = 'test';
  static const String mockApiBaseUrl = 'https://mock-api.test';
  static const String mockFirebaseUrl = 'https://mock-firebase.test';
  
  // Test timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);
  static const Duration asyncOperationTimeout = Duration(seconds: 5);
  
  // Test data
  static const String testUserEmail = 'test@example.com';
  static const String testUserPassword = 'TestPassword123!';
  static const String testUserId = 'test-user-id';
  static const String testUserRole = 'student';
  
  // Mock API endpoints
  static const String mockLoginEndpoint = '/auth/login';
  static const String mockRegisterEndpoint = '/auth/register';
  static const String mockLogoutEndpoint = '/auth/logout';
  static const String mockProfileEndpoint = '/user/profile';
  static const String mockAssignmentsEndpoint = '/assignments';
  static const String mockChatEndpoint = '/chat';
  static const String mockPaymentEndpoint = '/payments';
  
  // Firebase emulator configuration
  static const String firebaseEmulatorHost = 'localhost';
  static const int firebaseAuthPort = 9099;
  static const int firebaseFirestorePort = 8080;
  static const int firebaseStoragePort = 9199;
  static const int firebaseFunctionsPort = 5001;
  
  // Test fixtures paths
  static const String fixturePath = 'test/fixtures/';
  
  // Performance thresholds
  static const int maxMemoryUsageMB = 50;
  static const Duration maxStartupTime = Duration(seconds: 3);
  static const Duration maxApiResponseTime = Duration(seconds: 2);
  
  // Accessibility configuration
  static const double minimumTouchTargetSize = 48.0;
  static const double minimumFontSize = 14.0;
  static const int minimumColorContrastRatio = 4.5;
}

/// Test database configuration
class TestDatabase {
  static const String dbName = 'test_tutoring_app.db';
  static const int dbVersion = 1;
}

/// Network testing configuration
class NetworkTestConfig {
  static const Map<String, dynamic> mockSuccessResponse = {
    'success': true,
    'data': {'message': 'Success'},
    'timestamp': '2024-01-01T00:00:00Z',
  };
  
  static const Map<String, dynamic> mockErrorResponse = {
    'success': false,
    'error': {'code': 'TEST_ERROR', 'message': 'Test error message'},
    'timestamp': '2024-01-01T00:00:00Z',
  };
  
  static const Map<String, dynamic> mockValidationError = {
    'success': false,
    'error': {
      'code': 'VALIDATION_ERROR',
      'message': 'Validation failed',
      'details': {'email': 'Invalid email format'}
    },
  };
}

/// Cache testing configuration
class CacheTestConfig {
  static const Duration shortExpiry = Duration(seconds: 1);
  static const Duration mediumExpiry = Duration(minutes: 5);
  static const Duration longExpiry = Duration(hours: 1);
  static const int maxCacheSize = 100;
}

/// Payment testing configuration
class PaymentTestConfig {
  static const String testCardNumber = '4242424242424242';
  static const String testCardCvc = '123';
  static const String testCardExpiry = '12/34';
  static const String testZipCode = '12345';
  static const double testAmount = 99.99;
  static const String testCurrency = 'USD';
}

/// Chat testing configuration
class ChatTestConfig {
  static const String testRoomId = 'test-room-123';
  static const String testMessage = 'Hello, this is a test message!';
  static const int maxMessagesPerPage = 50;
  static const Duration messageTimeout = Duration(seconds: 10);
}

/// Assignment testing configuration
class AssignmentTestConfig {
  static const String testAssignmentId = 'test-assignment-123';
  static const String testAssignmentTitle = 'Test Assignment';
  static const String testAssignmentDescription = 'This is a test assignment description';
  static const Duration testAssignmentDuration = Duration(hours: 2);
  static const int maxAttachments = 5;
  static const int maxAttachmentSizeMB = 10;
}

/// Authentication testing configuration
class AuthTestConfig {
  static const Duration tokenExpiry = Duration(hours: 1);
  static const Duration refreshTokenExpiry = Duration(days: 30);
  static const int maxLoginAttempts = 3;
  static const Duration lockoutDuration = Duration(minutes: 15);
}

/// File upload testing configuration
class FileUploadTestConfig {
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt'];
  static const int maxFileSizeMB = 10;
  static const List<int> allowedImageDimensions = [1920, 1080]; // width, height
}

/// Performance testing configuration
class PerformanceTestConfig {
  static const int iterationsForMemoryTest = 100;
  static const Duration memoryTestDuration = Duration(seconds: 30);
  static const int maxConcurrentOperations = 10;
  static const double maxMemoryLeakPercentage = 5.0;
}

/// Accessibility testing configuration
class AccessibilityTestConfig {
  static const List<String> requiredAccessibilityLabels = [
    'button',
    'image',
    'input',
    'link',
    'heading',
  ];
  
  static const Map<String, double> minimumTouchTargets = {
    'small': 44.0,
    'medium': 48.0,
    'large': 56.0,
  };
  
  static const Map<String, int> minimumColorContrast = {
    'normal': 4.5,
    'large': 3.0,
  };
}

/// Helper methods for test configuration
class TestHelpers {
  /// Create a test timeout configuration
  static Duration getTimeout(String testType) {
    switch (testType.toLowerCase()) {
      case 'unit':
        return TestConfig.defaultTimeout;
      case 'widget':
        return TestConfig.defaultTimeout;
      case 'integration':
        return TestConfig.longTimeout;
      case 'performance':
        return TestConfig.longTimeout;
      default:
        return TestConfig.defaultTimeout;
    }
  }
  
  /// Validate test environment
  static bool isTestEnvironment() {
    return const bool.fromEnvironment('dart.test.vm');
  }
  
  /// Check if running in CI environment
  static bool isCiEnvironment() {
    return const bool.fromEnvironment('dart.library.dart2js');
  }
  
  /// Get test platform
  static String getTestPlatform() {
    if (const bool.fromEnvironment('dart.library.html')) {
      return 'web';
    }
    return 'flutter';
  }
}

/// Custom test matchers for common assertions
class CustomMatchers {
  /// Matcher for successful API responses
  static Matcher isSuccessfulApiResponse() {
    return predicate<Map<String, dynamic>>(
      (response) => response['success'] == true,
      'is a successful API response',
    );
  }
  
  /// Matcher for failed API responses
  static Matcher isFailedApiResponse() {
    return predicate<Map<String, dynamic>>(
      (response) => response['success'] == false,
      'is a failed API response',
    );
  }
  
  /// Matcher for valid authentication tokens
  static Matcher isValidAuthToken() {
    return predicate<String>(
      (token) => token != null && token.isNotEmpty && token.length > 10,
      'is a valid authentication token',
    );
  }
  
  /// Matcher for valid email addresses
  static Matcher isValidEmail() {
    return predicate<String>(
      (email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email),
      'is a valid email address',
    );
  }
  
  /// Matcher for non-empty strings
  static Matcher isNonEmptyString() {
    return predicate<String>(
      (str) => str != null && str.isNotEmpty,
      'is a non-empty string',
    );
  }
  
  /// Matcher for positive numbers
  static Matcher isPositiveNumber() {
    return predicate<num>(
      (num) => num > 0,
      'is a positive number',
    );
  }
  
  /// Matcher for valid dates
  static Matcher isValidDate() {
    return predicate<DateTime>(
      (dateTime) => dateTime != null && dateTime.isAfter(DateTime(2000)),
      'is a valid date',
    );
  }
  
  /// Matcher for lists with minimum length
  static Matcher hasMinimumLength(int minLength) {
    return predicate<List>(
      (list) => list != null && list.length >= minLength,
      'has minimum length of $minLength',
    );
  }
  
  /// Matcher for valid file paths
  static Matcher isValidFilePath() {
    return predicate<String>(
      (path) => path != null && path.isNotEmpty && path.contains('.'),
      'is a valid file path',
    );
  }
  
  /// Matcher for URLs
  static Matcher isValidUrl() {
    return predicate<String>(
      (url) => Uri.tryParse(url)?.hasAbsolutePath == true,
      'is a valid URL',
    );
  }
}

/// Setup and teardown helpers
class TestSetup {
  /// Global setUp for all tests
  static void setUpAll() {
    // Initialize test configuration
    TestWidgetsFlutterBinding.ensureInitialized();
  }
  
  /// Global tearDown for all tests
  static void tearDownAll() {
    // Cleanup after all tests
  }
  
  /// Individual test setUp
  static void setUp() {
    // Reset mocks and state before each test
  }
  
  /// Individual test tearDown
  static void tearDown() {
    // Clean up after each test
  }
}