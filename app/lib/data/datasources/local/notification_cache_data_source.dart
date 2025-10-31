import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// NotificationCacheDataSource - Manages notification caching in SQLite
class NotificationCacheDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================================
  // CREATE / UPDATE
  // ============================================================

  /// Cache a notification
  Future<void> cacheNotification(Map<String, dynamic> notification) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...notification,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_notifications',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple notifications
  Future<void> cacheNotifications(List<Map<String, dynamic>> notifications) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final notification in notifications) {
      final cacheData = {
        ...notification,
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      batch.insert(
        'cache_notifications',
        cacheData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_notifications',
      {
        'is_read': 1,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_notifications',
      {
        'is_read': 1,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ? AND is_read = ?',
      whereArgs: [userId, 0],
    );
  }

  // ============================================================
  // READ / QUERY
  // ============================================================

  /// Get notification by ID
  Future<Map<String, dynamic>?> getNotification(String notificationId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get all cached notifications
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_notifications',
      orderBy: 'created_at DESC',
    );
  }

  /// Get user's notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get unread notifications
  Future<List<Map<String, dynamic>>> getUnreadNotifications(String userId) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_notifications',
      where: 'user_id = ? AND is_read = ?',
      whereArgs: [userId, 0],
      orderBy: 'created_at DESC',
    );
  }

  /// Get notifications by type
  Future<List<Map<String, dynamic>>> getNotificationsByType(
    String userId,
    String type,
  ) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_notifications',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'created_at DESC',
    );
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_notifications WHERE user_id = ? AND is_read = ?',
      [userId, 0],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get notification count by type
  Future<Map<String, int>> getCountByType(String userId) async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery(
      'SELECT type, COUNT(*) as count FROM cache_notifications WHERE user_id = ? GROUP BY type',
      [userId],
    );

    final counts = <String, int>{};
    for (final row in results) {
      counts[row['type'] as String] = row['count'] as int;
    }

    return counts;
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cache_notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Delete all notifications for a user
  Future<void> deleteUserNotifications(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cache_notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Clear all cached notifications
  Future<void> clearAllNotifications() async {
    final db = await _dbHelper.database;
    await db.delete('cache_notifications');
  }

  /// Delete old notifications (older than X days)
  Future<void> deleteOldNotifications({int daysToKeep = 30}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();

    await db.delete(
      'cache_notifications',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  /// Delete read notifications older than X days
  Future<void> deleteOldReadNotifications({int daysToKeep = 7}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();

    await db.delete(
      'cache_notifications',
      where: 'is_read = ? AND created_at < ?',
      whereArgs: [1, cutoffDate],
    );
  }

  // ============================================================
  // SYNC STATUS
  // ============================================================

  /// Check if notifications need sync for a user
  Future<bool> needsSync(String userId, {int minutesThreshold = 5}) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_synced_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return true;

    final lastSynced = DateTime.parse(results.first['last_synced_at'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastSynced).inMinutes;

    return difference >= minutesThreshold;
  }

  /// Get stale notifications (need sync)
  Future<List<Map<String, dynamic>>> getStaleNotifications({
    int minutesThreshold = 30,
  }) async {
    final db = await _dbHelper.database;
    
    final cutoffTime = DateTime.now()
        .subtract(Duration(minutes: minutesThreshold))
        .toIso8601String();

    return await db.query(
      'cache_notifications',
      where: 'last_synced_at < ?',
      whereArgs: [cutoffTime],
    );
  }

  /// Update sync timestamp for user's notifications
  Future<void> updateSyncTimestamp(String userId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_notifications',
      {'last_synced_at': DateTime.now().toIso8601String()},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_notifications',
    );
    final unreadResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_notifications WHERE is_read = ?',
      [0],
    );
    final readResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_notifications WHERE is_read = ?',
      [1],
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'unread': Sqflite.firstIntValue(unreadResult) ?? 0,
      'read': Sqflite.firstIntValue(readResult) ?? 0,
    };
  }

  /// Get user notification statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_notifications WHERE user_id = ?',
      [userId],
    );
    final unreadResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_notifications WHERE user_id = ? AND is_read = ?',
      [userId, 0],
    );
    
    final typeResult = await db.rawQuery(
      'SELECT type, COUNT(*) as count FROM cache_notifications WHERE user_id = ? GROUP BY type',
      [userId],
    );

    final byType = <String, int>{};
    for (final row in typeResult) {
      byType[row['type'] as String] = row['count'] as int;
    }

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'unread': Sqflite.firstIntValue(unreadResult) ?? 0,
      'by_type': byType,
    };
  }
}
