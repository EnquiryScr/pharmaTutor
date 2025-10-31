import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseHelper - Singleton class to manage SQLite database
/// Provides offline caching for Supabase data
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pharmaT_cache.db');
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all cache tables
  Future<void> _createDB(Database db, int version) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');

    // Profiles table (cache for user profiles)
    await db.execute('''
      CREATE TABLE cache_profiles (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        full_name TEXT,
        role TEXT NOT NULL,
        avatar_url TEXT,
        bio TEXT,
        subjects TEXT,
        hourly_rate REAL,
        rating REAL,
        total_sessions INTEGER DEFAULT 0,
        total_students INTEGER DEFAULT 0,
        is_verified INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        phone TEXT,
        location TEXT,
        timezone TEXT,
        languages TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL
      )
    ''');

    // Courses table (cache for courses)
    await db.execute('''
      CREATE TABLE cache_courses (
        id TEXT PRIMARY KEY,
        tutor_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        subject TEXT NOT NULL,
        level TEXT NOT NULL,
        price REAL NOT NULL,
        duration_weeks INTEGER,
        max_students INTEGER,
        thumbnail_url TEXT,
        is_published INTEGER DEFAULT 0,
        total_enrollments INTEGER DEFAULT 0,
        rating REAL,
        total_reviews INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (tutor_id) REFERENCES cache_profiles (id) ON DELETE CASCADE
      )
    ''');

    // Course content table
    await db.execute('''
      CREATE TABLE cache_course_content (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        content_type TEXT NOT NULL,
        content_url TEXT,
        duration_minutes INTEGER,
        order_index INTEGER NOT NULL,
        is_free INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES cache_courses (id) ON DELETE CASCADE
      )
    ''');

    // Enrollments table
    await db.execute('''
      CREATE TABLE cache_enrollments (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        course_id TEXT NOT NULL,
        status TEXT NOT NULL,
        progress_percentage REAL DEFAULT 0,
        completed_at TEXT,
        enrolled_at TEXT NOT NULL,
        last_accessed_at TEXT,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES cache_profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES cache_courses (id) ON DELETE CASCADE
      )
    ''');

    // Course progress table
    await db.execute('''
      CREATE TABLE cache_course_progress (
        id TEXT PRIMARY KEY,
        enrollment_id TEXT NOT NULL,
        content_id TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        time_spent_minutes INTEGER DEFAULT 0,
        last_position TEXT,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (enrollment_id) REFERENCES cache_enrollments (id) ON DELETE CASCADE,
        FOREIGN KEY (content_id) REFERENCES cache_course_content (id) ON DELETE CASCADE
      )
    ''');

    // Sessions table (cache for tutoring sessions)
    await db.execute('''
      CREATE TABLE cache_sessions (
        id TEXT PRIMARY KEY,
        tutor_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        course_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        scheduled_at TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        status TEXT NOT NULL,
        meeting_url TEXT,
        price REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (tutor_id) REFERENCES cache_profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES cache_profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES cache_courses (id) ON DELETE SET NULL
      )
    ''');

    // Session feedback table
    await db.execute('''
      CREATE TABLE cache_session_feedback (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES cache_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES cache_profiles (id) ON DELETE CASCADE
      )
    ''');

    // Messages table (cache for recent messages)
    await db.execute('''
      CREATE TABLE cache_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        attachment_url TEXT,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (sender_id) REFERENCES cache_profiles (id) ON DELETE CASCADE
      )
    ''');

    // Conversations table
    await db.execute('''
      CREATE TABLE cache_conversations (
        id TEXT PRIMARY KEY,
        participant_ids TEXT NOT NULL,
        last_message_id TEXT,
        last_message_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL
      )
    ''');

    // Notifications table (cache for notifications)
    await db.execute('''
      CREATE TABLE cache_notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES cache_profiles (id) ON DELETE CASCADE
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE cache_payments (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        session_id TEXT,
        course_id TEXT,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        status TEXT NOT NULL,
        payment_method TEXT,
        transaction_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES cache_profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (session_id) REFERENCES cache_sessions (id) ON DELETE SET NULL,
        FOREIGN KEY (course_id) REFERENCES cache_courses (id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for performance
    await _createIndexes(db);
  }

  /// Create indexes for frequently queried columns
  Future<void> _createIndexes(Database db) async {
    // Profile indexes
    await db.execute('CREATE INDEX idx_profiles_email ON cache_profiles(email)');
    await db.execute('CREATE INDEX idx_profiles_role ON cache_profiles(role)');

    // Course indexes
    await db.execute('CREATE INDEX idx_courses_tutor ON cache_courses(tutor_id)');
    await db.execute('CREATE INDEX idx_courses_subject ON cache_courses(subject)');
    await db.execute('CREATE INDEX idx_courses_published ON cache_courses(is_published)');

    // Enrollment indexes
    await db.execute('CREATE INDEX idx_enrollments_student ON cache_enrollments(student_id)');
    await db.execute('CREATE INDEX idx_enrollments_course ON cache_enrollments(course_id)');

    // Session indexes
    await db.execute('CREATE INDEX idx_sessions_tutor ON cache_sessions(tutor_id)');
    await db.execute('CREATE INDEX idx_sessions_student ON cache_sessions(student_id)');
    await db.execute('CREATE INDEX idx_sessions_scheduled ON cache_sessions(scheduled_at)');
    await db.execute('CREATE INDEX idx_sessions_status ON cache_sessions(status)');

    // Message indexes
    await db.execute('CREATE INDEX idx_messages_conversation ON cache_messages(conversation_id)');
    await db.execute('CREATE INDEX idx_messages_sender ON cache_messages(sender_id)');
    await db.execute('CREATE INDEX idx_messages_created ON cache_messages(created_at)');

    // Notification indexes
    await db.execute('CREATE INDEX idx_notifications_user ON cache_notifications(user_id)');
    await db.execute('CREATE INDEX idx_notifications_read ON cache_notifications(is_read)');
    await db.execute('CREATE INDEX idx_notifications_created ON cache_notifications(created_at)');

    // Payment indexes
    await db.execute('CREATE INDEX idx_payments_user ON cache_payments(user_id)');
    await db.execute('CREATE INDEX idx_payments_status ON cache_payments(status)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future schema migrations will go here
    if (oldVersion < 2) {
      // Example: Add new column in version 2
      // await db.execute('ALTER TABLE cache_profiles ADD COLUMN new_field TEXT');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  /// Clear all cached data (useful for logout)
  Future<void> clearAllCache() async {
    final db = await instance.database;
    
    final tables = [
      'cache_profiles',
      'cache_courses',
      'cache_course_content',
      'cache_enrollments',
      'cache_course_progress',
      'cache_sessions',
      'cache_session_feedback',
      'cache_messages',
      'cache_conversations',
      'cache_notifications',
      'cache_payments',
    ];

    for (final table in tables) {
      await db.delete(table);
    }
  }

  /// Clear cache for a specific user
  Future<void> clearUserCache(String userId) async {
    final db = await instance.database;
    
    // Delete user-specific data
    await db.delete('cache_profiles', where: 'id = ?', whereArgs: [userId]);
    await db.delete('cache_notifications', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('cache_payments', where: 'user_id = ?', whereArgs: [userId]);
    
    // Delete related data as tutor
    await db.delete('cache_sessions', where: 'tutor_id = ?', whereArgs: [userId]);
    await db.delete('cache_courses', where: 'tutor_id = ?', whereArgs: [userId]);
    
    // Delete related data as student
    await db.delete('cache_sessions', where: 'student_id = ?', whereArgs: [userId]);
    await db.delete('cache_enrollments', where: 'student_id = ?', whereArgs: [userId]);
    await db.delete('cache_messages', where: 'sender_id = ?', whereArgs: [userId]);
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    final db = await instance.database;
    
    final stats = <String, int>{};
    
    final tables = [
      'cache_profiles',
      'cache_courses',
      'cache_sessions',
      'cache_messages',
      'cache_notifications',
      'cache_payments',
    ];

    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = Sqflite.firstIntValue(result) ?? 0;
    }

    return stats;
  }

  /// Delete old cache entries (older than specified days)
  Future<void> deleteOldCache({int daysToKeep = 30}) async {
    final db = await instance.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

    await db.delete(
      'cache_messages',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );

    await db.delete(
      'cache_notifications',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );
  }
}
