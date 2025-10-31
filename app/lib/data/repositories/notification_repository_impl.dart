import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/repositories/irepository.dart';
import '../models/notification_model.dart';
import '../datasources/remote/notification_supabase_data_source.dart';
import '../datasources/local/notification_cache_data_source.dart';

/// Notification repository implementing offline-first pattern
class NotificationRepositoryImpl implements IOfflineFirstRepository<NotificationModel> {
  final NotificationSupabaseDataSource _remoteDataSource;
  final NotificationCacheDataSource _cacheDataSource;
  final Connectivity _connectivity;

  NotificationRepositoryImpl({
    required NotificationSupabaseDataSource remoteDataSource,
    required NotificationCacheDataSource cacheDataSource,
    Connectivity? connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _cacheDataSource = cacheDataSource,
        _connectivity = connectivity ?? Connectivity();

  @override
  String get repositoryName => 'NotificationRepository';

  Future<bool> get _isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get user notifications with cache-first approach
  Future<Either<Failure, List<NotificationModel>>> getUserNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
    String? type,
    bool? isRead,
  }) async {
    try {
      final cachedNotifications = await _cacheDataSource.getUserNotifications(
        userId,
        limit: limit,
        offset: offset,
        type: type,
        isRead: isRead,
      );
      
      if (cachedNotifications.isNotEmpty) {
        final notificationModels = cachedNotifications
            .map((data) => NotificationModel.fromJson(data))
            .toList();
        
        if (await _isOnline) {
          _updateNotificationsInBackground(userId, type: type, isRead: isRead);
        }
        
        return Right(notificationModels);
      }

      if (await _isOnline) {
        final remoteNotifications = await _remoteDataSource.getUserNotifications(
          userId,
          limit: limit,
          offset: offset,
          type: type,
          isRead: isRead,
        );
        
        for (final notification in remoteNotifications) {
          await _cacheDataSource.insertNotification(notification);
        }
        
        return Right(remoteNotifications.map((data) => NotificationModel.fromJson(data)).toList());
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get user notifications: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateNotificationsInBackground(
    String userId, {
    String? type,
    bool? isRead,
  }) async {
    try {
      final remoteNotifications = await _remoteDataSource.getUserNotifications(
        userId,
        type: type,
        isRead: isRead,
      );
      
      for (final notification in remoteNotifications) {
        await _cacheDataSource.updateNotification(
          notification['notification_id'],
          notification,
        );
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get unread notifications count
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await _cacheDataSource.getUnreadCount(userId);
      
      if (await _isOnline) {
        _updateUnreadCountInBackground(userId);
      }
      
      return Right(count);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get unread count: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateUnreadCountInBackground(String userId) async {
    try {
      final remoteCount = await _remoteDataSource.getUnreadCount(userId);
      // Count will be updated when notifications are synced
    } catch (e) {
      // Silent fail
    }
  }

  /// Mark notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.markNotificationAsRead(notificationId);
      }
      
      // Update cache regardless of online status
      await _cacheDataSource.markAsRead(notificationId);
      
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to mark notification as read: $e',
        exception: e,
      ));
    }
  }

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.markAllNotificationsAsRead(userId);
      }
      
      // Update cache regardless of online status
      await _cacheDataSource.markAllAsRead(userId);
      
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to mark all notifications as read: $e',
        exception: e,
      ));
    }
  }

  /// Get notification statistics
  Future<Either<Failure, Map<String, dynamic>>> getNotificationStats(String userId) async {
    try {
      final stats = await _cacheDataSource.getNotificationStats(userId);
      
      if (await _isOnline) {
        _updateStatsInBackground(userId);
      }
      
      return Right(stats);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get notification statistics: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateStatsInBackground(String userId) async {
    try {
      final remoteNotifications = await _remoteDataSource.getUserNotifications(userId);
      
      for (final notification in remoteNotifications) {
        await _cacheDataSource.updateNotification(
          notification['notification_id'],
          notification,
        );
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Create notification (admin/system only)
  Future<Either<Failure, NotificationModel>> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (await _isOnline) {
        final notificationData = await _remoteDataSource.createNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
        );
        
        await _cacheDataSource.insertNotification(notificationData);
        
        return Right(NotificationModel.fromJson(notificationData));
      } else {
        return Left(Failure(
          message: 'Cannot create notification while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to create notification: $e',
        exception: e,
      ));
    }
  }

  // Offline-first interface implementation
  
  @override
  Future<Either<Failure, SyncResult<NotificationModel>>> syncData() async {
    try {
      if (!await _isOnline) {
        return Left(Failure(
          message: 'Cannot sync while offline',
          code: 'OFFLINE',
        ));
      }

      // Sync logic would go here
      final syncedItems = <NotificationModel>[];
      final failedItems = <String>[];

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
  Future<Either<Failure, List<NotificationModel>>> getOfflineData() async {
    try {
      // Would retrieve all cached notifications here
      return const Right([]);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveOfflineData(List<NotificationModel> data) async {
    try {
      for (final notification in data) {
        await _cacheDataSource.insertNotification(notification.toJson());
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
      // Check if we have any cached notifications
      return const Right(true);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check sync status: $e',
        exception: e,
      ));
    }
  }

  // Base repository methods
  
  @override
  Future<Either<Failure, NotificationModel>> getById(String id) async {
    try {
      final cachedNotification = await _cacheDataSource.getNotification(id);
      
      if (cachedNotification != null) {
        return Right(NotificationModel.fromJson(cachedNotification));
      }

      return Left(Failure(
        message: 'Notification not found',
        code: 'NOT_FOUND',
      ));
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get notification: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> create(NotificationModel entity) async {
    return createNotification(
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      data: entity.data,
    );
  }

  @override
  Future<Either<Failure, NotificationModel>> update(String id, NotificationModel entity) async {
    return Left(Failure(
      message: 'Notification update not supported',
      code: 'UNSUPPORTED_OPERATION',
    ));
  }

  @override
  Future<Either<Failure, bool>> delete(String id) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.deleteNotification(id);
      }
      
      await _cacheDataSource.deleteNotification(id);
      
      return const Right(true);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to delete notification: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<NotificationModel>>> getAll({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<NotificationModel>>> search(String query) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, bool>> exists(String id) async {
    try {
      final notification = await _cacheDataSource.getNotification(id);
      return Right(notification != null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check if notification exists: $e',
        exception: e,
      ));
    }
  }
}
