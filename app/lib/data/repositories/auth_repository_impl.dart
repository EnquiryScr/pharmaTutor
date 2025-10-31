import 'package:dartz/dartz.dart';
import '../../domain/repositories/i_domain_repositories.dart';
import '../../core/utils/dependency_injection.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthApiClient _apiClient;
  final LocalDataSource _localDataSource;

  AuthRepositoryImpl(this._apiClient, this._localDataSource);

  @override
  String get repositoryName => 'AuthRepository';

  @override
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _apiClient.login(
        email: email,
        password: password,
      );

      if (result.success && result.data != null) {
        // Store tokens in local storage
        if (result.data!.token != null) {
          await _localDataSource.setString(StorageKeys.token, result.data!.token!);
        }
        if (result.data!.refreshToken != null) {
          await _localDataSource.setString(StorageKeys.refreshToken, result.data!.refreshToken!);
        }
        
        return Right(result.data!);
      } else {
        return Left(Failure(
          message: result.message ?? 'Login failed',
          exception: result.error,
        ));
      }
    } on ApiException catch (e) {
      return Left(Failure(
        message: e.message,
        exception: e,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'An unexpected error occurred',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final result = await _apiClient.register(
        email: email,
        password: password,
        name: name,
      );

      if (result.success && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(Failure(
          message: result.message ?? 'Registration failed',
          exception: result.error,
        ));
      }
    } on ApiException catch (e) {
      return Left(Failure(
        message: e.message,
        exception: e,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'An unexpected error occurred',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Clear local storage
      await _localDataSource.remove(StorageKeys.token);
      await _localDataSource.remove(StorageKeys.refreshToken);
      await _localDataSource.remove(StorageKeys.userData);

      // Call API logout
      await _apiClient.logout();

      return const Right(null);
    } on ApiException catch (e) {
      // Even if API fails, we want to clear local data
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Logout failed',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> refreshToken() async {
    try {
      final refreshToken = await _localDataSource.getString(StorageKeys.refreshToken);
      
      if (refreshToken == null) {
        return Left(Failure(
          message: 'No refresh token available',
          code: 'NO_REFRESH_TOKEN',
        ));
      }

      final result = await _apiClient.refreshToken(
        refreshToken: refreshToken,
      );

      if (result.success && result.data != null) {
        // Update stored tokens
        if (result.data!.token != null) {
          await _localDataSource.setString(StorageKeys.token, result.data!.token!);
        }
        if (result.data!.refreshToken != null) {
          await _localDataSource.setString(StorageKeys.refreshToken, result.data!.refreshToken!);
        }
        
        return Right(result.data!);
      } else {
        return Left(Failure(
          message: result.message ?? 'Token refresh failed',
          exception: result.error,
        ));
      }
    } on ApiException catch (e) {
      return Left(Failure(
        message: e.message,
        exception: e,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'An unexpected error occurred',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      final result = await _apiClient.forgotPassword(email);

      if (result.success) {
        return const Right(null);
      } else {
        return Left(Failure(
          message: result.message ?? 'Password reset request failed',
          exception: result.error,
        ));
      }
    } on ApiException catch (e) {
      return Left(Failure(
        message: e.message,
        exception: e,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'An unexpected error occurred',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final result = await _apiClient.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      if (result.success) {
        return const Right(null);
      } else {
        return Left(Failure(
          message: result.message ?? 'Password reset failed',
          exception: result.error,
        ));
      }
    } on ApiException catch (e) {
      return Left(Failure(
        message: e.message,
        exception: e,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'An unexpected error occurred',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final token = await _localDataSource.getString(StorageKeys.token);
      
      if (token == null || token.isEmpty) {
        return const Right(false);
      }

      // Optionally verify token with API
      final result = await _apiClient.getAuthStatus();
      
      return Right(result.success);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, dynamic>> getCurrentUser() async {
    try {
      final result = await _apiClient.getCurrentUser();

      if (result.success && result.data != null) {
        // Store user data locally
        await _localDataSource.setString(
          StorageKeys.userData, 
          result.data!.toJson().toString(),
        );
        
        return Right(result.data);
      } else {
        return Left(Failure(
          message: result.message ?? 'Failed to get user profile',
          exception: result.error,
        ));
      }
    } on ApiException catch (e) {
      return Left(Failure(
        message: e.message,
        exception: e,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'An unexpected error occurred',
        exception: e,
      ));
    }
  }

  // Implementation of BaseRepository methods (not needed for Auth)
  @override
  Future<Either<Failure, UserModel>> create(UserModel entity) {
    throw UnimplementedError('Create method not implemented for AuthRepository');
  }

  @override
  Future<Either<Failure, UserModel>> getById(String id) {
    throw UnimplementedError('GetById method not implemented for AuthRepository');
  }

  @override
  Future<Either<Failure, List<UserModel>>> getAll({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) {
    throw UnimplementedError('GetAll method not implemented for AuthRepository');
  }

  @override
  Future<Either<Failure, UserModel>> update(String id, UserModel entity) {
    throw UnimplementedError('Update method not implemented for AuthRepository');
  }

  @override
  Future<Either<Failure, bool>> delete(String id) {
    throw UnimplementedError('Delete method not implemented for AuthRepository');
  }

  @override
  Future<Either<Failure, List<UserModel>>> search(String query) {
    throw UnimplementedError('Search method not implemented for AuthRepository');
  }

  @override
  Future<Either<Failure, bool>> exists(String id) {
    throw UnimplementedError('Exists method not implemented for AuthRepository');
  }
}

/// Local Data Source interface (simplified for dependency injection)
abstract class LocalDataSource {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}