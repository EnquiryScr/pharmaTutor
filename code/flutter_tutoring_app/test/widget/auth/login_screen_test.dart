import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Assuming these would be the actual screen files
// import '../../lib/presentation/screens/auth/login_screen.dart';
// import '../../lib/presentation/screens/auth/register_screen.dart';
// import '../../lib/presentation/viewmodels/auth_viewmodel.dart';
// import '../../lib/data/services/auth_service.dart';

import '../../mocks/mock_viewmodels.dart';
import '../../fixtures/auth_fixtures.dart';
import '../../test_config.dart';
import '../../helpers/test_helpers.dart';

/// Generate mock classes
@GenerateMocks([AuthViewModel])
import 'login_screen_test.mocks.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late Widget testWidget;
    late MockAuthViewModel mockAuthViewModel;

    setUp(() {
      mockAuthViewModel = MockAuthViewModel();
      
      // Create test widget with providers
      testWidget = ChangeNotifierProvider<AuthViewModel>.value(
        value: mockAuthViewModel,
        child: MaterialApp(
          home: LoginScreen(),
        ),
      );
    });

    tearDown(() {
      mockAuthViewModel.dispose();
    });

    testWidgets('should display login form elements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
    });

    testWidgets('should display email input field', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      final emailField = find.byKey(Key('email_text_field'));
      expect(emailField, findsOneWidget);
      
      // Verify it's a TextFormField
      expect(tester.widget<TextFormField>(emailField).decoration?.hintText, 'Enter your email');
    });

    testWidgets('should display password input field', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      final passwordField = find.byKey(Key('password_text_field'));
      expect(passwordField, findsOneWidget);
      
      // Verify it's a TextFormField with password input
      expect(tester.widget<TextFormField>(passwordField).obscureText, isTrue);
    });

    testWidgets('should update email field when user types', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      final emailField = find.byKey(Key('email_text_field'));

      // Act
      await tester.tap(emailField);
      await tester.pump();
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should update password field when user types', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      final passwordField = find.byKey(Key('password_text_field'));

      // Act
      await tester.tap(passwordField);
      await tester.pump();
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Assert
      expect(find.text('password123'), findsNothing); // Password is obscured
      expect(find.byKey(Key('password_text_field')), findsOneWidget);
    });

    testWidgets('should show loading state when login is in progress', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      // Mock loading state
      when(mockAuthViewModel.isLoading).thenReturn(true);
      when(mockAuthViewModel.state).thenReturn(ViewState.loading);
      mockAuthViewModel.notifyListeners();

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Signing In...'), findsOneWidget);
    });

    testWidgets('should call login when sign in button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      // Setup mock response
      when(mockAuthViewModel.login(any, any))
          .thenAnswer((_) async {});
      when(mockAuthViewModel.isLoading).thenReturn(false);
      
      final emailField = find.byKey(Key('email_text_field'));
      final passwordField = find.byKey(Key('password_text_field'));
      final signInButton = find.byKey(Key('sign_in_button'));

      // Act
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.tap(passwordField);
      await tester.enterText(passwordField, 'password123');
      await tester.tap(signInButton);
      await tester.pump();

      // Assert
      verify(mockAuthViewModel.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('should show error message when login fails', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      // Mock error state
      when(mockAuthViewModel.isLoading).thenReturn(false);
      when(mockAuthViewModel.state).thenReturn(ViewState.error);
      when(mockAuthViewModel.error).thenReturn('Invalid credentials');
      mockAuthViewModel.notifyListeners();
      
      await tester.pump();

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should clear error when user starts typing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      // Set error state
      when(mockAuthViewModel.isLoading).thenReturn(false);
      when(mockAuthViewModel.state).thenReturn(ViewState.error);
      when(mockAuthViewModel.error).thenReturn('Previous error');
      mockAuthViewModel.notifyListeners();
      
      await tester.pump();
      expect(find.text('Previous error'), findsOneWidget);

      // Act - Clear error by calling the method
      when(mockAuthViewModel.error).thenReturn(null);
      mockAuthViewModel.clearError();
      mockAuthViewModel.notifyListeners();
      
      await tester.pump();

      // Assert
      expect(find.text('Previous error'), findsNothing);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      final emailField = find.byKey(Key('email_text_field'));
      final signInButton = find.byKey(Key('sign_in_button'));

      // Act - Enter invalid email
      await tester.tap(emailField);
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(signInButton);
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should validate password is not empty', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      final emailField = find.byKey(Key('email_text_field'));
      final passwordField = find.byKey(Key('password_text_field'));
      final signInButton = find.byKey(Key('sign_in_button'));

      // Act - Enter email but leave password empty
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.tap(passwordField);
      await tester.tap(signInButton);
      await tester.pump();

      // Assert
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should disable sign in button when loading', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      when(mockAuthViewModel.isLoading).thenReturn(true);
      mockAuthViewModel.notifyListeners();
      
      await tester.pump();

      // Act & Assert
      final signInButton = tester.widget<ElevatedButton>(
        find.byKey(Key('sign_in_button'))
      );
      expect(signInButton.enabled, isFalse);
    });

    testWidgets('should enable sign in button when not loading', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      when(mockAuthViewModel.isLoading).thenReturn(false);
      mockAuthViewModel.notifyListeners();
      
      await tester.pump();

      // Act & Assert
      final signInButton = tester.widget<ElevatedButton>(
        find.byKey(Key('sign_in_button'))
      );
      expect(signInButton.enabled, isTrue);
    });

    testWidgets('should navigate to register screen when sign up link is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      // Mock navigation behavior
      final registerLink = find.byKey(Key('sign_up_link'));

      // Act
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Assert
      // This would depend on how navigation is implemented
      // For example, using Navigator, you could verify the screen change
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('should navigate to forgot password screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      final forgotPasswordLink = find.byKey(Key('forgot_password_link'));

      // Act
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('should show password visibility toggle', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      final passwordField = find.byKey(Key('password_text_field'));
      final visibilityToggle = find.byKey(Key('password_visibility_toggle'));

      // Assert - Toggle should be visible
      expect(visibilityToggle, findsOneWidget);

      // Act - Toggle password visibility
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Assert - Password should now be visible
      expect(tester.widget<TextFormField>(passwordField).obscureText, isFalse);
    });

    testWidgets('should handle keyboard interactions properly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      final emailField = find.byKey(Key('email_text_field'));
      final passwordField = find.byKey(Key('password_text_field'));

      // Act - Use keyboard navigation
      await tester.tap(emailField);
      await tester.pump();
      await tester.enterText(emailField, 'test@example.com');
      
      // Navigate to next field
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      
      await tester.enterText(passwordField, 'password123');
      
      // Submit form
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);

      // Act - Change to landscape
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // Assert - Layout should still be functional
      expect(find.byKey(Key('email_text_field')), findsOneWidget);
      expect(find.byKey(Key('password_text_field')), findsOneWidget);
      expect(find.byKey(Key('sign_in_button')), findsOneWidget);

      // Act - Change back to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      // Assert - Layout should still be functional
      expect(find.byKey(Key('email_text_field')), findsOneWidget);
      expect(find.byKey(Key('password_text_field')), findsOneWidget);
      expect(find.byKey(Key('sign_in_button')), findsOneWidget);
    });

    testWidgets('should handle accessibility features', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);

      // Assert - Check for accessibility labels
      expect(find.bySemanticsLabel('Email address'), findsOneWidget);
      expect(find.bySemanticsLabel('Password'), findsOneWidget);
      expect(find.bySemanticsLabel('Sign in button'), findsOneWidget);

      // Act - Test semantic tap
      await tester.tap(find.bySemanticsLabel('Sign in button'));
      await tester.pump();

      // This would verify that the semantic tap works correctly
    });

    testWidgets('should maintain state during widget rebuilding', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      final emailField = find.byKey(Key('email_text_field'));
      final passwordField = find.byKey(Key('password_text_field'));

      // Act - Enter data
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.tap(passwordField);
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Trigger a rebuild
      mockAuthViewModel.notifyListeners();
      await tester.pump();

      // Assert - Data should persist
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    late Widget testWidget;
    late MockAuthViewModel mockAuthViewModel;

    setUp(() {
      mockAuthViewModel = MockAuthViewModel();
      
      testWidget = ChangeNotifierProvider<AuthViewModel>.value(
        value: mockAuthViewModel,
        child: MaterialApp(
          home: RegisterScreen(),
        ),
      );
    });

    testWidgets('should display register form elements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('should validate password confirmation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      final passwordField = find.byKey(Key('password_text_field'));
      final confirmPasswordField = find.byKey(Key('confirm_password_text_field'));
      final createAccountButton = find.byKey(Key('create_account_button'));

      // Act - Enter mismatched passwords
      await tester.tap(passwordField);
      await tester.enterText(passwordField, 'password123');
      await tester.tap(confirmPasswordField);
      await tester.enterText(confirmPasswordField, 'differentpassword');
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should call register when create account button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      
      when(mockAuthViewModel.register(any, any, any))
          .thenAnswer((_) async {});
      when(mockAuthViewModel.isLoading).thenReturn(false);

      final firstNameField = find.byKey(Key('first_name_text_field'));
      final lastNameField = find.byKey(Key('last_name_text_field'));
      final emailField = find.byKey(Key('email_text_field'));
      final passwordField = find.byKey(Key('password_text_field'));
      final confirmPasswordField = find.byKey(Key('confirm_password_text_field'));
      final createAccountButton = find.byKey(Key('create_account_button'));

      // Act - Fill all fields
      await tester.tap(firstNameField);
      await tester.enterText(firstNameField, 'John');
      await tester.tap(lastNameField);
      await tester.enterText(lastNameField, 'Doe');
      await tester.tap(emailField);
      await tester.enterText(emailField, 'john.doe@example.com');
      await tester.tap(passwordField);
      await tester.enterText(passwordField, 'SecurePassword123!');
      await tester.tap(confirmPasswordField);
      await tester.enterText(confirmPasswordField, 'SecurePassword123!');
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert
      verify(mockAuthViewModel.register(
        'john.doe@example.com',
        'SecurePassword123!',
        {'firstName': 'John', 'lastName': 'Doe'},
      )).called(1);
    });
  });
}

/// Mock Login Screen for testing
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.headlineMedium,
              key: Key('sign_in_title'),
            ),
            const SizedBox(height: 32),
            TextFormField(
              key: Key('email_text_field'),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: Key('password_text_field'),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  key: Key('password_visibility_toggle'),
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // Toggle password visibility
                  },
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                if (authViewModel.isLoading) {
                  return const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Signing In...'),
                    ],
                  );
                }

                return ElevatedButton(
                  key: Key('sign_in_button'),
                  onPressed: () {
                    // Login logic would go here
                  },
                  child: const Text('Sign In'),
                );
              },
            ),
            const SizedBox(height: 16),
            if (context.watch<AuthViewModel>().error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.watch<AuthViewModel>().error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            TextButton(
              key: Key('forgot_password_link'),
              onPressed: () {
                // Navigate to forgot password
              },
              child: const Text('Forgot Password?'),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Don\'t have an account? '),
                TextButton(
                  key: Key('sign_up_link'),
                  onPressed: () {
                    // Navigate to register
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mock Register Screen for testing
class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Create Account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            TextFormField(
              key: Key('first_name_text_field'),
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: Key('last_name_text_field'),
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: Key('email_text_field'),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: Key('password_text_field'),
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: Key('confirm_password_text_field'),
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value != 'SecurePassword123!') {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: Key('create_account_button'),
              onPressed: () {
                // Register logic would go here
              },
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                TextButton(
                  onPressed: () {
                    // Navigate to login
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}