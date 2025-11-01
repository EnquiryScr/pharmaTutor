import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';

/// Auth Provider using Riverpod
final authProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) {
    // For now, use a mock implementation
    final mockAuthRepository = MockAuthRepository();
    final loginUseCase = LoginUseCase(mockAuthRepository);
    return AuthViewModel(loginUseCase);
  },
);

/// Mock Auth Repository for testing
class MockAuthRepository implements IAuthRepository {
  @override
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock successful login
    if (email.isNotEmpty && password.length >= 6) {
      return Right(AuthResult(
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        user: const UserModel(
          id: '1',
          email: 'user@example.com',
          name: 'Test User',
          avatar: 'https://example.com/avatar.jpg',
        ),
        refreshToken: 'mock_refresh_token',
      ));
    } else {
      return Left(Failure('Invalid email or password'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock successful registration
    if (email.isNotEmpty && password.length >= 6 && name.isNotEmpty) {
      return Right(AuthResult(
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        user: UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: name,
        ),
        refreshToken: 'mock_refresh_token',
      ));
    } else {
      return Left(Failure('Invalid registration data'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    // Simulate logout
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    // Mock current user
    return const Right(UserModel(
      id: '1',
      email: 'user@example.com',
      name: 'Test User',
    ));
  }

  @override
  Future<Either<Failure, AuthResult>> refreshToken(String refreshToken) async {
    return Left(Failure('Not implemented'));
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    return Left(Failure('Not implemented'));
  }

  @override
  Future<Either<Failure, UserModel>> updateProfile(UserModel user) async {
    return Left(Failure('Not implemented'));
  }

  @override
  bool isAuthenticated() {
    return false;
  }

  @override
  String? getAuthToken() {
    return null;
  }

  @override
  void clearAuthData() {
    // Clear any stored auth data
  }
}