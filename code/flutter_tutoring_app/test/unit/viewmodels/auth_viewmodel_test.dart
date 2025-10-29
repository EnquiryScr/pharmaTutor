import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/annotations.dart';
import '../../lib/presentation/viewmodels/auth_viewmodel.dart';
import '../../lib/data/services/auth_service.dart';
import '../../mocks/mock_services.dart';
import '../../mocks/mock_viewmodels.dart';
import '../../fixtures/auth_fixtures.dart';
import '../../test_config.dart';
import '../../helpers/test_helpers.dart';

/// Generate mock classes
@GenerateMocks([AuthService])
import 'auth_viewmodel_test.mocks.dart';

void main() {
  group('AuthViewModel', () {
    late AuthViewModel authViewModel;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authViewModel = AuthViewModel(authService: mockAuthService);
    });

    tearDown(() {
      authViewModel.dispose();
    });

    test('should initialize with unloaded state', () {
      expect(authViewModel.state, equals(ViewState.unloaded));
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.error, isNull);
      expect(authViewModel.isAuthenticated, isFalse);
      expect(authViewModel.currentUserId, isNull);
      expect(authViewModel.currentUserRole, isNull);
      expect(authViewModel.currentUserEmail, isNull);
    });

    group('login', () {
      test('should set loading state during login', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);

        // Act
        final future = authViewModel.login('test@example.com', 'password123');
        expect(authViewModel.isLoading, isTrue);
        expect(authViewModel.state, equals(ViewState.loading));

        // Assert
        await future;
        expect(authViewModel.isLoading, isFalse);
      });

      test('should login successfully with valid credentials', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);

        // Act
        await authViewModel.login('test@example.com', 'password123');

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.isAuthenticated, isTrue);
        expect(authViewModel.currentUserId, equals('student-123'));
        expect(authViewModel.currentUserRole, equals('student'));
        expect(authViewModel.currentUserEmail, equals('student@example.com'));
        expect(authViewModel.error, isNull);

        verify(mockAuthService.login('test@example.com', 'password123')).called(1);
      });

      test('should handle login failure with invalid credentials', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.failedLoginResponse);

        // Act
        await authViewModel.login('wrong@example.com', 'wrongpassword');

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.isAuthenticated, isFalse);
        expect(authViewModel.currentUserId, isNull);
        expect(authViewModel.currentUserRole, isNull);
        expect(authViewModel.currentUserEmail, isNull);
        expect(authViewModel.error, equals('Invalid email or password'));

        verify(mockAuthService.login('wrong@example.com', 'wrongpassword')).called(1);
      });

      test('should handle network errors during login', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => authViewModel.login('test@example.com', 'password123'),
          throwsA(isA<Exception>()),
        );

        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, isNotNull);
      });

      test('should not login with empty email', () async {
        // Act & Assert
        expect(
          () => authViewModel.login('', 'password123'),
          throwsA(isA<ArgumentError>()),
        );

        expect(authViewModel.state, equals(ViewState.error));
      });

      test('should not login with empty password', () async {
        // Act & Assert
        expect(
          () => authViewModel.login('test@example.com', ''),
          throwsA(isA<ArgumentError>()),
        );

        expect(authViewModel.state, equals(ViewState.error));
      });

      test('should not login with invalid email format', () async {
        // Act & Assert
        expect(
          () => authViewModel.login('invalid-email', 'password123'),
          throwsA(isA<ArgumentError>()),
        );

        expect(authViewModel.state, equals(ViewState.error));
      });
    });

    group('register', () {
      test('should set loading state during registration', () async {
        // Arrange
        when(mockAuthService.register(any, any, any))
            .thenAnswer((_) async => AuthFixtures.successfulRegisterResponse);

        // Act
        final future = authViewModel.register(
          'new@example.com',
          'NewPassword123!',
          {'firstName': 'New', 'lastName': 'User'},
        );
        expect(authViewModel.isLoading, isTrue);
        expect(authViewModel.state, equals(ViewState.loading));

        // Assert
        await future;
        expect(authViewModel.isLoading, isFalse);
      });

      test('should register successfully with valid data', () async {
        // Arrange
        when(mockAuthService.register(any, any, any))
            .thenAnswer((_) async => AuthFixtures.successfulRegisterResponse);

        // Act
        await authViewModel.register(
          'new@example.com',
          'NewPassword123!',
          {'firstName': 'New', 'lastName': 'User'},
        );

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.error, isNull);

        verify(mockAuthService.register(
          'new@example.com',
          'NewPassword123!',
          {'firstName': 'New', 'lastName': 'User'},
        )).called(1);
      });

      test('should handle registration failure when email already exists', () async {
        // Arrange
        when(mockAuthService.register(any, any, any))
            .thenAnswer((_) async => AuthFixtures.emailExistsResponse);

        // Act
        await authViewModel.register(
          'existing@example.com',
          'NewPassword123!',
          {'firstName': 'Existing', 'lastName': 'User'},
        );

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, equals('Email address is already registered'));
      });
    });

    group('logout', () {
      test('should logout successfully when authenticated', () async {
        // Arrange - First login
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        await authViewModel.login('test@example.com', 'password123');

        // Arrange - Setup logout
        when(mockAuthService.logout())
            .thenAnswer((_) async => {'success': true, 'data': {'message': 'Logout successful'}});

        // Act
        await authViewModel.logout();

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.isAuthenticated, isFalse);
        expect(authViewModel.currentUserId, isNull);
        expect(authViewModel.currentUserRole, isNull);
        expect(authViewModel.currentUserEmail, isNull);
        expect(authViewModel.error, isNull);

        verify(mockAuthService.logout()).called(1);
      });

      test('should handle logout failure gracefully', () async {
        // Arrange
        when(mockAuthService.logout())
            .thenThrow(Exception('Logout failed'));

        // Act & Assert
        expect(
          () => authViewModel.logout(),
          throwsA(isA<Exception>()),
        );

        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, isNotNull);
      });
    });

    group('resetPassword', () {
      test('should request password reset successfully', () async {
        // Arrange
        when(mockAuthService.resetPassword(any))
            .thenAnswer((_) async => {
              'success': true,
              'data': {'message': 'Password reset email sent'},
            });

        // Act
        await authViewModel.resetPassword('test@example.com');

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.error, isNull);

        verify(mockAuthService.resetPassword('test@example.com')).called(1);
      });

      test('should handle password reset failure', () async {
        // Arrange
        when(mockAuthService.resetPassword(any))
            .thenAnswer((_) async => {
              'success': false,
              'error': {'code': 'USER_NOT_FOUND', 'message': 'User not found'},
            });

        // Act
        await authViewModel.resetPassword('nonexistent@example.com');

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, equals('User not found'));
      });
    });

    group('updateProfile', () {
      test('should update profile successfully', () async {
        // Arrange - First login
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        await authViewModel.login('test@example.com', 'password123');

        // Arrange - Setup profile update
        when(mockAuthService.updateProfile(any))
            .thenAnswer((_) async => {
              'success': true,
              'data': {
                'user': {
                  ...AuthFixtures.validStudentUser,
                  'firstName': 'Updated',
                  'lastName': 'Name',
                },
              },
            });

        // Act
        await authViewModel.updateProfile({
          'firstName': 'Updated',
          'lastName': 'Name',
        });

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.error, isNull);

        verify(mockAuthService.updateProfile({
          'firstName': 'Updated',
          'lastName': 'Name',
        })).called(1);
      });

      test('should handle profile update failure', () async {
        // Arrange - First login
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        await authViewModel.login('test@example.com', 'password123');

        // Arrange - Setup profile update failure
        when(mockAuthService.updateProfile(any))
            .thenAnswer((_) async => {
              'success': false,
              'error': {'code': 'UPDATE_FAILED', 'message': 'Profile update failed'},
            });

        // Act
        await authViewModel.updateProfile({'invalid': 'data'});

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, equals('Profile update failed'));
      });
    });

    group('checkAuthStatus', () {
      test('should check authentication status successfully', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        
        // Act
        await authViewModel.checkAuthStatus();

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.isAuthenticated, isTrue);
      });

      test('should handle authentication check when not authenticated', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.failedLoginResponse);

        // Act
        await authViewModel.checkAuthStatus();

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.isAuthenticated, isFalse);
      });
    });

    group('clearError', () {
      test('should clear error state', () async {
        // Arrange - First trigger an error
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.failedLoginResponse);
        await authViewModel.login('test@example.com', 'wrongpassword');
        
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, isNotNull);

        // Act
        authViewModel.clearError();

        // Assert
        expect(authViewModel.state, equals(ViewState.loaded));
        expect(authViewModel.error, isNull);
      });
    });

    group('state management', () {
      test('should transition through correct states during successful login', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);

        // Act & Assert
        expect(authViewModel.state, equals(ViewState.unloaded));

        final future = authViewModel.login('test@example.com', 'password123');
        expect(authViewModel.state, equals(ViewState.loading));
        
        await future;
        expect(authViewModel.state, equals(ViewState.loaded));
      });

      test('should transition to error state on failure', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.failedLoginResponse);

        // Act & Assert
        expect(authViewModel.state, equals(ViewState.unloaded));

        await authViewModel.login('test@example.com', 'wrongpassword');
        expect(authViewModel.state, equals(ViewState.error));
      });

      test('should handle concurrent login attempts', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);

        // Act
        final future1 = authViewModel.login('test@example.com', 'password123');
        final future2 = authViewModel.login('test2@example.com', 'password123');

        // Assert
        expect(authViewModel.isLoading, isTrue);

        await Future.wait([future1, future2]);
        expect(authViewModel.isLoading, isFalse);
        expect(authViewModel.state, equals(ViewState.loaded));
      });
    });

    group('validation', () {
      test('should validate email format', () {
        expect(authViewModel.isValidEmail('test@example.com'), isTrue);
        expect(authViewModel.isValidEmail('invalid-email'), isFalse);
        expect(authViewModel.isValidEmail(''), isFalse);
        expect(authViewModel.isValidEmail(null), isFalse);
      });

      test('should validate password strength', () {
        expect(authViewModel.isStrongPassword('StrongPassword123!'), isTrue);
        expect(authViewModel.isStrongPassword('weak'), isFalse);
        expect(authViewModel.isStrongPassword('NoNumbers!'), isFalse);
        expect(authViewModel.isStrongPassword('nouppercase123!'), isFalse);
        expect(authViewModel.isStrongPassword('NOLOWERCASE123!'), isFalse);
        expect(authViewModel.isStrongPassword(''), isFalse);
      });

      test('should validate required fields', () {
        expect(authViewModel.areValidCredentials('test@example.com', 'password123'), isTrue);
        expect(authViewModel.areValidCredentials('', 'password123'), isFalse);
        expect(authViewModel.areValidCredentials('test@example.com', ''), isFalse);
        expect(authViewModel.areValidCredentials('', ''), isFalse);
      });
    });

    group('session management', () {
      test('should persist authentication state after login', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);

        // Act
        await authViewModel.login('test@example.com', 'password123');

        // Assert
        expect(authViewModel.isAuthenticated, isTrue);
        expect(authViewModel.currentUserId, equals('student-123'));
      });

      test('should clear session after logout', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        when(mockAuthService.logout())
            .thenAnswer((_) async => {'success': true, 'data': {'message': 'Logout successful'}});
        
        await authViewModel.login('test@example.com', 'password123');
        
        // Act
        await authViewModel.logout();

        // Assert
        expect(authViewModel.isAuthenticated, isFalse);
        expect(authViewModel.currentUserId, isNull);
      });
    });

    group('error handling', () {
      test('should handle network timeouts gracefully', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenThrow(TimeoutException('Connection timeout', const Duration(seconds: 30)));

        // Act
        await authViewModel.login('test@example.com', 'password123');

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, isNotNull);
        expect(authViewModel.error, contains('timeout'));
      });

      test('should handle API errors with specific codes', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.accountLockedResponse);

        // Act
        await authViewModel.login('test@example.com', 'password123');

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, contains('Account is temporarily locked'));
      });

      test('should handle server maintenance errors', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => {
              'success': false,
              'error': {
                'code': 'SERVER_MAINTENANCE',
                'message': 'Server is under maintenance. Please try again later.',
              },
            });

        // Act
        await authViewModel.login('test@example.com', 'password123');

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, contains('maintenance'));
      });
    });

    group('security', () {
      test('should not expose sensitive data in error messages', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => {
              'success': false,
              'error': {
                'code': 'SECURITY_ERROR',
                'message': 'An error occurred',
                'debugInfo': 'Internal error details',
              },
            });

        // Act
        await authViewModel.login('test@example.com', 'password123');

        // Assert
        expect(authViewModel.state, equals(ViewState.error));
        expect(authViewModel.error, isNotNull);
        // Error should not contain sensitive debug information
        expect(authViewModel.error, isNot(contains('debugInfo')));
      });

      test('should clear sensitive data when disposing', () async {
        // Arrange
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);

        // Act
        await authViewModel.login('test@example.com', 'password123');
        authViewModel.dispose();

        // Assert
        expect(authViewModel.currentUserId, isNull);
        expect(authViewModel.currentUserRole, isNull);
        expect(authViewModel.currentUserEmail, isNull);
      });
    });
  });
}

/// Timeout exception for tests
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}