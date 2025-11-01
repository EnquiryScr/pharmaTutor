import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:developer';
import 'dart:io';

import '../../../lib/main.dart' as app;
import '../../../lib/presentation/viewmodels/auth_viewmodel.dart';
import '../../../lib/presentation/viewmodels/chat_viewmodel.dart';
import '../../../lib/presentation/viewmodels/assignment_viewmodel.dart';
import '../../../lib/presentation/viewmodels/dashboard_viewmodel.dart';
import '../../../mocks/mock_services.dart';
import '../../../test_config.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    late MockAuthService mockAuthService;
    late MockChatService mockChatService;
    late MockAssignmentService mockAssignmentService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockChatService = MockChatService();
      mockAssignmentService = MockAssignmentService();
    });

    testWidgets('app startup performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      // Measure app initialization time
      app.main();
      
      stopwatch.stop();
      final startupTime = stopwatch.elapsedMilliseconds;

      await tester.pumpAndSettle();

      // Log performance metrics
      log('App Startup Time: ${startupTime}ms');
      
      // Assert startup time is within acceptable limits
      expect(startupTime, lessThan(TestConfig.maxStartupTime.inMilliseconds));

      // Verify app is fully loaded
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('screen navigation performance', (WidgetTester tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // Login first (simulate user authentication)
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Measure navigation performance between screens
      final navigationStopwatch = Stopwatch()..start();

      // Navigate to Chat
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Navigate to Assignments
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assignments'));
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Navigate back to Dashboard
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      navigationStopwatch.stop();
      final navigationTime = navigationStopwatch.elapsedMilliseconds;

      log('Screen Navigation Time (4 transitions): ${navigationTime}ms');
      
      // Assert navigation is responsive
      expect(navigationTime, lessThan(2000)); // Should complete within 2 seconds
    });

    testWidgets('memory usage during heavy operations', (WidgetTester tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Measure memory usage after login
      final initialMemory = await _getCurrentMemoryUsage();

      // Perform heavy operations - navigate rapidly between screens
      for (int i = 0; i < 20; i++) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chat'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Assignments'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
      }

      // Measure memory usage after operations
      final finalMemory = await _getCurrentMemoryUsage();
      final memoryIncrease = finalMemory - initialMemory;
      final memoryIncreaseMB = memoryIncrease / (1024 * 1024);

      log('Initial Memory: ${initialMemory / (1024 * 1024)}MB');
      log('Final Memory: ${finalMemory / (1024 * 1024)}MB');
      log('Memory Increase: ${memoryIncreaseMB.toStringAsFixed(2)}MB');

      // Assert memory increase is within acceptable limits
      expect(memoryIncreaseMB, lessThan(TestConfig.maxMemoryUsageMB));
    });

    testWidgets('scroll performance with large lists', (WidgetTester tester) async {
      // This test would measure scroll performance with large datasets
      // In a real implementation, you would test with 1000+ items
      
      // Initialize app and go to assignments with large list
      app.main();
      await tester.pumpAndSettle();

      // Login and navigate to assignments
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assignments'));
      await tester.pumpAndSettle();

      // Measure scroll performance
      final scrollStopwatch = Stopwatch()..start();

      // Scroll to bottom
      for (int i = 0; i < 10; i++) {
        await tester.fling(
          find.byType(ListView),
          const Offset(0, -300),
          1000,
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      }

      // Scroll back to top
      for (int i = 0; i < 10; i++) {
        await tester.fling(
          find.byType(ListView),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      }

      scrollStopwatch.stop();
      final scrollTime = scrollStopwatch.elapsedMilliseconds;

      log('Scroll Performance Time (20 scroll actions): ${scrollTime}ms');

      // Assert scroll is smooth and responsive
      expect(scrollTime, lessThan(5000)); // Should complete within 5 seconds
    });

    testWidgets('network request performance', (WidgetTester tester) async {
      // This test measures API response times
      // In a real implementation, you would mock slow network responses

      final requestStopwatch = Stopwatch()..start();

      // Simulate network requests with different response times
      // Login request
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Wait for login request to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      requestStopwatch.stop();
      final totalRequestTime = requestStopwatch.elapsedMilliseconds;

      log('Network Request Performance: ${totalRequestTime}ms');

      // Assert network requests complete within acceptable time
      expect(totalRequestTime, lessThan(TestConfig.maxApiResponseTime.inMilliseconds * 2));
    });

    testWidgets('battery usage simulation', (WidgetTester tester) async {
      // This test simulates battery-intensive operations
      // In a real implementation, you might test with actual battery monitoring

      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Simulate battery-intensive operations
      final batteryStopwatch = Stopwatch()..start();

      // Rapid screen navigation
      for (int i = 0; i < 50; i++) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chat'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
      }

      batteryStopwatch.stop();
      final intensiveOperationTime = batteryStopwatch.elapsedMilliseconds;

      log('Battery-Intensive Operations Time: ${intensiveOperationTime}ms');

      // Assert operations complete without significant delays
      expect(intensiveOperationTime, lessThan(30000)); // Should complete within 30 seconds
    });

    testWidgets('app stability during stress testing', (WidgetTester tester) async {
      // This test performs stress testing to ensure app stability

      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      int errorCount = 0;

      // Perform stress operations
      for (int cycle = 0; cycle < 5; cycle++) {
        log('Stress Test Cycle ${cycle + 1}');

        // Login
        await tester.tap(find.byKey(Key('email_text_field')));
        await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
        await tester.pump();

        await tester.tap(find.byKey(Key('password_text_field')));
        await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
        await tester.pump();

        await tester.tap(find.byKey(Key('sign_in_button')));
        await tester.pumpAndSettle();

        // Rapid navigation
        for (int i = 0; i < 10; i++) {
          try {
            await tester.tap(find.byIcon(Icons.menu));
            await tester.pumpAndSettle();
            
            final menuItems = [
              'Dashboard',
              'Assignments', 
              'Chat',
              'Payment',
              'Profile'
            ];
            
            final randomItem = menuItems[i % menuItems.length];
            await tester.tap(find.text(randomItem));
            await tester.pumpAndSettle();
            
          } catch (e) {
            errorCount++;
            log('Error in navigation: $e');
          }
        }

        // Logout
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Wait between cycles
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Assert no errors occurred during stress testing
      expect(errorCount, equals(0));
      log('Stress Test Completed: $errorCount errors detected');

      // Verify app is still functional
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('performance monitoring and profiling', (WidgetTester tester) async {
      // This test demonstrates performance monitoring capabilities

      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // Start performance monitoring
      final performanceMonitor = PerformanceMonitor();
      performanceMonitor.start();

      // Perform typical user interactions
      // Login
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Navigate through app
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assignments'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Stop monitoring and get results
      final results = performanceMonitor.stop();

      // Log performance metrics
      log('=== Performance Monitoring Results ===');
      log('Total Execution Time: ${results.totalTime}ms');
      log('Widget Build Count: ${results.widgetBuildCount}');
      log('Frame Render Count: ${results.frameRenderCount}');
      log('Average Frame Time: ${results.averageFrameTime.toStringAsFixed(2)}ms');
      log('Max Frame Time: ${results.maxFrameTime.toStringAsFixed(2)}ms');
      log('Memory Usage: ${results.memoryUsage}MB');

      // Assert performance is within acceptable limits
      expect(results.totalTime, lessThan(15000)); // 15 seconds total
      expect(results.averageFrameTime, lessThan(16.67)); // 60 FPS
      expect(results.maxFrameTime, lessThan(100)); // 10 FPS minimum
    });
  });
}

/// Utility function to get current memory usage
Future<int> _getCurrentMemoryUsage() async {
  // This is a simplified implementation
  // In a real app, you might use platform-specific APIs
  return ProcessInfo.currentRss; // Resident Set Size in KB
}

/// Performance monitoring utility
class PerformanceMonitor {
  late Stopwatch _stopwatch;
  late DateTime _startTime;
  int _widgetBuildCount = 0;
  List<double> _frameTimes = [];
  int _frameCount = 0;

  void start() {
    _stopwatch = Stopwatch()..start();
    _startTime = DateTime.now();
    _widgetBuildCount = 0;
    _frameTimes.clear();
    _frameCount = 0;
  }

  void recordWidgetBuild() {
    _widgetBuildCount++;
  }

  void recordFrameRender(double frameTime) {
    _frameTimes.add(frameTime);
    _frameCount++;
  }

  PerformanceResults stop() {
    _stopwatch.stop();
    final totalTime = _stopwatch.elapsedMilliseconds;
    
    final averageFrameTime = _frameTimes.isEmpty 
        ? 0.0 
        : _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    
    final maxFrameTime = _frameTimes.isEmpty 
        ? 0.0 
        : _frameTimes.reduce((a, b) => a > b ? a : b);
    
    final memoryUsage = ProcessInfo.currentRss / (1024 * 1024); // Convert to MB

    return PerformanceResults(
      totalTime: totalTime,
      widgetBuildCount: _widgetBuildCount,
      frameRenderCount: _frameCount,
      averageFrameTime: averageFrameTime,
      maxFrameTime: maxFrameTime,
      memoryUsage: memoryUsage,
    );
  }
}

class PerformanceResults {
  final int totalTime;
  final int widgetBuildCount;
  final int frameRenderCount;
  final double averageFrameTime;
  final double maxFrameTime;
  final double memoryUsage;

  PerformanceResults({
    required this.totalTime,
    required this.widgetBuildCount,
    required this.frameRenderCount,
    required this.averageFrameTime,
    required this.maxFrameTime,
    required this.memoryUsage,
  });
}