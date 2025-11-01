import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/repositories/irepository.dart';
import '../models/user_model.dart';
import '../datasources/remote/user_supabase_data_source.dart';
import '../datasources/local/user_cache_data_source.dart';

/// User repository implementing offline-first pattern with Supabase and SQLite cache
class UserRepositoryImpl implements IOfflineFirstRepository<UserModel> {
  final UserSupabaseDataSource _remoteDataSource;
  final UserCacheDataSource _cacheDataSource;
  final Connectivity _connectivity;

  UserRepositoryImpl({
    required UserSupabaseDataSource remoteDataSource,
    required UserCacheDataSource cacheDataSource,
    Connectivity? connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _cacheDataSource = cacheDataSource,
        _connectivity = connectivity ?? Connectivity();

  @override
  String get repositoryName => 'UserRepository';

  /// Check if device has internet connection
  Future<bool> get _isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get user profile by ID with cache-first approach
  @override
  Future<Either<Failure, UserModel>> getById(String id) async {
    try {
      // Try to get from cache first
      final cachedUser = await _cacheDataSource.getProfile(id);
      
      if (cachedUser != null) {
        // Return cached data immediately
        final userModel = UserModel.fromJson(cachedUser);
        
        // Update from remote in background if online
        if (await _isOnline) {
          _updateCacheInBackground(id);
        }
        
        return Right(userModel);
      }

      // If not in cache, fetch from remote
      if (await _isOnline) {
        final remoteUser = await _remoteDataSource.getProfile(id);
        
        // Cache the result
        await _cacheDataSource.cacheProfile(remoteUser);
        
        return Right(UserModel.fromJson(remoteUser));
      } else {
        return Left(Failure(
          message: 'User not found in cache and device is offline',
          code: 'OFFLINE_NO_CACHE',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get user profile: $e',
        exception: e,
      ));
    }
  }

  /// Update cache in background without blocking
  Future<void> _updateCacheInBackground(String userId) async {
    try {
      final remoteUser = await _remoteDataSource.getProfile(userId);
      await _cacheDataSource.updateProfile(userId, remoteUser);
    } catch (e) {
      // Silent fail - cache will be updated on next sync
    }
  }

  /// Update user profile
  @override
  Future<Either<Failure, UserModel>> update(String id, UserModel entity) async {
    try {
      final updateData = entity.toJson();
      
      if (await _isOnline) {
        // Update remote first
        final updatedUser = await _remoteDataSource.updateProfile(id, updateData);
        
        // Update cache
        await _cacheDataSource.updateProfile(id, updatedUser);
        
        return Right(UserModel.fromJson(updatedUser));
      } else {
        // Update cache only when offline
        await _cacheDataSource.updateProfile(id, updateData);
        
        // TODO: Queue for sync when online
        
        return Right(entity);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to update user profile: $e',
        exception: e,
      ));
    }
  }

  /// Search tutors with filters (cache-first)
  Future<Either<Failure, List<UserModel>>> searchTutors({
    String? query,
    List<String>? subjects,
    double? minRating,
    double? maxHourlyRate,
  }) async {
    try {
      // Try cache first
      final cachedTutors = await _cacheDataSource.searchTutors(
        query: query,
        subject: subjects?.isNotEmpty == true ? subjects!.first : null,
        minRating: minRating,
        maxPrice: maxHourlyRate,
      );

      if (cachedTutors.isNotEmpty) {
        final tutorModels = cachedTutors
            .map((data) => UserModel.fromJson(data))
            .toList();
        
        // Update from remote in background if online
        if (await _isOnline) {
          _updateTutorCacheInBackground(
            query: query,
            subjects: subjects,
            minRating: minRating,
            maxHourlyRate: maxHourlyRate,
          );
        }
        
        return Right(tutorModels);
      }

      // Fetch from remote if cache is empty
      if (await _isOnline) {
        final remoteTutors = await _remoteDataSource.searchTutors(
          query: query,
          subjects: subjects,
          minRating: minRating,
          maxHourlyRate: maxHourlyRate,
        );
        
        // Cache the results
        for (final tutor in remoteTutors) {
          await _cacheDataSource.cacheProfile(tutor);
        }
        
        return Right(remoteTutors.map((data) => UserModel.fromJson(data)).toList());
      } else {
        return Left(Failure(
          message: 'No tutors found in cache and device is offline',
          code: 'OFFLINE_NO_CACHE',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to search tutors: $e',
        exception: e,
      ));
    }
  }

  /// Update tutor cache in background
  Future<void> _updateTutorCacheInBackground({
    String? query,
    List<String>? subjects,
    double? minRating,
    double? maxHourlyRate,
  }) async {
    try {
      final remoteTutors = await _remoteDataSource.searchTutors(
        query: query,
        subjects: subjects,
        minRating: minRating,
        maxHourlyRate: maxHourlyRate,
      );
      
      for (final tutor in remoteTutors) {
        await _cacheDataSource.updateProfile(tutor['user_id'], tutor);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Upload avatar
  Future<Either<Failure, String>> uploadAvatar(String userId, String filePath) async {
    try {
      if (await _isOnline) {
        final avatarUrl = await _remoteDataSource.uploadAvatar(userId, filePath);
        
        // Update cache
        await _cacheDataSource.updateProfile(userId, {'avatar_url': avatarUrl});
        
        return Right(avatarUrl);
      } else {
        return Left(Failure(
          message: 'Cannot upload avatar while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to upload avatar: $e',
        exception: e,
      ));
    }
  }

  /// Delete avatar
  Future<Either<Failure, void>> deleteAvatar(String userId) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.deleteAvatar(userId);
        
        // Update cache
        await _cacheDataSource.updateProfile(userId, {'avatar_url': null});
        
        return const Right(null);
      } else {
        return Left(Failure(
          message: 'Cannot delete avatar while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to delete avatar: $e',
        exception: e,
      ));
    }
  }

  // Offline-first interface implementation
  
  @override
  Future<Either<Failure, SyncResult<UserModel>>> syncData() async {
    try {
      if (!await _isOnline) {
        return Left(Failure(
          message: 'Cannot sync while offline',
          code: 'OFFLINE',
        ));
      }

      // Get all cached profiles
      final cachedProfiles = await _cacheDataSource.getAllProfiles();
      
      final syncedItems = <UserModel>[];
      final failedItems = <String>[];

      for (final cached in cachedProfiles) {
        try {
          final userId = cached['user_id'] as String;
          final remoteUser = await _remoteDataSource.getProfile(userId);
          
          // Update cache with latest data
          await _cacheDataSource.updateProfile(userId, remoteUser);
          
          syncedItems.add(UserModel.fromJson(remoteUser));
        } catch (e) {
          failedItems.add(cached['user_id'] as String);
        }
      }

      return Right(SyncResult(
        syncedItems: syncedItems,
        failedItems: failedItems,
        totalSynced: syncedItems.length,
        totalFailed: failedItems.length,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'Sync failed: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getOfflineData() async {
    try {
      final cachedProfiles = await _cacheDataSource.getAllProfiles();
      final userModels = cachedProfiles
          .map((data) => UserModel.fromJson(data))
          .toList();
      
      return Right(userModels);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveOfflineData(List<UserModel> data) async {
    try {
      for (final user in data) {
        await _cacheDataSource.cacheProfile(user.toJson());
      }
      
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to save offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isDataSynced() async {
    try {
      // Check if we have any cached data
      final cachedProfiles = await _cacheDataSource.getAllProfiles();
      return Right(cachedProfiles.isNotEmpty);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check sync status: $e',
        exception: e,
      ));
    }
  }

  // Base repository methods
  
  @override
  Future<Either<Failure, UserModel>> create(UserModel entity) async {
    return Left(Failure(
      message: 'User creation is handled by authentication service',
      code: 'UNSUPPORTED_OPERATION',
    ));
  }

  @override
  Future<Either<Failure, List<UserModel>>> getAll({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final offset = page != null && limit != null ? (page - 1) * limit : 0;
      final cachedProfiles = await _cacheDataSource.getAllProfiles(
        limit: limit,
        offset: offset,
      );
      
      final userModels = cachedProfiles
          .map((data) => UserModel.fromJson(data))
          .toList();
      
      return Right(userModels);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get all users: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> delete(String id) async {
    return Left(Failure(
      message: 'User deletion is not supported',
      code: 'UNSUPPORTED_OPERATION',
    ));
  }

  @override
  Future<Either<Failure, List<UserModel>>> search(String query) async {
    return searchTutors(query: query);
  }

  @override
  Future<Either<Failure, bool>> exists(String id) async {
    try {
      final profile = await _cacheDataSource.getProfile(id);
      return Right(profile != null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check if user exists: $e',
        exception: e,
      ));
    }
  }
}
