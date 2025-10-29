import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../lib/main.dart' as app;
import '../../../lib/presentation/viewmodels/auth_viewmodel.dart';
import '../../../lib/presentation/viewmodels/dashboard_viewmodel.dart';
import '../../../lib/presentation/viewmodels/chat_viewmodel.dart';
import '../../../lib/presentation/viewmodels/payment_viewmodel.dart';
import '../../../lib/presentation/viewmodels/assignment_viewmodel.dart';
import '../../../lib/data/services/auth_service.dart';
import '../../../lib/data/services/chat_service.dart';
import '../../../lib/data/services/payment_service.dart';
import '../../../lib/data/services/assignment_service.dart';
import '../../../mocks/mock_services.dart';
import '../../../mocks/mock_viewmodels.dart';
import '../../../fixtures/auth_fixtures.dart';
import '../../../fixtures/chat_fixtures.dart';
import '../../../fixtures/payment_fixtures.dart';
import '../../../fixtures/assignment_fixtures.dart';
import '../../../test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Authentication Flow Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockChatService mockChatService;
    late MockPaymentService mockPaymentService;
    late MockAssignmentService mockAssignmentService;

    setUp(() {
      // Initialize mock services
      mockAuthService = MockAuthService();
      mockChatService = MockChatService();
      mockPaymentService = MockPaymentService();
      mockAssignmentService = MockAssignmentService();
      
      // Configure app with mock services for testing
      app.AppConfig.testMode = true;
    });

    tearDown(() {
      app.AppConfig.testMode = false;
    });

    testWidgets('complete user journey: register -> login -> dashboard -> logout', 
        (WidgetTester tester) async {
      
      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // === STEP 1: Navigate to Registration ===
      // Tap on "Sign Up" link from login screen
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify registration screen is displayed
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // === STEP 2: Fill Registration Form ===
      // Enter first name
      await tester.tap(find.byKey(Key('first_name_text_field')));
      await tester.enterText(find.byKey(Key('first_name_text_field')), 'John');
      await tester.pump();

      // Enter last name
      await tester.tap(find.byKey(Key('last_name_text_field')));
      await tester.enterText(find.byKey(Key('last_name_text_field')), 'Doe');
      await tester.pump();

      // Enter email
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'john.doe@example.com');
      await tester.pump();

      // Enter password
      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'SecurePassword123!');
      await tester.pump();

      // Confirm password
      await tester.tap(find.byKey(Key('confirm_password_text_field')));
      await tester.enterText(find.byKey(Key('confirm_password_text_field')), 'SecurePassword123!');
      await tester.pump();

      // === STEP 3: Submit Registration ===
      // Tap "Create Account" button
      await tester.tap(find.byKey(Key('create_account_button')));
      await tester.pumpAndSettle();

      // Verify registration success (should show confirmation or redirect)
      expect(find.text('Registration Successful'), findsOneWidget);
      expect(find.text('Please check your email to verify your account'), findsOneWidget);

      // === STEP 4: Navigate to Login ===
      // Tap "Sign In" button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // === STEP 5: Login ===
      // Enter email
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'john.doe@example.com');
      await tester.pump();

      // Enter password
      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'SecurePassword123!');
      await tester.pump();

      // Tap "Sign In" button
      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Wait for loading state to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // === STEP 6: Verify Dashboard Access ===
      // Verify user is redirected to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Welcome, John Doe'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Upcoming Sessions'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);

      // Verify navigation drawer is accessible
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // === STEP 7: Navigate to Different Sections ===
      // Navigate to Assignments
      await tester.tap(find.text('Assignments'));
      await tester.pumpAndSettle();
      
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Create Assignment'), findsOneWidget);
      expect(find.text('Assignment List'), findsOneWidget);

      // Navigate to Chat
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Start a Conversation'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets); // Message input field

      // Navigate to Payment
      await tester.tap(find.text('Payment'));
      await tester.pumpAndSettle();
      
      expect(find.text('Payment History'), findsOneWidget);
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Subscribe'), findsOneWidget);

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      // === STEP 8: Return to Dashboard ===
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Welcome, John Doe'), findsOneWidget);

      // === STEP 9: Logout ===
      // Open navigation drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      
      // Tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // === STEP 10: Verify Logout ===
      // Verify user is redirected back to login screen
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byKey(Key('email_text_field')), findsOneWidget);
      expect(find.byKey(Key('password_text_field')), findsOneWidget);

      // Verify email field is cleared
      expect(find.text('john.doe@example.com'), findsNothing);

      // Verify user cannot access dashboard without authentication
      // Try to navigate to dashboard manually
      final dashboardFinder = find.text('Dashboard');
      expect(dashboardFinder, findsNothing);

    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('failed login flow and error handling', 
        (WidgetTester tester) async {
      
      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // Try to login with invalid credentials
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'invalid@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'wrongpassword');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Verify form is not cleared
      expect(find.text('invalid@example.com'), findsOneWidget);

      // Verify user stays on login screen
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byKey(Key('email_text_field')), findsOneWidget);

      // === Test Forgot Password Flow ===
      // Tap "Forgot Password" link
      await tester.tap(find.byKey(Key('forgot_password_link')));
      await tester.pumpAndSettle();

      // Verify forgot password screen
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);

      // Enter email for password reset
      await tester.tap(find.byKey(Key('reset_email_text_field')));
      await tester.enterText(find.byKey(Key('reset_email_text_field')), 'invalid@example.com');
      await tester.pump();

      // Tap "Send Reset Link"
      await tester.tap(find.byKey(Key('send_reset_button')));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Reset link sent! Check your email.'), findsOneWidget);

      // Return to login
      await tester.tap(find.text('Back to Sign In'));
      await tester.pumpAndSettle();

      // Verify back on login screen
      expect(find.text('Sign In'), findsOneWidget);

    }, timeout: const Timeout(Duration(minutes: 1)));

    testWidgets('profile update flow after login', 
        (WidgetTester tester) async {
      
      // Initialize app with logged-in state
      app.main();
      await tester.pumpAndSettle();

      // Simulate successful login (this would be done via mock or test setup)
      // For integration test, we'll assume user is already logged in
      // In a real test, you might use a test account or mock the login process

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify profile screen
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);

      // Tap "Edit Profile"
      await tester.tap(find.byKey(Key('edit_profile_button')));
      await tester.pumpAndSettle();

      // Verify edit mode
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byKey(Key('first_name_text_field')), findsOneWidget);
      expect(find.byKey(Key('last_name_text_field')), findsOneWidget);
      expect(find.byKey(Key('profile_save_button')), findsOneWidget);

      // Update profile information
      await tester.tap(find.byKey(Key('first_name_text_field')));
      await tester.clearText(find.byKey(Key('first_name_text_field')));
      await tester.enterText(find.byKey(Key('first_name_text_field')), 'Jane');
      await tester.pump();

      await tester.tap(find.byKey(Key('last_name_text_field')));
      await tester.clearText(find.byKey(Key('last_name_text_field')));
      await tester.enterText(find.byKey(Key('last_name_text_field')), 'Smith');
      await tester.pump();

      // Save changes
      await tester.tap(find.byKey(Key('profile_save_button')));
      await tester.pumpAndSettle();

      // Verify update success
      expect(find.text('Profile updated successfully'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);

      // Return to view mode
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify profile shows updated information
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget); // Email unchanged

    }, timeout: const Timeout(Duration(minutes: 1)));

    testWidgets('session management and auto-logout', 
        (WidgetTester tester) async {
      
      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // Simulate login
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Verify dashboard access
      expect(find.text('Dashboard'), findsOneWidget);

      // === Test Session Timeout Simulation ===
      // Wait for session to expire (in real test, this would be based on actual timeout)
      // For testing, we'll simulate session expiry
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Simulate 61 seconds

      // Attempt to access protected resource after session expiry
      // In a real app, this would trigger authentication check
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify user is redirected to login due to session expiry
      expect(find.text('Session expired. Please login again.'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('navigation flow between different app sections', 
        (WidgetTester tester) async {
      
      // Initialize app and login
      app.main();
      await tester.pumpAndSettle();

      // Quick login simulation
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // === Test Navigation Flow ===
      // Start from Dashboard
      expect(find.text('Dashboard'), findsOneWidget);

      // Navigate to Chat
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      
      expect(find.text('Chat'), findsOneWidget);
      
      // Send a message from chat
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Hello, I need help with math');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Verify message was sent
      expect(find.text('Hello, I need help with math'), findsOneWidget);

      // Navigate to Assignments
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assignments'));
      await tester.pumpAndSettle();
      
      expect(find.text('Assignments'), findsOneWidget);
      
      // Create a new assignment
      await tester.tap(find.text('Create Assignment'));
      await tester.pumpAndSettle();
      
      expect(find.text('Create New Assignment'), findsOneWidget);
      
      // Fill assignment form
      await tester.tap(find.byKey(Key('assignment_title_field')));
      await tester.enterText(find.byKey(Key('assignment_title_field')), 'Math Quiz 1');
      await tester.pump();

      await tester.tap(find.byKey(Key('assignment_description_field')));
      await tester.enterText(find.byKey(Key('assignment_description_field')), 'Complete the following math problems');
      await tester.pump();

      await tester.tap(find.byKey(Key('create_assignment_button')));
      await tester.pumpAndSettle();

      // Verify assignment was created
      expect(find.text('Assignment created successfully'), findsOneWidget);
      expect(find.text('Math Quiz 1'), findsOneWidget);

      // Navigate to Payment
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment'));
      await tester.pumpAndSettle();
      
      expect(find.text('Payment History'), findsOneWidget);
      
      // Navigate to Profile
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      
      expect(find.text('Profile'), findsOneWidget);

      // Return to Dashboard
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      
      expect(find.text('Dashboard'), findsOneWidget);

    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('error handling and recovery flow', 
        (WidgetTester tester) async {
      
      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // === Test Network Error Handling ===
      // Attempt login with network issues
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'test@example.com');
      await tester.pump();

      await tester.tap(find.byKey(Key('password_text_field')));
      await tester.enterText(find.byKey(Key('password_text_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Simulate network error (in real test, this would be controlled via mock)
      // For this test, we'll assume the error is handled gracefully
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify error handling UI
      expect(find.text('Connection error. Please try again.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Test retry functionality
      await tester.tap(find.byKey(Key('retry_button')));
      await tester.pumpAndSettle();

      // Verify we're back to login form
      expect(find.byKey(Key('email_text_field')), findsOneWidget);
      expect(find.byKey(Key('password_text_field')), findsOneWidget);

      // === Test Validation Errors ===
      // Try to login with empty fields
      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pump();

      // Verify validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Enter invalid email
      await tester.tap(find.byKey(Key('email_text_field')));
      await tester.enterText(find.byKey(Key('email_text_field')), 'invalid-email');
      await tester.pump();

      await tester.tap(find.byKey(Key('sign_in_button')));
      await tester.pump();

      // Verify email validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);

    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}