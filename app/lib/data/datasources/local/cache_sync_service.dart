import 'dart:async';
import '../remote/user_supabase_data_source.dart';
import '../remote/course_supabase_data_source.dart';
import '../remote/session_supabase_data_source.dart';
import '../remote/message_supabase_data_source.dart';
import '../remote/notification_supabase_data_source.dart';
import 'user_cache_data_source.dart';
import 'course_cache_data_source.dart';
import 'session_cache_data_source.dart';
import 'message_cache_data_source.dart';
import 'notification_cache_data_source.dart';

/// CacheSyncService - Handles synchronization between Supabase and SQLite
/// Provides offline-first functionality with automatic background sync
class CacheSyncService {
  // Remote data sources
  final UserSupabaseDataSource _userRemote = UserSupabaseDataSource();
  final CourseSupabaseDataSource _courseRemote = CourseSupabaseDataSource();
  final SessionSupabaseDataSource _sessionRemote = SessionSupabaseDataSource();
  final MessageSupabaseDataSource _messageRemote = MessageSupabaseDataSource();
  final NotificationSupabaseDataSource _notificationRemote = NotificationSupabaseDataSource();

  // Cache data sources
  final UserCacheDataSource _userCache = UserCacheDataSource();
  final CourseCacheDataSource _courseCache = CourseCacheDataSource();
  final SessionCacheDataSource _sessionCache = SessionCacheDataSource();
  final MessageCacheDataSource _messageCache = MessageCacheDataSource();
  final NotificationCacheDataSource _notificationCache = NotificationCacheDataSource();

  Timer? _syncTimer;
  bool _isSyncing = false;

  // ============================================================
  // INITIALIZATION & LIFECYCLE
  // ============================================================

  /// Start automatic background sync (every X minutes)
  void startAutoSync({int intervalMinutes = 5}) {
    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => syncAll(),
    );
  }

  /// Stop automatic background sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }

  // ============================================================
  // FULL SYNC
  // ============================================================

  /// Sync all data for a user
  Future<void> syncAll({String? userId}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (userId != null) {
        await Future.wait([
          syncUserProfile(userId),
          syncUserCourses(userId),
          syncUserSessions(userId),
          syncUserMessages(userId),
          syncUserNotifications(userId),
        ]);
      } else {
        // Sync without user context (e.g., public courses)
        await syncPublicCourses();
      }
    } catch (e) {
      print('CacheSyncService: Error during sync - $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  // ============================================================
  // USER PROFILE SYNC
  // ============================================================

  /// Sync user profile
  Future<void> syncUserProfile(String userId) async {
    try {
      // Check if cache needs update
      final needsUpdate = await _userCache.needsSync(userId);
      if (!needsUpdate) return;

      // Fetch from Supabase
      final profile = await _userRemote.getProfile(userId);
      
      // Update cache
      await _userCache.cacheProfile(profile);
    } catch (e) {
      print('CacheSyncService: Error syncing user profile - $e');
      // Don't rethrow - allow other syncs to continue
    }
  }

  /// Sync multiple user profiles
  Future<void> syncUserProfiles(List<String> userIds) async {
    try {
      final profiles = <Map<String, dynamic>>[];

      for (final userId in userIds) {
        try {
          final profile = await _userRemote.getProfile(userId);
          profiles.add(profile);
        } catch (e) {
          print('CacheSyncService: Error fetching profile $userId - $e');
        }
      }

      if (profiles.isNotEmpty) {
        await _userCache.cacheProfiles(profiles);
      }
    } catch (e) {
      print('CacheSyncService: Error syncing user profiles - $e');
    }
  }

  // ============================================================
  // COURSE SYNC
  // ============================================================

  /// Sync public courses
  Future<void> syncPublicCourses({int limit = 50}) async {
    try {
      final courses = await _courseRemote.getPublishedCourses(limit: limit);
      await _courseCache.cacheCourses(courses);
    } catch (e) {
      print('CacheSyncService: Error syncing public courses - $e');
    }
  }

  /// Sync user's courses (as tutor or student)
  Future<void> syncUserCourses(String userId) async {
    try {
      // Sync courses created by tutor
      final tutorCourses = await _courseRemote.getCoursesByTutor(userId);
      await _courseCache.cacheCourses(tutorCourses);

      // Sync enrolled courses
      final enrolledCourses = await _courseRemote.getEnrolledCourses(userId);
      await _courseCache.cacheCourses(enrolledCourses);

      // Sync course content for enrolled courses
      for (final course in enrolledCourses) {
        await syncCourseContent(course['id'] as String);
      }
    } catch (e) {
      print('CacheSyncService: Error syncing user courses - $e');
    }
  }

  /// Sync course content
  Future<void> syncCourseContent(String courseId) async {
    try {
      final contents = await _courseRemote.getCourseContent(courseId);
      await _courseCache.cacheContents(contents);
    } catch (e) {
      print('CacheSyncService: Error syncing course content - $e');
    }
  }

  /// Sync single course
  Future<void> syncCourse(String courseId) async {
    try {
      final course = await _courseRemote.getCourse(courseId);
      await _courseCache.cacheCourse(course);
      await syncCourseContent(courseId);
    } catch (e) {
      print('CacheSyncService: Error syncing course - $e');
    }
  }

  // ============================================================
  // SESSION SYNC
  // ============================================================

  /// Sync user's sessions
  Future<void> syncUserSessions(String userId) async {
    try {
      // Sync as tutor
      final tutorSessions = await _sessionRemote.getTutorSessions(userId);
      await _sessionCache.cacheSessions(tutorSessions);

      // Sync as student
      final studentSessions = await _sessionRemote.getStudentSessions(userId);
      await _sessionCache.cacheSessions(studentSessions);
    } catch (e) {
      print('CacheSyncService: Error syncing user sessions - $e');
    }
  }

  /// Sync upcoming sessions
  Future<void> syncUpcomingSessions(String userId) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: 30));

      final sessions = await _sessionRemote.getSessionsByDateRange(
        userId: userId,
        startDate: now.toIso8601String(),
        endDate: endDate.toIso8601String(),
      );

      await _sessionCache.cacheSessions(sessions);
    } catch (e) {
      print('CacheSyncService: Error syncing upcoming sessions - $e');
    }
  }

  /// Sync single session
  Future<void> syncSession(String sessionId) async {
    try {
      final session = await _sessionRemote.getSession(sessionId);
      await _sessionCache.cacheSession(session);
    } catch (e) {
      print('CacheSyncService: Error syncing session - $e');
    }
  }

  // ============================================================
  // MESSAGE SYNC
  // ============================================================

  /// Sync user's messages and conversations
  Future<void> syncUserMessages(String userId) async {
    try {
      // Sync conversations
      final conversations = await _messageRemote.getUserConversations(userId);
      await _messageCache.cacheConversations(conversations);

      // Sync messages for each conversation
      for (final conversation in conversations) {
        await syncConversationMessages(conversation['id'] as String);
      }
    } catch (e) {
      print('CacheSyncService: Error syncing user messages - $e');
    }
  }

  /// Sync messages for a conversation
  Future<void> syncConversationMessages(
    String conversationId, {
    int limit = 100,
  }) async {
    try {
      final messages = await _messageRemote.getConversationMessages(
        conversationId,
        limit: limit,
      );
      await _messageCache.cacheMessages(messages);
    } catch (e) {
      print('CacheSyncService: Error syncing conversation messages - $e');
    }
  }

  // ============================================================
  // NOTIFICATION SYNC
  // ============================================================

  /// Sync user's notifications
  Future<void> syncUserNotifications(String userId, {int limit = 50}) async {
    try {
      final notifications = await _notificationRemote.getUserNotifications(
        userId,
        limit: limit,
      );
      await _notificationCache.cacheNotifications(notifications);
    } catch (e) {
      print('CacheSyncService: Error syncing user notifications - $e');
    }
  }

  // ============================================================
  // CACHE OPERATIONS
  // ============================================================

  /// Clear all cache for a user
  Future<void> clearUserCache(String userId) async {
    try {
      await Future.wait([
        _userCache.deleteProfile(userId),
        _courseCache.clearAllCourses(),
        _sessionCache.clearAllSessions(),
        _messageCache.clearAllMessages(),
        _notificationCache.deleteUserNotifications(userId),
      ]);
    } catch (e) {
      print('CacheSyncService: Error clearing user cache - $e');
      rethrow;
    }
  }

  /// Clear all cache (use on logout)
  Future<void> clearAllCache() async {
    try {
      await Future.wait([
        _userCache.clearAllProfiles(),
        _courseCache.clearAllCourses(),
        _sessionCache.clearAllSessions(),
        _messageCache.clearAllMessages(),
        _notificationCache.clearAllNotifications(),
      ]);
    } catch (e) {
      print('CacheSyncService: Error clearing all cache - $e');
      rethrow;
    }
  }

  /// Clean old cache data
  Future<void> cleanOldCache({
    int messageDaysToKeep = 30,
    int notificationDaysToKeep = 30,
    int sessionDaysToKeep = 90,
  }) async {
    try {
      await Future.wait([
        _messageCache.deleteOldMessages(daysToKeep: messageDaysToKeep),
        _notificationCache.deleteOldNotifications(daysToKeep: notificationDaysToKeep),
        _sessionCache.deleteOldSessions(daysToKeep: sessionDaysToKeep),
      ]);
    } catch (e) {
      print('CacheSyncService: Error cleaning old cache - $e');
      rethrow;
    }
  }

  // ============================================================
  // CACHE STATISTICS
  // ============================================================

  /// Get overall cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final results = await Future.wait([
        _userCache.getStats(),
        _courseCache.getStats(),
        _sessionCache.getStats(),
        _messageCache.getStats(),
        _notificationCache.getStats(),
      ]);

      return {
        'users': results[0],
        'courses': results[1],
        'sessions': results[2],
        'messages': results[3],
        'notifications': results[4],
        'last_sync': DateTime.now().toIso8601String(),
        'is_syncing': _isSyncing,
      };
    } catch (e) {
      print('CacheSyncService: Error getting cache stats - $e');
      return {};
    }
  }

  // ============================================================
  // OFFLINE OPERATIONS
  // ============================================================

  /// Mark data as pending sync (for offline writes)
  /// In a production app, you would track offline changes and sync them
  /// when connection is restored
  Future<void> queueOfflineOperation({
    required String operation,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    // TODO: Implement offline operation queue
    // This would store operations in a queue table and sync them later
    print('CacheSyncService: Queued offline operation - $operation on $entityType');
  }

  /// Process offline operation queue
  Future<void> processOfflineQueue() async {
    // TODO: Implement offline queue processing
    // This would sync all queued operations with Supabase
    print('CacheSyncService: Processing offline queue');
  }
}
