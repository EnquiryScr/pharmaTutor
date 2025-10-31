import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// SessionCacheDataSource - Manages session caching in SQLite
class SessionCacheDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================================
  // CREATE / UPDATE
  // ============================================================

  /// Cache a session
  Future<void> cacheSession(Map<String, dynamic> session) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...session,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_sessions',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple sessions
  Future<void> cacheSessions(List<Map<String, dynamic>> sessions) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final session in sessions) {
      final cacheData = {
        ...session,
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      batch.insert(
        'cache_sessions',
        cacheData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Cache session feedback
  Future<void> cacheFeedback(Map<String, dynamic> feedback) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...feedback,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_session_feedback',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update cached session
  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    final db = await _dbHelper.database;
    
    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.update(
      'cache_sessions',
      updateData,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Update session status
  Future<void> updateStatus(String sessionId, String status) async {
    await updateSession(sessionId, {'status': status});
  }

  // ============================================================
  // READ / QUERY
  // ============================================================

  /// Get cached session by ID
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get all cached sessions
  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_sessions',
      orderBy: 'scheduled_at DESC',
    );
  }

  /// Get tutor's sessions
  Future<List<Map<String, dynamic>>> getTutorSessions(
    String tutorId, {
    String? status,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = 'tutor_id = ?';
    List<dynamic> whereArgs = [tutorId];

    if (status != null && status.isNotEmpty) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    return await db.query(
      'cache_sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'scheduled_at DESC',
    );
  }

  /// Get student's sessions
  Future<List<Map<String, dynamic>>> getStudentSessions(
    String studentId, {
    String? status,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = 'student_id = ?';
    List<dynamic> whereArgs = [studentId];

    if (status != null && status.isNotEmpty) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    return await db.query(
      'cache_sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'scheduled_at DESC',
    );
  }

  /// Get upcoming sessions
  Future<List<Map<String, dynamic>>> getUpcomingSessions(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.query(
      'cache_sessions',
      where: '(tutor_id = ? OR student_id = ?) AND scheduled_at > ? AND status = ?',
      whereArgs: [userId, userId, now, 'scheduled'],
      orderBy: 'scheduled_at ASC',
    );
  }

  /// Get past sessions
  Future<List<Map<String, dynamic>>> getPastSessions(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.query(
      'cache_sessions',
      where: '(tutor_id = ? OR student_id = ?) AND (scheduled_at < ? OR status = ?)',
      whereArgs: [userId, userId, now, 'completed'],
      orderBy: 'scheduled_at DESC',
    );
  }

  /// Get sessions by date range
  Future<List<Map<String, dynamic>>> getSessionsByDateRange({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    final db = await _dbHelper.database;

    return await db.query(
      'cache_sessions',
      where: '(tutor_id = ? OR student_id = ?) AND scheduled_at BETWEEN ? AND ?',
      whereArgs: [userId, userId, startDate, endDate],
      orderBy: 'scheduled_at ASC',
    );
  }

  /// Get session feedback
  Future<Map<String, dynamic>?> getSessionFeedback(String sessionId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_session_feedback',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get all feedback for a tutor
  Future<List<Map<String, dynamic>>> getTutorFeedback(String tutorId) async {
    final db = await _dbHelper.database;

    return await db.rawQuery('''
      SELECT f.* FROM cache_session_feedback f
      INNER JOIN cache_sessions s ON f.session_id = s.id
      WHERE s.tutor_id = ?
      ORDER BY f.created_at DESC
    ''', [tutorId]);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete cached session
  Future<void> deleteSession(String sessionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cache_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Clear all cached sessions
  Future<void> clearAllSessions() async {
    final db = await _dbHelper.database;
    await db.delete('cache_sessions');
    await db.delete('cache_session_feedback');
  }

  /// Delete old completed sessions (older than X days)
  Future<void> deleteOldSessions({int daysToKeep = 90}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();

    await db.delete(
      'cache_sessions',
      where: 'status = ? AND scheduled_at < ?',
      whereArgs: ['completed', cutoffDate],
    );
  }

  // ============================================================
  // SYNC STATUS
  // ============================================================

  /// Check if session needs sync
  Future<bool> needsSync(String sessionId, {int minutesThreshold = 30}) async {
    final session = await getSession(sessionId);
    if (session == null) return true;

    final lastSynced = DateTime.parse(session['last_synced_at'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastSynced).inMinutes;

    return difference >= minutesThreshold;
  }

  /// Update sync timestamp
  Future<void> updateSyncTimestamp(String sessionId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_sessions',
      {'last_synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache_sessions');
    final scheduledResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_sessions WHERE status = ?',
      ['scheduled'],
    );
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_sessions WHERE status = ?',
      ['completed'],
    );
    final feedbackResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache_session_feedback');

    return {
      'total_sessions': Sqflite.firstIntValue(totalResult) ?? 0,
      'scheduled': Sqflite.firstIntValue(scheduledResult) ?? 0,
      'completed': Sqflite.firstIntValue(completedResult) ?? 0,
      'total_feedback': Sqflite.firstIntValue(feedbackResult) ?? 0,
    };
  }

  /// Get tutor session statistics
  Future<Map<String, dynamic>> getTutorStats(String tutorId) async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_sessions WHERE tutor_id = ?',
      [tutorId],
    );
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_sessions WHERE tutor_id = ? AND status = ?',
      [tutorId, 'completed'],
    );
    final avgRatingResult = await db.rawQuery(
      '''SELECT AVG(f.rating) as avg_rating FROM cache_session_feedback f
         INNER JOIN cache_sessions s ON f.session_id = s.id
         WHERE s.tutor_id = ?''',
      [tutorId],
    );

    return {
      'total_sessions': Sqflite.firstIntValue(totalResult) ?? 0,
      'completed_sessions': Sqflite.firstIntValue(completedResult) ?? 0,
      'average_rating': avgRatingResult.first['avg_rating'] ?? 0.0,
    };
  }
}
