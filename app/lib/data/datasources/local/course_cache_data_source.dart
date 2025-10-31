import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// CourseCacheDataSource - Manages course caching in SQLite
class CourseCacheDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================================
  // CREATE / UPDATE
  // ============================================================

  /// Cache a course
  Future<void> cacheCourse(Map<String, dynamic> course) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...course,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_courses',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple courses
  Future<void> cacheCourses(List<Map<String, dynamic>> courses) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final course in courses) {
      final cacheData = {
        ...course,
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      batch.insert(
        'cache_courses',
        cacheData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Cache course content
  Future<void> cacheContent(Map<String, dynamic> content) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...content,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_course_content',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple course contents
  Future<void> cacheContents(List<Map<String, dynamic>> contents) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final content in contents) {
      final cacheData = {
        ...content,
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      batch.insert(
        'cache_course_content',
        cacheData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Cache enrollment
  Future<void> cacheEnrollment(Map<String, dynamic> enrollment) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...enrollment,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_enrollments',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache course progress
  Future<void> cacheProgress(Map<String, dynamic> progress) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...progress,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_course_progress',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update cached course
  Future<void> updateCourse(String courseId, Map<String, dynamic> updates) async {
    final db = await _dbHelper.database;
    
    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.update(
      'cache_courses',
      updateData,
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  // ============================================================
  // READ / QUERY
  // ============================================================

  /// Get cached course by ID
  Future<Map<String, dynamic>?> getCourse(String courseId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_courses',
      where: 'id = ?',
      whereArgs: [courseId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get all cached courses
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_courses',
      orderBy: 'created_at DESC',
    );
  }

  /// Get published courses
  Future<List<Map<String, dynamic>>> getPublishedCourses() async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_courses',
      where: 'is_published = ?',
      whereArgs: [1],
      orderBy: 'rating DESC, total_enrollments DESC',
    );
  }

  /// Get courses by tutor
  Future<List<Map<String, dynamic>>> getCoursesByTutor(String tutorId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_courses',
      where: 'tutor_id = ?',
      whereArgs: [tutorId],
      orderBy: 'created_at DESC',
    );
  }

  /// Search courses
  Future<List<Map<String, dynamic>>> searchCourses({
    String? query,
    String? subject,
    String? level,
    double? maxPrice,
  }) async {
    final db = await _dbHelper.database;
    
    final where = <String>['is_published = ?'];
    final whereArgs = <dynamic>[1];

    if (query != null && query.isNotEmpty) {
      where.add('(title LIKE ? OR description LIKE ?)');
      final searchPattern = '%$query%';
      whereArgs.addAll([searchPattern, searchPattern]);
    }

    if (subject != null && subject.isNotEmpty) {
      where.add('subject = ?');
      whereArgs.add(subject);
    }

    if (level != null && level.isNotEmpty) {
      where.add('level = ?');
      whereArgs.add(level);
    }

    if (maxPrice != null) {
      where.add('price <= ?');
      whereArgs.add(maxPrice);
    }

    return await db.query(
      'cache_courses',
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'rating DESC, total_enrollments DESC',
    );
  }

  /// Get course content by course ID
  Future<List<Map<String, dynamic>>> getCourseContent(String courseId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_course_content',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'order_index ASC',
    );
  }

  /// Get student's enrolled courses
  Future<List<Map<String, dynamic>>> getEnrolledCourses(String studentId) async {
    final db = await _dbHelper.database;
    
    return await db.rawQuery('''
      SELECT c.* FROM cache_courses c
      INNER JOIN cache_enrollments e ON c.id = e.course_id
      WHERE e.student_id = ?
      ORDER BY e.enrolled_at DESC
    ''', [studentId]);
  }

  /// Get enrollment by ID
  Future<Map<String, dynamic>?> getEnrollment(String enrollmentId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_enrollments',
      where: 'id = ?',
      whereArgs: [enrollmentId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get student's progress for a course
  Future<List<Map<String, dynamic>>> getCourseProgress(String enrollmentId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_course_progress',
      where: 'enrollment_id = ?',
      whereArgs: [enrollmentId],
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete cached course
  Future<void> deleteCourse(String courseId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cache_courses',
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  /// Delete cached content
  Future<void> deleteContent(String contentId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cache_course_content',
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  /// Clear all cached courses
  Future<void> clearAllCourses() async {
    final db = await _dbHelper.database;
    await db.delete('cache_courses');
    await db.delete('cache_course_content');
    await db.delete('cache_enrollments');
    await db.delete('cache_course_progress');
  }

  // ============================================================
  // SYNC STATUS
  // ============================================================

  /// Check if course needs sync
  Future<bool> needsSync(String courseId, {int minutesThreshold = 30}) async {
    final course = await getCourse(courseId);
    if (course == null) return true;

    final lastSynced = DateTime.parse(course['last_synced_at'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastSynced).inMinutes;

    return difference >= minutesThreshold;
  }

  /// Update sync timestamp
  Future<void> updateSyncTimestamp(String courseId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_courses',
      {'last_synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final db = await _dbHelper.database;
    
    final coursesResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache_courses');
    final publishedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_courses WHERE is_published = ?',
      [1],
    );
    final contentsResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache_course_content');
    final enrollmentsResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache_enrollments');

    return {
      'total_courses': Sqflite.firstIntValue(coursesResult) ?? 0,
      'published_courses': Sqflite.firstIntValue(publishedResult) ?? 0,
      'total_contents': Sqflite.firstIntValue(contentsResult) ?? 0,
      'total_enrollments': Sqflite.firstIntValue(enrollmentsResult) ?? 0,
    };
  }
}
