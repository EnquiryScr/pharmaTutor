import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../core/utils/base_model.dart';

/// Failure class for error handling in repositories
class Failure {
  final String message;
  final String? code;
  final dynamic exception;

  const Failure({
    required this.message,
    this.code,
    this.exception,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Repository interface - base contract for all repositories
abstract class IRepository {
  /// Get the repository name for logging/debugging
  String get repositoryName;
}

/// Generic repository interface for CRUD operations
abstract class IRepository<T extends BaseModel> extends IRepository {
  const IRepository() : super();

  /// Create a new entity
  /// Returns Either<Failure, T>
  Future<Either<Failure, T>> create(T entity);

  /// Get entity by ID
  /// Returns Either<Failure, T>
  Future<Either<Failure, T>> getById(String id);

  /// Get all entities
  /// Returns Either<Failure, List<T>>
  Future<Either<Failure, List<T>>> getAll({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  });

  /// Update an existing entity
  /// Returns Either<Failure, T>
  Future<Either<Failure, T>> update(String id, T entity);

  /// Delete an entity by ID
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> delete(String id);

  /// Search entities
  /// Returns Either<Failure, List<T>>
  Future<Either<Failure, List<T>>> search(String query);

  /// Check if entity exists
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> exists(String id);
}

/// Repository interface for entities with pagination
abstract class IPaginatedRepository<T extends BaseModel> extends IRepository<T> {
  const IPaginatedRepository() : super();

  /// Get paginated entities
  /// Returns Either<Failure, PaginatedResult<T>>
  Future<Either<Failure, PaginatedResult<T>>> getPaginated({
    required int page,
    required int limit,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? sort,
  });
}

/// Paginated result wrapper
class PaginatedResult<T> extends BaseModel {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResult.fromApiResponse(
    ApiListResponse<T> response,
  ) {
    return PaginatedResult(
      items: response.data ?? [],
      currentPage: response.page ?? 1,
      totalPages: (response.totalCount ?? 0) / (response.perPage ?? 20).ceil(),
      totalItems: response.totalCount ?? 0,
      itemsPerPage: response.perPage ?? 20,
      hasNextPage: (response.page ?? 1) < ((response.totalCount ?? 0) / (response.perPage ?? 20)).ceil(),
      hasPreviousPage: (response.page ?? 1) > 1,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  factory PaginatedResult.fromJson(Map<String, dynamic> json) {
    return PaginatedResult(
      items: (json['items'] as List<dynamic>)
          .map((item) => item as T)
          .toList(),
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
      itemsPerPage: json['itemsPerPage'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentPage,
        totalPages,
        totalItems,
        itemsPerPage,
        hasNextPage,
        hasPreviousPage,
      ];
}

/// Repository interface for caching operations
abstract class ICachedRepository<T extends BaseModel> extends IRepository<T> {
  const ICachedRepository() : super();

  /// Get entity from cache
  /// Returns Either<Failure, T>
  Future<Either<Failure, T>> getCachedById(String id);

  /// Cache an entity
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> cacheEntity(T entity);

  /// Remove entity from cache
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> removeCachedEntity(String id);

  /// Clear all cached entities
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> clearCache();

  /// Check if entity is cached
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> isCached(String id);
}

/// Repository interface for offline-first operations
abstract class IOfflineFirstRepository<T extends BaseModel> extends IRepository<T> {
  const IOfflineFirstRepository() : super();

  /// Sync data with remote source
  /// Returns Either<Failure, SyncResult<T>>
  Future<Either<Failure, SyncResult<T>>> syncData();

  /// Get offline data
  /// Returns Either<Failure, List<T>>
  Future<Either<Failure, List<T>>> getOfflineData();

  /// Save data for offline use
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> saveOfflineData(List<T> data);

  /// Check if data is synced with remote
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> isDataSynced();
}

/// Sync result for offline operations
class SyncResult<T> extends BaseModel {
  final List<T> syncedItems;
  final List<String> failedItems;
  final int totalSynced;
  final int totalFailed;

  const SyncResult({
    required this.syncedItems,
    required this.failedItems,
    required this.totalSynced,
    required this.totalFailed,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'syncedItems': syncedItems.map((item) => item.toJson()).toList(),
      'failedItems': failedItems,
      'totalSynced': totalSynced,
      'totalFailed': totalFailed,
    };
  }

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      syncedItems: (json['syncedItems'] as List<dynamic>)
          .map((item) => item as T)
          .toList(),
      failedItems: (json['failedItems'] as List<dynamic>)
          .cast<String>(),
      totalSynced: json['totalSynced'] as int,
      totalFailed: json['totalFailed'] as int,
    );
  }

  @override
  List<Object?> get props => [
        syncedItems,
        failedItems,
        totalSynced,
        totalFailed,
      ];
}

/// Repository interface for authentication operations
abstract class IAuthRepository extends IRepository {
  const IAuthRepository() : super();

  /// Login user
  /// Returns Either<Failure, AuthResult>
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  });

  /// Register new user
  /// Returns Either<Failure, AuthResult>
  Future<Either<Failure, AuthResult>> register({
    required String email,
    required String password,
    required String name,
  });

  /// Logout user
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> logout();

  /// Refresh authentication token
  /// Returns Either<Failure, AuthResult>
  Future<Either<Failure, AuthResult>> refreshToken();

  /// Forgot password
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> forgotPassword(String email);

  /// Reset password
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Check if user is authenticated
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> isAuthenticated();

  /// Get current user
  /// Returns Either<Failure, User>
  Future<Either<Failure, dynamic>> getCurrentUser();
}

/// Authentication result
class AuthResult extends BaseModel {
  final String? token;
  final String? refreshToken;
  final dynamic user;
  final bool success;
  final String? message;

  const AuthResult({
    this.token,
    this.refreshToken,
    this.user,
    required this.success,
    this.message,
  });

  factory AuthResult.success({
    String? token,
    String? refreshToken,
    dynamic user,
    String? message,
  }) {
    return AuthResult(
      token: token,
      refreshToken: refreshToken,
      user: user,
      success: true,
      message: message,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
      'success': success,
      'message': message,
    };
  }

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'],
      refreshToken: json['refreshToken'],
      user: json['user'],
      success: json['success'] as bool,
      message: json['message'],
    );
  }

  @override
  List<Object?> get props => [
        token,
        refreshToken,
        user,
        success,
        message,
      ];
}

/// Extension for Either utilities
extension EitherExtensions<L, R> on Either<L, R> {
  /// Map the right value if present
  Either<L, NewR> mapR<NewR>(NewR Function(R) fn) {
    return fold(
      (left) => Left(left),
      (right) => Right(fn(right)),
    );
  }

  /// Map the left value if present
  Either<NewL, R> mapL<NewL>(NewL Function(L) fn) {
    return fold(
      (left) => Left(fn(left)),
      (right) => Right(right),
    );
  }

  /// Execute an action if this is a Right value
  Future<void> ifRightR(Future<void> Function(R) action) async {
    final result = await fold(
      (left) async => null,
      (right) async => action(right),
    );
    return result;
  }

  /// Execute an action if this is a Left value
  Future<void> ifLeftL(Future<void> Function(L) action) async {
    final result = await fold(
      (left) async => action(left),
      (right) async => null,
    );
    return result;
  }
}