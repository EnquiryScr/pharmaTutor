import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../test_config.dart';
import '../fixtures/auth_fixtures.dart';
import '../fixtures/chat_fixtures.dart';
import '../fixtures/payment_fixtures.dart';
import '../fixtures/assignment_fixtures.dart';

/// Common test helpers and utilities
class TestHelpers {
  /// Wait for a specific duration in tests
  static Future<void> waitFor(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Wait for a condition to become true
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return;
      }
      await Future.delayed(interval);
    }
    
    throw TimeoutException('Condition not met within timeout', timeout);
  }

  /// Wait for a specific number of frames
  static Future<void> pumpAndSettle(WidgetTester tester, [int max Pumps = 30]) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Create a test widget with common providers
  static Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Create a test widget with theme
  static Widget createTestWidgetWithTheme(Widget child, ThemeData theme) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Create a mock response for testing
  static Map<String, dynamic> createMockResponse({
    bool success = true,
    dynamic data,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? errorDetails,
  }) {
    if (success) {
      return {
        'success': true,
        'data': data ?? {'message': 'Success'},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      return {
        'success': false,
        'error': {
          'code': errorCode ?? 'TEST_ERROR',
          'message': errorMessage ?? 'Test error',
          ...?errorDetails,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Create test user data
  static Map<String, dynamic> createTestUser({
    String? id,
    String? email,
    String? role,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'id': id ?? 'test-user-123',
      'email': email ?? 'test@example.com',
      'firstName': 'Test',
      'lastName': 'User',
      'role': role ?? 'student',
      'createdAt': DateTime.now().toIso8601String(),
      'lastLoginAt': DateTime.now().toIso8601String(),
      'isEmailVerified': true,
      'isActive': true,
      ...?additionalData,
    };
  }

  /// Create test assignment data
  static Map<String, dynamic> createTestAssignment({
    String? id,
    String? title,
    String? subject,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'id': id ?? 'test-assignment-123',
      'title': title ?? 'Test Assignment',
      'description': 'This is a test assignment description',
      'subject': subject ?? 'Mathematics',
      'topic': 'General',
      'difficulty': 'beginner',
      'estimatedDuration': 60,
      'totalPoints': 100,
      'createdBy': 'tutor-456',
      'createdAt': DateTime.now().toIso8601String(),
      'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'status': 'active',
      'questions': [],
      'attachments': [],
      'tags': ['test'],
      'isPublic': false,
      'maxAttempts': 3,
      'timeLimit': 120,
      ...?additionalData,
    };
  }

  /// Create test chat message
  static Map<String, dynamic> createTestMessage({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'test-message-123',
      'roomId': roomId ?? 'test-room-123',
      'senderId': senderId ?? 'test-user-123',
      'senderName': 'Test User',
      'senderRole': 'student',
      'type': type ?? 'text',
      'content': content ?? 'Test message',
      'timestamp': DateTime.now().toIso8601String(),
      'isEdited': false,
      'isDeleted': false,
      'replyTo': null,
      'reactions': [],
      'readBy': [],
      'deliveryStatus': 'delivered',
      ...?metadata,
    };
  }

  /// Create test payment transaction
  static Map<String, dynamic> createTestTransaction({
    String? id,
    String? userId,
    double? amount,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'test-transaction-123',
      'userId': userId ?? 'test-user-123',
      'amount': amount ?? 99.99,
      'currency': 'USD',
      'status': status ?? 'completed',
      'paymentMethod': {
        'type': 'card',
        'card': {
          'brand': 'visa',
          'last4': '4242',
          'expMonth': 12,
          'expYear': 2025,
        },
      },
      'description': 'Test payment',
      'createdAt': DateTime.now().toIso8601String(),
      'completedAt': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
      'fees': {
        'platformFee': 2.99,
        'processingFee': 1.50,
      },
      'refundStatus': null,
    };
  }

  /// Create test file data
  static Map<String, dynamic> createTestFile({
    String? id,
    String? filename,
    String? type,
    int? size,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'test-file-123',
      'filename': filename ?? 'test-file.pdf',
      'url': 'https://example.com/files/test-file.pdf',
      'size': size ?? 1024000,
      'type': type ?? 'pdf',
      'uploadedAt': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  /// Generate a unique test ID
  static String generateTestId([String prefix = 'test']) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }

  /// Create a timeout exception
  static TimeoutException createTimeoutException([String message = 'Operation timed out']) {
    return TimeoutException(message, const Duration(seconds: 30));
  }

  /// Mock a successful API response
  static void mockSuccessfulApiCall(Mock mock, [dynamic returnValue]) {
    when(mock).thenReturn(returnValue ?? {
      'success': true,
      'data': {'message': 'Success'},
    });
  }

  /// Mock a failed API response
  static void mockFailedApiCall(Mock mock, [String errorCode = 'TEST_ERROR']) {
    when(mock).thenReturn({
      'success': false,
      'error': {'code': errorCode, 'message': 'Test error'},
    });
  }

  /// Create a test exception
  static Exception createTestException([String message = 'Test exception']) {
    return Exception(message);
  }

  /// Compare JSON objects for equality
  static bool jsonEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      
      final aValue = a[key];
      final bValue = b[key];
      
      if (aValue is Map && bValue is Map) {
        if (!jsonEquals(aValue, bValue)) return false;
      } else if (aValue is List && bValue is List) {
        if (!listEquals(aValue, bValue)) return false;
      } else if (aValue != bValue) {
        return false;
      }
    }
    
    return true;
  }

  /// Compare lists for equality
  static bool listEquals(List? a, List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      final aValue = a[i];
      final bValue = b[i];
      
      if (aValue is Map && bValue is Map) {
        if (!jsonEquals(aValue, bValue)) return false;
      } else if (aValue is List && bValue is List) {
        if (!listEquals(aValue, bValue)) return false;
      } else if (aValue != bValue) {
        return false;
      }
    }
    
    return true;
  }

  /// Format test data for logging
  static String formatTestData(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return data.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
      } else if (data is List) {
        return data.join(', ');
      } else {
        return data.toString();
      }
    } catch (e) {
      return 'Error formatting test data: $e';
    }
  }

  /// Extract specific field from test data
  static T? getTestDataField<T>(Map<String, dynamic> data, String field) {
    try {
      final value = data[field];
      if (value is T) {
        return value;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create test dataset for bulk operations
  static List<Map<String, dynamic>> createTestDataset({
    int count = 10,
    String type = 'user',
    Map<String, dynamic>? baseData,
  }) {
    final List<Map<String, dynamic>> dataset = [];
    
    for (int i = 0; i < count; i++) {
      final item = {
        'id': '${type}-${i + 1}',
        'index': i,
        'createdAt': DateTime.now().subtract(Duration(days: i)).toIso8601String(),
        ...?baseData,
      };
      dataset.add(item);
    }
    
    return dataset;
  }

  /// Simulate network delay for testing
  static Future<void> simulateNetworkDelay([
    Duration duration = const Duration(milliseconds: 500),
  ]) async {
    await Future.delayed(duration);
  }

  /// Simulate slow device performance
  static Future<void> simulateSlowDevice() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Create a test builder function
  static Widget Function() createTestWidgetBuilder(Widget child) {
    return () => createTestWidget(child);
  }

  /// Validate test configuration
  static void validateTestConfig() {
    assert(
      TestConfig.testEnvironment.isNotEmpty,
      'Test environment should not be empty',
    );
    assert(
      TestConfig.defaultTimeout.inSeconds > 0,
      'Default timeout should be positive',
    );
    assert(
      TestConfig.testUserEmail.isNotEmpty,
      'Test user email should not be empty',
    );
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for successful API responses
  static Matcher isSuccessfulApiResponse() {
    return predicate<Map<String, dynamic>>(
      (response) => response['success'] == true && response.containsKey('data'),
      'is a successful API response with data',
    );
  }

  /// Matcher for failed API responses
  static Matcher isFailedApiResponse() {
    return predicate<Map<String, dynamic>>(
      (response) => response['success'] == false && response.containsKey('error'),
      'is a failed API response with error',
    );
  }

  /// Matcher for authentication tokens
  static Matcher isValidAuthToken() {
    return predicate<String>(
      (token) => token != null && token.isNotEmpty && token.length > 10,
      'is a valid authentication token',
    );
  }

  /// Matcher for valid email addresses
  static Matcher isValidEmail() {
    return predicate<String>(
      (email) => TestHelpers.isValidEmail(email),
      'is a valid email address',
    );
  }

  /// Matcher for strong passwords
  static Matcher isStrongPassword() {
    return predicate<String>(
      (password) => TestHelpers.isStrongPassword(password),
      'is a strong password',
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
      'is a valid date after year 2000',
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
      (url) => TestHelpers.isValidUrl(url),
      'is a valid URL',
    );
  }

  /// Matcher for ViewState.loading
  static Matcher isLoadingState() {
    return predicate<dynamic>(
      (state) => state.toString().contains('loading'),
      'is in loading state',
    );
  }

  /// Matcher for ViewState.error
  static Matcher isErrorState() {
    return predicate<dynamic>(
      (state) => state.toString().contains('error'),
      'is in error state',
    );
  }

  /// Matcher for ViewState.loaded
  static Matcher isLoadedState() {
    return predicate<dynamic>(
      (state) => state.toString().contains('loaded'),
      'is in loaded state',
    );
  }

  /// Matcher for valid timestamps
  static Matcher isValidTimestamp() {
    return predicate<String>(
      (timestamp) {
        try {
          DateTime.parse(timestamp);
          return true;
        } catch (e) {
          return false;
        }
      },
      'is a valid ISO8601 timestamp',
    );
  }

  /// Matcher for JSON objects
  static Matcher isValidJson() {
    return predicate<dynamic>(
      (obj) => obj is Map<String, dynamic> || obj is List,
      'is valid JSON (Map or List)',
    );
  }
}

/// Test data generators
class TestDataGenerators {
  /// Generate random test users
  static List<Map<String, dynamic>> generateTestUsers([int count = 10]) {
    return List.generate(count, (index) => TestHelpers.createTestUser(
      id: 'user-${index + 1}',
      email: 'user${index + 1}@test.com',
      role: index % 3 == 0 ? 'tutor' : 'student',
    ));
  }

  /// Generate random test assignments
  static List<Map<String, dynamic>> generateTestAssignments([int count = 5]) {
    const subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'];
    const difficulties = ['beginner', 'intermediate', 'advanced'];
    
    return List.generate(count, (index) => TestHelpers.createTestAssignment(
      id: 'assignment-${index + 1}',
      title: 'Test Assignment ${index + 1}',
      subject: subjects[index % subjects.length],
      additionalData: {
        'difficulty': difficulties[index % difficulties.length],
        'createdBy': 'tutor-${(index % 3) + 1}',
      },
    ));
  }

  /// Generate random test messages
  static List<Map<String, dynamic>> generateTestMessages([int count = 20]) {
    const contents = [
      'Hello!',
      'How can I help you today?',
      'That\'s a great question.',
      'Let me explain that concept.',
      'Do you understand now?',
      'Here\'s what we need to do next.',
      'That\'s correct!',
      'Good work on that problem.',
      'Let me show you another way.',
      'I think you\'re ready for the next topic.',
    ];
    
    return List.generate(count, (index) => TestHelpers.createTestMessage(
      id: 'msg-${index + 1}',
      content: contents[index % contents.length],
      senderId: index % 2 == 0 ? 'student-123' : 'tutor-456',
      roomId: 'room-123',
      type: index % 5 == 0 ? 'file' : 'text',
    ));
  }

  /// Generate random test transactions
  static List<Map<String, dynamic>> generateTestTransactions([int count = 10]) {
    const statuses = ['completed', 'pending', 'failed', 'refunded'];
    
    return List.generate(count, (index) => TestHelpers.createTestTransaction(
      id: 'txn-${index + 1}',
      amount: 50.0 + (index * 25.0),
      status: statuses[index % statuses.length],
    ));
  }
}

/// Performance testing helpers
class PerformanceHelpers {
  /// Measure execution time
  static Future<T> measureExecutionTime<T>(Future<T> Function() action) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      print('Execution time: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('Execution failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Measure memory usage
  static int measureMemoryUsage() {
    // This is a simplified implementation
    // In a real test environment, you might use more sophisticated memory profiling
    return 1024 * 1024; // 1MB placeholder
  }

  /// Test memory leak
  static Future<bool> testMemoryLeak({
    int iterations = 100,
    int thresholdMB = 5,
  }) async {
    final initialMemory = measureMemoryUsage();
    
    for (int i = 0; i < iterations; i++) {
      // Simulate memory allocation
      await TestHelpers.waitFor(const Duration(milliseconds: 10));
    }
    
    final finalMemory = measureMemoryUsage();
    final memoryIncrease = (finalMemory - initialMemory) ~/ (1024 * 1024);
    
    return memoryIncrease <= thresholdMB;
  }
}

/// Timeout exception for tests
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}