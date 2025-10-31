import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/services/auth_service.dart';
import '../../core/utils/base_viewmodel.dart';

/// Auth provider for state management
class AuthProvider extends BaseViewModel {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthService _authService;

  AuthProvider({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AuthService authService,
  }) 
  : _loginUseCase = loginUseCase,
    _registerUseCase = registerUseCase,
    _logoutUseCase = logoutUseCase,
    _getCurrentUserUseCase = getCurrentUserUseCase,
    _authService = authService;

  // User state
  UserModel? _user;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  // Authentication methods
  Future<bool> login(String email, String password) async {
    return await executeAsync(
      () async {
        final result = await _loginUseCase.execute(
          LoginParams(email: email, password: password),
        );
        
        return result.fold(
          (failure) => throw Exception(failure.message),
          (authResult) {
            _user = authResult.user;
            return true;
          },
        );
      },
      loadingMessage: 'Signing in...',
    ) ?? false;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await executeAsync(
      () async {
        final result = await _registerUseCase.execute(
          RegisterParams(
            email: email,
            password: password,
            name: name,
          ),
        );
        
        return result.fold(
          (failure) => throw Exception(failure.message),
          (authResult) {
            _user = authResult.user;
            return true;
          },
        );
      },
      loadingMessage: 'Creating account...',
    ) ?? false;
  }

  Future<void> logout() async {
    await executeAsync(
      () async {
        final result = await _logoutUseCase.execute(NoParams());
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {
            _user = null;
          },
        );
      },
      loadingMessage: 'Signing out...',
    );
  }

  Future<void> checkAuthStatus() async {
    await executeAsync(
      () async {
        final result = await _getCurrentUserUseCase.execute(NoParams());
        result.fold(
          (failure) {
            _user = null;
          },
          (user) {
            _user = user;
          },
        );
      },
      showLoading: false,
    );
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      await checkAuthStatus();
    }
  }
}

/// Auth provider state notifier for Riverpod
final authProvider = StateNotifierProvider<AuthProvider, AsyncValue<AuthProvider?>>(
  (ref) {
    final loginUseCase = ref.read(loginUseCaseProvider);
    final registerUseCase = ref.read(registerUseCaseProvider);
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    final authService = ref.read(authServiceProvider);

    return AuthProvider(
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
      logoutUseCase: logoutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      authService: authService,
    );
  },
);

// Provider for use cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return LoginUseCase(authRepository);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return RegisterUseCase(authRepository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return LogoutUseCase(authRepository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return GetCurrentUserUseCase(authRepository);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  // This would be injected via dependency injection
  throw UnimplementedError('AuthRepository should be injected via DI');
});

final authServiceProvider = Provider<AuthService>((ref) {
  // This would be injected via dependency injection
  throw UnimplementedError('AuthService should be injected via DI');
});

// User model placeholder
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
    };
  }
}