import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// UserCacheDataSource - Manages user profile caching in SQLite
class UserCacheDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================================
  // CREATE / UPDATE
  // ============================================================

  /// Cache a user profile
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...profile,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_profiles',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple profiles
  Future<void> cacheProfiles(List<Map<String, dynamic>> profiles) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final profile in profiles) {
      final cacheData = {
        ...profile,
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      batch.insert(
        'cache_profiles',
        cacheData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update cached profile
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    final db = await _dbHelper.database;
    
    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.update(
      'cache_profiles',
      updateData,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // READ / QUERY
  // ============================================================

  /// Get cached profile by user ID
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_profiles',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get all cached profiles
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final db = await _dbHelper.database;
    return await db.query('cache_profiles');
  }

  /// Search cached tutors
  Future<List<Map<String, dynamic>>> searchTutors({
    String? query,
    String? subject,
    double? minRating,
    double? maxPrice,
  }) async {
    final db = await _dbHelper.database;
    
    final where = <String>['role = ?'];
    final whereArgs = <dynamic>['tutor'];

    if (query != null && query.isNotEmpty) {
      where.add('(full_name LIKE ? OR bio LIKE ? OR subjects LIKE ?)');
      final searchPattern = '%$query%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }

    if (subject != null && subject.isNotEmpty) {
      where.add('subjects LIKE ?');
      whereArgs.add('%$subject%');
    }

    if (minRating != null) {
      where.add('rating >= ?');
      whereArgs.add(minRating);
    }

    if (maxPrice != null) {
      where.add('hourly_rate <= ?');
      whereArgs.add(maxPrice);
    }

    return await db.query(
      'cache_profiles',
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'rating DESC, total_sessions DESC',
    );
  }

  /// Get tutors by subject
  Future<List<Map<String, dynamic>>> getTutorsBySubject(String subject) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_profiles',
      where: 'role = ? AND subjects LIKE ?',
      whereArgs: ['tutor', '%$subject%'],
      orderBy: 'rating DESC',
    );
  }

  /// Get top-rated tutors
  Future<List<Map<String, dynamic>>> getTopTutors({int limit = 10}) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_profiles',
      where: 'role = ? AND rating IS NOT NULL',
      whereArgs: ['tutor'],
      orderBy: 'rating DESC, total_sessions DESC',
      limit: limit,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete cached profile
  Future<void> deleteProfile(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cache_profiles',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Clear all cached profiles
  Future<void> clearAllProfiles() async {
    final db = await _dbHelper.database;
    await db.delete('cache_profiles');
  }

  // ============================================================
  // SYNC STATUS
  // ============================================================

  /// Check if profile needs sync (older than X minutes)
  Future<bool> needsSync(String userId, {int minutesThreshold = 30}) async {
    final profile = await getProfile(userId);
    if (profile == null) return true;

    final lastSynced = DateTime.parse(profile['last_synced_at'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastSynced).inMinutes;

    return difference >= minutesThreshold;
  }

  /// Get profiles that need sync
  Future<List<Map<String, dynamic>>> getStaleProfiles({int minutesThreshold = 30}) async {
    final db = await _dbHelper.database;
    
    final cutoffTime = DateTime.now()
        .subtract(Duration(minutes: minutesThreshold))
        .toIso8601String();

    return await db.query(
      'cache_profiles',
      where: 'last_synced_at < ?',
      whereArgs: [cutoffTime],
    );
  }

  /// Update last synced timestamp
  Future<void> updateSyncTimestamp(String userId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_profiles',
      {'last_synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get cache statistics for profiles
  Future<Map<String, dynamic>> getStats() async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache_profiles');
    final tutorResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_profiles WHERE role = ?',
      ['tutor'],
    );
    final studentResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_profiles WHERE role = ?',
      ['student'],
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'tutors': Sqflite.firstIntValue(tutorResult) ?? 0,
      'students': Sqflite.firstIntValue(studentResult) ?? 0,
    };
  }
}
