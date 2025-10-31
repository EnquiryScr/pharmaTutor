// Supabase dependencies initialization
// This file registers Supabase data sources, cache data sources, and repositories

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Remote data sources (Supabase)
import '../../data/datasources/remote/user_supabase_data_source.dart';
import '../../data/datasources/remote/course_supabase_data_source.dart';
import '../../data/datasources/remote/session_supabase_data_source.dart';
import '../../data/datasources/remote/message_supabase_data_source.dart';
import '../../data/datasources/remote/notification_supabase_data_source.dart';

// Local data sources (SQLite Cache)
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/user_cache_data_source.dart';
import '../../data/datasources/local/course_cache_data_source.dart';
import '../../data/datasources/local/session_cache_data_source.dart';
import '../../data/datasources/local/message_cache_data_source.dart';
import '../../data/datasources/local/notification_cache_data_source.dart';
import '../../data/datasources/local/cache_sync_service.dart';
import '../../data/datasources/local/offline_queue_manager.dart';

// Repositories
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';

/// Singleton class to manage Supabase dependencies
class SupabaseDependencies {
  static final SupabaseDependencies _instance = SupabaseDependencies._internal();
  factory SupabaseDependencies() => _instance;
  SupabaseDependencies._internal();

  // Supabase client
  late final SupabaseClient _supabaseClient;

  // Remote data sources
  late final UserSupabaseDataSource _userRemoteDataSource;
  late final CourseSupabaseDataSource _courseRemoteDataSource;
  late final SessionSupabaseDataSource _sessionRemoteDataSource;
  late final MessageSupabaseDataSource _messageRemoteDataSource;
  late final NotificationSupabaseDataSource _notificationRemoteDataSource;

  // Cache data sources
  late final UserCacheDataSource _userCacheDataSource;
  late final CourseCacheDataSource _courseCacheDataSource;
  late final SessionCacheDataSource _sessionCacheDataSource;
  late final MessageCacheDataSource _messageCacheDataSource;
  late final NotificationCacheDataSource _notificationCacheDataSource;

  // Cache sync service
  late final CacheSyncService _cacheSyncService;

  // Offline queue manager
  late final OfflineQueueManager _offlineQueueManager;

  // Repositories
  late final UserRepositoryImpl _userRepository;
  late final CourseRepositoryImpl _courseRepository;
  late final SessionRepositoryImpl _sessionRepository;
  late final MessageRepositoryImpl _messageRepository;
  late final NotificationRepositoryImpl _notificationRepository;

  // Connectivity
  final Connectivity _connectivity = Connectivity();

  bool _initialized = false;

  /// Initialize all Supabase dependencies
  Future<void> initialize() async {
    if (_initialized) return;

    // Get Supabase client (should already be initialized in main.dart)
    _supabaseClient = Supabase.instance.client;

    // Initialize database helper
    final databaseHelper = DatabaseHelper.instance;
    await databaseHelper.database; // Ensure database is created

    // Initialize offline queue manager
    _offlineQueueManager = OfflineQueueManager();
    await _offlineQueueManager.initialize();
    _offlineQueueManager.startAutoProcessing();

    // Initialize remote data sources
    _userRemoteDataSource = UserSupabaseDataSource(_supabaseClient);
    _courseRemoteDataSource = CourseSupabaseDataSource(_supabaseClient);
    _sessionRemoteDataSource = SessionSupabaseDataSource(_supabaseClient);
    _messageRemoteDataSource = MessageSupabaseDataSource(_supabaseClient);
    _notificationRemoteDataSource = NotificationSupabaseDataSource(_supabaseClient);

    // Initialize cache data sources
    _userCacheDataSource = UserCacheDataSource();
    _courseCacheDataSource = CourseCacheDataSource();
    _sessionCacheDataSource = SessionCacheDataSource();
    _messageCacheDataSource = MessageCacheDataSource();
    _notificationCacheDataSource = NotificationCacheDataSource();

    // Initialize cache sync service
    _cacheSyncService = CacheSyncService(
      userRemoteDataSource: _userRemoteDataSource,
      courseRemoteDataSource: _courseRemoteDataSource,
      sessionRemoteDataSource: _sessionRemoteDataSource,
      messageRemoteDataSource: _messageRemoteDataSource,
      notificationRemoteDataSource: _notificationRemoteDataSource,
      userCacheDataSource: _userCacheDataSource,
      courseCacheDataSource: _courseCacheDataSource,
      sessionCacheDataSource: _sessionCacheDataSource,
      messageCacheDataSource: _messageCacheDataSource,
      notificationCacheDataSource: _notificationCacheDataSource,
    );

    // Initialize repositories
    _userRepository = UserRepositoryImpl(
      remoteDataSource: _userRemoteDataSource,
      cacheDataSource: _userCacheDataSource,
      connectivity: _connectivity,
    );

    _courseRepository = CourseRepositoryImpl(
      remoteDataSource: _courseRemoteDataSource,
      cacheDataSource: _courseCacheDataSource,
      connectivity: _connectivity,
    );

    _sessionRepository = SessionRepositoryImpl(
      remoteDataSource: _sessionRemoteDataSource,
      cacheDataSource: _sessionCacheDataSource,
      connectivity: _connectivity,
    );

    _messageRepository = MessageRepositoryImpl(
      remoteDataSource: _messageRemoteDataSource,
      cacheDataSource: _messageCacheDataSource,
      connectivity: _connectivity,
    );

    _notificationRepository = NotificationRepositoryImpl(
      remoteDataSource: _notificationRemoteDataSource,
      cacheDataSource: _notificationCacheDataSource,
      connectivity: _connectivity,
    );

    _initialized = true;
  }

  /// Start background sync for authenticated user
  Future<void> startBackgroundSync(String userId) async {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    
    await _cacheSyncService.startPeriodicSync(
      userId: userId,
      intervalMinutes: 5,
    );
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _cacheSyncService.stopPeriodicSync();
  }

  /// Perform manual sync
  Future<void> syncNow(String userId) async {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    
    await _cacheSyncService.syncAllUserData(userId);
  }

  /// Process offline queue manually
  Future<void> processOfflineQueue() async {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    
    await _offlineQueueManager.processQueue();
  }

  /// Get offline queue size
  Future<int> getOfflineQueueSize() async {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    
    return await _offlineQueueManager.getQueueSize();
  }

  // Getters for repositories
  UserRepositoryImpl get userRepository {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    return _userRepository;
  }

  CourseRepositoryImpl get courseRepository {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    return _courseRepository;
  }

  SessionRepositoryImpl get sessionRepository {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    return _sessionRepository;
  }

  MessageRepositoryImpl get messageRepository {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    return _messageRepository;
  }

  NotificationRepositoryImpl get notificationRepository {
    if (!_initialized) {
      throw StateError('SupabaseDependencies not initialized. Call initialize() first.');
    }
    return _notificationRepository;
  }

  // Getters for remote data sources
  UserSupabaseDataSource get userRemoteDataSource => _userRemoteDataSource;
  CourseSupabaseDataSource get courseRemoteDataSource => _courseRemoteDataSource;
  SessionSupabaseDataSource get sessionRemoteDataSource => _sessionRemoteDataSource;
  MessageSupabaseDataSource get messageRemoteDataSource => _messageRemoteDataSource;
  NotificationSupabaseDataSource get notificationRemoteDataSource => _notificationRemoteDataSource;

  // Getters for cache data sources
  UserCacheDataSource get userCacheDataSource => _userCacheDataSource;
  CourseCacheDataSource get courseCacheDataSource => _courseCacheDataSource;
  SessionCacheDataSource get sessionCacheDataSource => _sessionCacheDataSource;
  MessageCacheDataSource get messageCacheDataSource => _messageCacheDataSource;
  NotificationCacheDataSource get notificationCacheDataSource => _notificationCacheDataSource;

  // Getter for sync service
  CacheSyncService get cacheSyncService => _cacheSyncService;

  // Getter for offline queue manager
  OfflineQueueManager get offlineQueueManager => _offlineQueueManager;
}
