import 'package:flutter_test/flutter_test.dart';
import 'test_config.dart';

/// Main test configuration for Flutter Tutoring Platform
/// 
/// This file sets up the global test environment and configuration
/// that applies to all tests in the suite.
void main() {
  // Global test configuration
  setUpAll(() {
    // Initialize test environment
    print('Initializing Flutter Tutoring Platform Test Suite');
    print('Test Environment: ${TestConfig.testEnvironment}');
    print('Platform: ${TestHelpers.getTestPlatform()}');
    print('CI Environment: ${TestHelpers.isCiEnvironment()}');
  });

  tearDownAll(() {
    print('Test Suite Completed');
  });

  // Example test to verify configuration
  group('Test Configuration', () {
    test('should have valid test configuration', () {
      expect(TestConfig.testEnvironment, equals('test'));
      expect(TestConfig.testUserEmail, isValidEmail());
      expect(TestConfig.defaultTimeout.inSeconds, greaterThan(0));
    });

    test('should have valid mock API configuration', () {
      expect(TestConfig.mockApiBaseUrl, isValidUrl());
      expect(TestConfig.mockFirebaseUrl, isValidUrl());
    });

    test('should have valid test data configuration', () {
      expect(TestConfig.testUserEmail, isNonEmptyString());
      expect(TestConfig.testUserPassword, isNonEmptyString());
      expect(TestConfig.testUserId, isNonEmptyString());
    });

    test('should have valid Firebase emulator configuration', () {
      expect(TestConfig.firebaseEmulatorHost, isNonEmptyString());
      expect(TestConfig.firebaseAuthPort, greaterThan(0));
      expect(TestConfig.firebaseFirestorePort, greaterThan(0));
    });

    test('should have valid performance thresholds', () {
      expect(TestConfig.maxMemoryUsageMB, greaterThan(0));
      expect(TestConfig.maxStartupTime.inMilliseconds, greaterThan(0));
      expect(TestConfig.maxApiResponseTime.inMilliseconds, greaterThan(0));
    });

    test('should have valid accessibility configuration', () {
      expect(TestConfig.minimumTouchTargetSize, greaterThan(0));
      expect(TestConfig.minimumFontSize, greaterThan(0));
      expect(TestConfig.minimumColorContrastRatio, greaterThan(0));
    });
  });

  // Test configuration validation
  group('Test Helpers', () {
    test('should return correct timeout based on test type', () {
      expect(TestHelpers.getTimeout('unit'), equals(TestConfig.defaultTimeout));
      expect(TestHelpers.getTimeout('widget'), equals(TestConfig.defaultTimeout));
      expect(TestHelpers.getTimeout('integration'), equals(TestConfig.longTimeout));
      expect(TestHelpers.getTimeout('performance'), equals(TestConfig.longTimeout));
      expect(TestHelpers.getTimeout('unknown'), equals(TestConfig.defaultTimeout));
    });

    test('should detect test environment correctly', () {
      // This should be true when running in test environment
      expect(TestHelpers.isTestEnvironment(), isTrue);
    });

    test('should have valid platform detection', () {
      final platform = TestHelpers.getTestPlatform();
      expect(platform, anyOf(equals('flutter'), equals('web')));
    });
  });

  // Custom matchers validation
  group('Custom Matchers', () {
    test('should validate successful API response', () {
      final response = NetworkTestConfig.mockSuccessResponse;
      expect(response, isSuccessfulApiResponse());
    });

    test('should validate failed API response', () {
      final response = NetworkTestConfig.mockErrorResponse;
      expect(response, isFailedApiResponse());
    });

    test('should validate email format', () {
      expect(TestConfig.testUserEmail, isValidEmail());
      expect('invalid-email', isNot(isValidEmail()));
      expect('test@', isNot(isValidEmail()));
      expect('@test.com', isNot(isValidEmail()));
    });

    test('should validate non-empty strings', () {
      expect(TestConfig.testUserEmail, isNonEmptyString());
      expect('', isNot(isNonEmptyString()));
      expect(null, isNot(isNonEmptyString()));
    });

    test('should validate positive numbers', () {
      expect(TestConfig.maxMemoryUsageMB, isPositiveNumber());
      expect(0, isNot(isPositiveNumber()));
      expect(-1, isNot(isPositiveNumber()));
    });

    test('should validate URLs', () {
      expect(TestConfig.mockApiBaseUrl, isValidUrl());
      expect(TestConfig.mockFirebaseUrl, isValidUrl());
      expect('invalid-url', isNot(isValidUrl()));
    });

    test('should validate file paths', () {
      expect('test/fixtures/test.json', isValidFilePath());
      expect('no-extension-file', isNot(isValidFilePath()));
    });

    test('should validate lists with minimum length', () {
      final list = [1, 2, 3];
      expect(list, hasMinimumLength(2));
      expect(list, isNot(hasMinimumLength(5)));
    });

    test('should validate dates', () {
      final date = DateTime.now();
      expect(date, isValidDate());
      expect(DateTime(1999), isNot(isValidDate()));
    });
  });

  // Network configuration validation
  group('Network Test Configuration', () {
    test('should have valid mock responses', () {
      final success = NetworkTestConfig.mockSuccessResponse;
      final error = NetworkTestConfig.mockErrorResponse;
      final validation = NetworkTestConfig.mockValidationError;

      expect(success['success'], isTrue);
      expect(success['data'], isNotNull);
      expect(success['timestamp'], isNotNull);

      expect(error['success'], isFalse);
      expect(error['error'], isNotNull);
      expect(error['timestamp'], isNotNull);

      expect(validation['success'], isFalse);
      expect(validation['error']['code'], isNotNull);
      expect(validation['error']['details'], isNotNull);
    });
  });

  // Payment configuration validation
  group('Payment Test Configuration', () {
    test('should have valid test payment data', () {
      expect(PaymentTestConfig.testCardNumber, hasLength(16));
      expect(PaymentTestConfig.testCardCvc, hasLength(3));
      expect(PaymentTestConfig.testCardExpiry, contains('/'));
      expect(PaymentTestConfig.testAmount, isPositiveNumber());
      expect(PaymentTestConfig.testCurrency, equals('USD'));
    });
  });

  // Chat configuration validation
  group('Chat Test Configuration', () {
    test('should have valid chat test data', () {
      expect(ChatTestConfig.testRoomId, isNonEmptyString());
      expect(ChatTestConfig.testMessage, isNonEmptyString());
      expect(ChatTestConfig.maxMessagesPerPage, greaterThan(0));
      expect(ChatTestConfig.messageTimeout.inSeconds, greaterThan(0));
    });
  });

  // Assignment configuration validation
  group('Assignment Test Configuration', () {
    test('should have valid assignment test data', () {
      expect(AssignmentTestConfig.testAssignmentId, isNonEmptyString());
      expect(AssignmentTestConfig.testAssignmentTitle, isNonEmptyString());
      expect(AssignmentTestConfig.testAssignmentDescription, isNonEmptyString());
      expect(AssignmentTestConfig.testAssignmentDuration.inHours, equals(2));
      expect(AssignmentTestConfig.maxAttachments, greaterThan(0));
      expect(AssignmentTestConfig.maxAttachmentSizeMB, greaterThan(0));
    });
  });

  // Authentication configuration validation
  group('Authentication Test Configuration', () {
    test('should have valid auth test data', () {
      expect(AuthTestConfig.tokenExpiry.inHours, equals(1));
      expect(AuthTestConfig.refreshTokenExpiry.inDays, equals(30));
      expect(AuthTestConfig.maxLoginAttempts, greaterThan(0));
      expect(AuthTestConfig.lockoutDuration.inMinutes, greaterThan(0));
    });
  });

  // File upload configuration validation
  group('File Upload Test Configuration', () {
    test('should have valid file upload test data', () {
      expect(FileUploadTestConfig.allowedImageTypes, isNotEmpty);
      expect(FileUploadTestConfig.allowedDocumentTypes, isNotEmpty);
      expect(FileUploadTestConfig.maxFileSizeMB, greaterThan(0));
      expect(FileUploadTestConfig.allowedImageDimensions, hasLength(2));
    });
  });

  // Performance configuration validation
  group('Performance Test Configuration', () {
    test('should have valid performance test data', () {
      expect(PerformanceTestConfig.iterationsForMemoryTest, greaterThan(0));
      expect(PerformanceTestConfig.memoryTestDuration.inSeconds, greaterThan(0));
      expect(PerformanceTestConfig.maxConcurrentOperations, greaterThan(0));
      expect(PerformanceTestConfig.maxMemoryLeakPercentage, greaterThan(0));
    });
  });

  // Accessibility configuration validation
  group('Accessibility Test Configuration', () {
    test('should have valid accessibility test data', () {
      expect(AccessibilityTestConfig.requiredAccessibilityLabels, isNotEmpty);
      expect(AccessibilityTestConfig.minimumTouchTargets, isNotEmpty);
      expect(AccessibilityTestConfig.minimumColorContrast, isNotEmpty);
      
      // Verify minimum touch targets
      expect(AccessibilityTestConfig.minimumTouchTargets['small'], greaterThan(0));
      expect(AccessibilityTestConfig.minimumTouchTargets['medium'], greaterThan(0));
      expect(AccessibilityTestConfig.minimumTouchTargets['large'], greaterThan(0));
      
      // Verify minimum color contrast
      expect(AccessibilityTestConfig.minimumColorContrast['normal'], greaterThan(0));
      expect(AccessibilityTestConfig.minimumColorContrast['large'], greaterThan(0));
    });
  });
}