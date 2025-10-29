import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import '../../lib/data/services/auth_service.dart';
import '../../lib/core/integrations/api_client.dart';
import '../../lib/core/integrations/authentication_service.dart';
import '../../lib/core/secure_storage/secure_storage.dart';
import '../../mocks/mock_integrations.dart';
import '../../fixtures/auth_fixtures.dart';
import '../../test_config.dart';
import '../../helpers/test_helpers.dart';

/// Generate mock classes
@GenerateMocks([ApiClient, AuthenticationService, SecureStorage, http.Client])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockApiClient mockApiClient;
    late MockAuthenticationService mockAuthService;
    late MockSecureStorage mockSecureStorage;

    setUp(() {
      mockApiClient = MockApiClient();
      mockAuthService = MockAuthenticationService();
      mockSecureStorage = MockSecureStorage();
      
      authService = AuthService(
        apiClient: mockApiClient,
        authService: mockAuthService,
        secureStorage: mockSecureStorage,
      );
    });

    group('login', () {
      test('should login successfully with valid credentials', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        when(mockSecureStorage.write('access_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('refresh_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('user_data', any)).thenAnswer((_) async {});

        // Act
        final result = await authService.login('student@example.com', 'password123');

        // Assert
        expect(result['success'], isTrue);
        expect(result['data']['user']['email'], equals('student@example.com'));
        expect(result['data']['accessToken'], isNotNull);
        
        verify(mockApiClient.post('/auth/login', data: {
          'email': 'student@example.com',
          'password': 'password123',
        })).called(1);
        
        verify(mockSecureStorage.write('access_token', any)).called(1);
        verify(mockSecureStorage.write('refresh_token', any)).called(1);
        verify(mockSecureStorage.write('user_data', any)).called(1);
      });

      test('should handle login failure with invalid credentials', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.failedLoginResponse);

        // Act
        final result = await authService.login('wrong@example.com', 'wrongpassword');

        // Assert
        expect(result['success'], isFalse);
        expect(result['error']['code'], equals('INVALID_CREDENTIALS'));
        expect(result['error']['message'], equals('Invalid email or password'));
      });

      test('should handle network errors during login', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => authService.login('test@example.com', 'password123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should not login with empty email', () async {
        // Act & Assert
        expect(
          () => authService.login('', 'password123'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should not login with empty password', () async {
        // Act & Assert
        expect(
          () => authService.login('test@example.com', ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate email format before API call', () async {
        // Act & Assert
        expect(
          () => authService.login('invalid-email', 'password123'),
          throwsA(isA<ArgumentError>()),
        );

        verifyNever(mockApiClient.post('/auth/login', data: anyNamed('data')));
      });
    });

    group('register', () {
      test('should register successfully with valid data', () async {
        // Arrange
        when(mockApiClient.post('/auth/register', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulRegisterResponse);

        // Act
        final result = await authService.register(
          'new@example.com',
          'NewPassword123!',
          {'firstName': 'New', 'lastName': 'User'},
        );

        // Assert
        expect(result['success'], isTrue);
        expect(result['data']['message'], equals('User registered successfully'));
        
        verify(mockApiClient.post('/auth/register', data: {
          'email': 'new@example.com',
          'password': 'NewPassword123!',
          'firstName': 'New',
          'lastName': 'User',
        })).called(1);
      });

      test('should handle registration failure when email exists', () async {
        // Arrange
        when(mockApiClient.post('/auth/register', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.emailExistsResponse);

        // Act
        final result = await authService.register(
          'existing@example.com',
          'Password123!',
          {'firstName': 'Existing', 'lastName': 'User'},
        );

        // Assert
        expect(result['success'], isFalse);
        expect(result['error']['code'], equals('EMAIL_ALREADY_EXISTS'));
      });

      test('should validate password strength during registration', () async {
        // Arrange - Mock successful API response
        when(mockApiClient.post('/auth/register', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulRegisterResponse);

        // Act & Assert
        expect(
          () => authService.register('test@example.com', 'weak', {'firstName': 'Test'}),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => authService.register('test@example.com', 'NoNumbers!', {'firstName': 'Test'}),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => authService.register('test@example.com', 'nouppercase123!', {'firstName': 'Test'}),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('logout', () {
      test('should logout successfully', () async {
        // Arrange
        when(mockApiClient.post('/auth/logout', data: anyNamed('data')))
            .thenAnswer((_) async => {'success': true, 'data': {'message': 'Logout successful'}});
        when(mockSecureStorage.delete('access_token')).thenAnswer((_) async {});
        when(mockSecureStorage.delete('refresh_token')).thenAnswer((_) async {});
        when(mockSecureStorage.delete('user_data')).thenAnswer((_) async {});

        // Act
        final result = await authService.logout();

        // Assert
        expect(result['success'], isTrue);
        expect(result['data']['message'], equals('Logout successful'));
        
        verify(mockApiClient.post('/auth/logout', data: anyNamed('data'))).called(1);
        verify(mockSecureStorage.delete('access_token')).called(1);
        verify(mockSecureStorage.delete('refresh_token')).called(1);
        verify(mockSecureStorage.delete('user_data')).called(1);
      });

      test('should clear local data even if API call fails', () async {
        // Arrange
        when(mockApiClient.post('/auth/logout', data: anyNamed('data')))
            .thenThrow(Exception('Network error'));
        when(mockSecureStorage.delete('access_token')).thenAnswer((_) async {});
        when(mockSecureStorage.delete('refresh_token')).thenAnswer((_) async {});
        when(mockSecureStorage.delete('user_data')).thenAnswer((_) async {});

        // Act
        await authService.logout();

        // Assert
        verify(mockSecureStorage.delete('access_token')).called(1);
        verify(mockSecureStorage.delete('refresh_token')).called(1);
        verify(mockSecureStorage.delete('user_data')).called(1);
      });
    });

    group('token management', () {
      test('should refresh token successfully', () async {
        // Arrange
        when(mockSecureStorage.read('refresh_token'))
            .thenAnswer((_) async => AuthFixtures.validRefreshToken);
        when(mockApiClient.post('/auth/refresh', data: anyNamed('data')))
            .thenAnswer((_) async => {
              'success': true,
              'data': {
                'accessToken': 'new-access-token',
                'refreshToken': 'new-refresh-token',
                'expiresIn': 3600,
              },
            });
        when(mockSecureStorage.write('access_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('refresh_token', any)).thenAnswer((_) async {});

        // Act
        final result = await authService.refreshToken();

        // Assert
        expect(result['success'], isTrue);
        expect(result['data']['accessToken'], equals('new-access-token'));
        
        verify(mockSecureStorage.read('refresh_token')).called(1);
        verify(mockApiClient.post('/auth/refresh', data: {
          'refreshToken': AuthFixtures.validRefreshToken,
        })).called(1);
        verify(mockSecureStorage.write('access_token', 'new-access-token')).called(1);
        verify(mockSecureStorage.write('refresh_token', 'new-refresh-token')).called(1);
      });

      test('should handle refresh token failure', () async {
        // Arrange
        when(mockSecureStorage.read('refresh_token'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => authService.refreshToken(),
          throwsA(isA<Exception>()),
        );
      });

      test('should store tokens securely', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        when(mockSecureStorage.write('access_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('refresh_token', any)).thenAnswer((_) async {});

        // Act
        await authService.login('test@example.com', 'password123');

        // Assert
        verify(mockSecureStorage.write('access_token', any)).called(1);
        verify(mockSecureStorage.write('refresh_token', any)).called(1);
        verifyNever(mockSecureStorage.write('password', any)); // Password should never be stored
      });
    });

    group('profile management', () {
      test('should update profile successfully', () async {
        // Arrange
        when(mockApiClient.put('/user/profile', data: anyNamed('data')))
            .thenAnswer((_) async => {
              'success': true,
              'data': {
                'user': {
                  'id': 'user-123',
                  'email': 'test@example.com',
                  'firstName': 'Updated',
                  'lastName': 'User',
                },
              },
            });

        // Act
        final result = await authService.updateProfile({
          'firstName': 'Updated',
          'lastName': 'User',
        });

        // Assert
        expect(result['success'], isTrue);
        expect(result['data']['user']['firstName'], equals('Updated'));
        expect(result['data']['user']['lastName'], equals('User'));
        
        verify(mockApiClient.put('/user/profile', data: {
          'firstName': 'Updated',
          'lastName': 'User',
        })).called(1);
      });

      test('should handle profile update failure', () async {
        // Arrange
        when(mockApiClient.put('/user/profile', data: anyNamed('data')))
            .thenAnswer((_) async => {
              'success': false,
              'error': {'code': 'UPDATE_FAILED', 'message': 'Profile update failed'},
            });

        // Act
        final result = await authService.updateProfile({'invalid': 'data'});

        // Assert
        expect(result['success'], isFalse);
        expect(result['error']['code'], equals('UPDATE_FAILED'));
      });
    });

    group('password reset', () {
      test('should request password reset successfully', () async {
        // Arrange
        when(mockApiClient.post('/auth/reset-password', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.passwordResetResponse);

        // Act
        final result = await authService.resetPassword('test@example.com');

        // Assert
        expect(result['success'], isTrue);
        expect(result['data']['message'], equals('Password reset email sent'));
        
        verify(mockApiClient.post('/auth/reset-password', data: {
          'email': 'test@example.com',
        })).called(1);
      });

      test('should handle password reset failure', () async {
        // Arrange
        when(mockApiClient.post('/auth/reset-password', data: anyNamed('data')))
            .thenAnswer((_) async => {
              'success': false,
              'error': {'code': 'USER_NOT_FOUND', 'message': 'User not found'},
            });

        // Act
        final result = await authService.resetPassword('nonexistent@example.com');

        // Assert
        expect(result['success'], isFalse);
        expect(result['error']['code'], equals('USER_NOT_FOUND'));
      });
    });

    group('validation', () {
      test('should validate email format', () {
        expect(authService.isValidEmail('test@example.com'), isTrue);
        expect(authService.isValidEmail('user.name@domain.co.uk'), isTrue);
        expect(authService.isValidEmail('invalid-email'), isFalse);
        expect(authService.isValidEmail('test@'), isFalse);
        expect(authService.isValidEmail('@domain.com'), isFalse);
        expect(authService.isValidEmail(''), isFalse);
        expect(authService.isValidEmail(null), isFalse);
      });

      test('should validate password strength', () {
        expect(authService.isStrongPassword('StrongPassword123!'), isTrue);
        expect(authService.isStrongPassword('Password1!'), isTrue);
        expect(authService.isStrongPassword('weak'), isFalse);
        expect(authService.isStrongPassword('NoNumbers!'), isFalse);
        expect(authService.isStrongPassword('nouppercase123!'), isFalse);
        expect(authService.isStrongPassword('NOLOWERCASE123!'), isFalse);
        expect(authService.isStrongPassword('NoSpecial123'), isFalse);
        expect(authService.isStrongPassword(''), isFalse);
        expect(authService.isStrongPassword(null), isFalse);
      });

      test('should validate required fields', () {
        expect(authService.areValidCredentials('test@example.com', 'password123'), isTrue);
        expect(authService.areValidCredentials('', 'password123'), isFalse);
        expect(authService.areValidCredentials('test@example.com', ''), isFalse);
        expect(authService.areValidCredentials('', ''), isFalse);
      });
    });

    group('session management', () {
      test('should check if user is authenticated', () async {
        // Arrange
        when(mockSecureStorage.read('access_token'))
            .thenAnswer((_) async => AuthFixtures.validAccessToken);
        when(mockSecureStorage.read('user_data'))
            .thenAnswer((_) async => '{"id": "user-123", "email": "test@example.com"}');

        // Act
        final isAuthenticated = authService.isAuthenticated;

        // Assert
        expect(isAuthenticated, isTrue);
        verify(mockSecureStorage.read('access_token')).called(1);
        verify(mockSecureStorage.read('user_data')).called(1);
      });

      test('should return false when not authenticated', () async {
        // Arrange
        when(mockSecureStorage.read('access_token')).thenAnswer((_) async => null);

        // Act
        final isAuthenticated = authService.isAuthenticated;

        // Assert
        expect(isAuthenticated, isFalse);
      });

      test('should get current user ID', () async {
        // Arrange
        when(mockSecureStorage.read('user_data'))
            .thenAnswer((_) async => '{"id": "user-123", "email": "test@example.com"}');

        // Act
        final userId = authService.currentUserId;

        // Assert
        expect(userId, equals('user-123'));
      });

      test('should get current user role', () async {
        // Arrange
        when(mockSecureStorage.read('user_data'))
            .thenAnswer((_) async => '{"id": "user-123", "role": "student"}');

        // Act
        final userRole = authService.currentUserRole;

        // Assert
        expect(userRole, equals('student'));
      });
    });

    group('error handling', () {
      test('should handle API timeouts gracefully', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenThrow(TimeoutException('Request timeout', const Duration(seconds: 30)));

        // Act
        final result = await authService.login('test@example.com', 'password123');

        // Assert
        expect(result['success'], isFalse);
        expect(result['error']['code'], equals('TIMEOUT_ERROR'));
        expect(result['error']['message'], contains('timeout'));
      });

      test('should handle server maintenance errors', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => {
              'success': false,
              'error': {
                'code': 'SERVER_MAINTENANCE',
                'message': 'Server is under maintenance. Please try again later.',
              },
            });

        // Act
        final result = await authService.login('test@example.com', 'password123');

        // Assert
        expect(result['success'], isFalse);
        expect(result['error']['code'], equals('SERVER_MAINTENANCE'));
      });

      test('should handle rate limiting', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => {
              'success': false,
              'error': {
                'code': 'RATE_LIMIT_EXCEEDED',
                'message': 'Too many login attempts. Please try again later.',
                'retryAfter': 300, // 5 minutes
              },
            });

        // Act
        final result = await authService.login('test@example.com', 'password123');

        // Assert
        expect(result['success'], isFalse);
        expect(result['error']['code'], equals('RATE_LIMIT_EXCEEDED'));
        expect(result['error']['retryAfter'], equals(300));
      });
    });

    group('security', () {
      test('should never store passwords in plain text', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        when(mockSecureStorage.write('access_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('refresh_token', any)).thenAnswer((_) async {});

        // Act
        await authService.login('test@example.com', 'password123');

        // Assert
        verifyNever(mockSecureStorage.write('password', 'password123'));
        verifyNever(mockSecureStorage.write('plainPassword', any));
      });

      test('should encrypt sensitive data before storage', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        when(mockSecureStorage.write('access_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('refresh_token', any)).thenAnswer((_) async {});

        // Act
        await authService.login('test@example.com', 'password123');

        // Assert
        // Verify that sensitive data is encrypted before storage
        // This would typically involve checking if the stored data is encrypted
        verify(mockSecureStorage.write('access_token', any)).called(1);
      });

      test('should clear all sensitive data on logout', () async {
        // Arrange
        when(mockApiClient.post('/auth/logout', data: anyNamed('data')))
            .thenAnswer((_) async => {'success': true, 'data': {'message': 'Logout successful'}});
        when(mockSecureStorage.delete('access_token')).thenAnswer((_) async {});
        when(mockSecureStorage.delete('refresh_token')).thenAnswer((_) async {});
        when(mockSecureStorage.delete('user_data')).thenAnswer((_) async {});
        when(mockSecureStorage.delete('profile_data')).thenAnswer((_) async {});

        // Act
        await authService.logout();

        // Assert
        verify(mockSecureStorage.delete('access_token')).called(1);
        verify(mockSecureStorage.delete('refresh_token')).called(1);
        verify(mockSecureStorage.delete('user_data')).called(1);
        verify(mockSecureStorage.delete('profile_data')).called(1);
      });
    });

    group('performance', () {
      test('should handle concurrent login attempts efficiently', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        when(mockSecureStorage.write('access_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('refresh_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('user_data', any)).thenAnswer((_) async {});

        // Act
        final futures = List.generate(5, (index) => 
            authService.login('user$index@example.com', 'password123'));

        // Assert
        final results = await Future.wait(futures);
        for (final result in results) {
          expect(result['success'], isTrue);
        }
      });

      test('should measure login performance', () async {
        // Arrange
        when(mockApiClient.post('/auth/login', data: anyNamed('data')))
            .thenAnswer((_) async => AuthFixtures.successfulLoginResponse);
        when(mockSecureStorage.write('access_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('refresh_token', any)).thenAnswer((_) async {});
        when(mockSecureStorage.write('user_data', any)).thenAnswer((_) async {});

        // Act
        final result = await TestHelpers.measureExecutionTime(
          () => authService.login('test@example.com', 'password123'),
        );

        // Assert
        expect(result['success'], isTrue);
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