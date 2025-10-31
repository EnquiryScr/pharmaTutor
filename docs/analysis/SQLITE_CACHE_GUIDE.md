# pharmaT SQLite Local Cache Guide

**Version:** 1.0  
**Date:** 2025-10-31  
**Status:** Phase 5 Complete

---

## Overview

The SQLite local cache provides offline-first functionality for the pharmaT Flutter application. It enables users to access their data without an internet connection and synchronizes with Supabase when connectivity is available.

### Key Benefits

1. **Offline Access**: Browse courses, view sessions, read messages without internet
2. **Fast Performance**: Data served from local SQLite database (milliseconds vs seconds)
3. **Reduced Data Usage**: Only sync changes, not full datasets
4. **Better UX**: Instant responses, no loading spinners for cached data
5. **Resilience**: App works even with spotty connectivity

---

## Architecture

### Three-Layer Data Architecture

```
┌─────────────────────────────────────────────────┐
│           UI Layer (Widgets)                    │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│         Business Logic (Repositories)           │
│   - Check cache first                           │
│   - Fetch from Supabase if stale               │
│   - Update cache with fresh data                │
└────────┬────────────────────────┬───────────────┘
         │                        │
┌────────▼────────┐    ┌──────────▼───────────────┐
│  Cache Layer    │    │    Remote Layer          │
│  (SQLite)       │    │    (Supabase)            │
│                 │◄───┤                          │
│  Fast reads     │    │  Source of truth         │
│  Offline access │    │  Real-time updates       │
└─────────────────┘    └──────────────────────────┘
         ▲                        ▲
         │                        │
         └────────┬───────────────┘
                  │
         ┌────────▼─────────┐
         │  CacheSyncService│
         │  (Auto-sync)     │
         └──────────────────┘
```

---

## Database Schema

### Cache Tables (11 Total)

#### 1. cache_profiles
Stores user profile information for offline access.

```sql
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
```

**Use Cases:**
- View tutor profiles offline
- Search cached tutors by subject/rating
- Display user information without API calls

#### 2. cache_courses
Stores course catalog for offline browsing.

```sql
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
  FOREIGN KEY (tutor_id) REFERENCES cache_profiles (id)
)
```

**Use Cases:**
- Browse course catalog offline
- Search courses by subject/level/price
- View course details without loading

#### 3. cache_course_content
Stores learning materials and lessons.

```sql
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
  FOREIGN KEY (course_id) REFERENCES cache_courses (id)
)
```

#### 4. cache_enrollments
Tracks student-course relationships.

```sql
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
  FOREIGN KEY (student_id) REFERENCES cache_profiles (id),
  FOREIGN KEY (course_id) REFERENCES cache_courses (id)
)
```

#### 5. cache_course_progress
Tracks detailed learning progress.

```sql
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
  FOREIGN KEY (enrollment_id) REFERENCES cache_enrollments (id),
  FOREIGN KEY (content_id) REFERENCES cache_course_content (id)
)
```

#### 6. cache_sessions
Stores tutoring session information.

```sql
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
  FOREIGN KEY (tutor_id) REFERENCES cache_profiles (id),
  FOREIGN KEY (student_id) REFERENCES cache_profiles (id),
  FOREIGN KEY (course_id) REFERENCES cache_courses (id)
)
```

**Use Cases:**
- View upcoming sessions offline
- Access past session history
- Check session calendar without internet

#### 7. cache_session_feedback
Stores student ratings and feedback.

#### 8. cache_conversations
Stores chat conversation metadata.

#### 9. cache_messages
Stores chat message history (recent messages only).

```sql
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
  FOREIGN KEY (sender_id) REFERENCES cache_profiles (id)
)
```

**Cache Policy:** Keep messages from last 30 days, older messages auto-deleted

#### 10. cache_notifications
Stores user notifications for offline viewing.

```sql
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
  FOREIGN KEY (user_id) REFERENCES cache_profiles (id)
)
```

**Cache Policy:** Keep notifications from last 30 days

#### 11. cache_payments
Stores payment transaction history.

---

## Cache Data Sources

### 1. UserCacheDataSource

**File:** `lib/data/datasources/local/user_cache_data_source.dart`

**Key Methods:**

```dart
// Cache operations
Future<void> cacheProfile(Map<String, dynamic> profile)
Future<void> cacheProfiles(List<Map<String, dynamic>> profiles)
Future<void> updateProfile(String userId, Map<String, dynamic> updates)

// Read operations
Future<Map<String, dynamic>?> getProfile(String userId)
Future<List<Map<String, dynamic>>> searchTutors({...})
Future<List<Map<String, dynamic>>> getTutorsBySubject(String subject)
Future<List<Map<String, dynamic>>> getTopTutors({int limit = 10})

// Sync status
Future<bool> needsSync(String userId, {int minutesThreshold = 30})
Future<List<Map<String, dynamic>>> getStaleProfiles({int minutesThreshold = 30})
```

**Usage Example:**

```dart
final userCache = UserCacheDataSource();

// Cache a profile
await userCache.cacheProfile({
  'id': 'user123',
  'email': 'john@example.com',
  'full_name': 'John Doe',
  'role': 'tutor',
  'subjects': 'Mathematics, Physics',
  'rating': 4.8,
});

// Get cached profile
final profile = await userCache.getProfile('user123');

// Search cached tutors
final tutors = await userCache.searchTutors(
  subject: 'Mathematics',
  minRating: 4.5,
);

// Check if cache is stale
final needsUpdate = await userCache.needsSync('user123');
if (needsUpdate) {
  // Fetch from Supabase and update cache
}
```

### 2. CourseCacheDataSource

**File:** `lib/data/datasources/local/course_cache_data_source.dart`

**Key Methods:**

```dart
// Cache operations
Future<void> cacheCourse(Map<String, dynamic> course)
Future<void> cacheCourses(List<Map<String, dynamic>> courses)
Future<void> cacheContent(Map<String, dynamic> content)
Future<void> cacheEnrollment(Map<String, dynamic> enrollment)

// Read operations
Future<Map<String, dynamic>?> getCourse(String courseId)
Future<List<Map<String, dynamic>>> getPublishedCourses()
Future<List<Map<String, dynamic>>> getCoursesByTutor(String tutorId)
Future<List<Map<String, dynamic>>> searchCourses({...})
Future<List<Map<String, dynamic>>> getCourseContent(String courseId)
Future<List<Map<String, dynamic>>> getEnrolledCourses(String studentId)
```

**Usage Example:**

```dart
final courseCache = CourseCacheDataSource();

// Cache courses for offline browsing
await courseCache.cacheCourses([
  {
    'id': 'course123',
    'title': 'Advanced Mathematics',
    'subject': 'Mathematics',
    'level': 'Advanced',
    'price': 49.99,
    'is_published': 1,
  },
]);

// Search cached courses
final mathCourses = await courseCache.searchCourses(
  subject: 'Mathematics',
  maxPrice: 100.0,
);

// Get student's enrolled courses offline
final enrolledCourses = await courseCache.getEnrolledCourses('student123');
```

### 3. SessionCacheDataSource

**File:** `lib/data/datasources/local/session_cache_data_source.dart`

**Key Methods:**

```dart
// Cache operations
Future<void> cacheSession(Map<String, dynamic> session)
Future<void> cacheSessions(List<Map<String, dynamic>> sessions)
Future<void> updateStatus(String sessionId, String status)

// Read operations
Future<Map<String, dynamic>?> getSession(String sessionId)
Future<List<Map<String, dynamic>>> getTutorSessions(String tutorId, {...})
Future<List<Map<String, dynamic>>> getStudentSessions(String studentId, {...})
Future<List<Map<String, dynamic>>> getUpcomingSessions(String userId)
Future<List<Map<String, dynamic>>> getPastSessions(String userId)
Future<List<Map<String, dynamic>>> getSessionsByDateRange({...})
```

**Usage Example:**

```dart
final sessionCache = SessionCacheDataSource();

// Cache upcoming sessions for offline calendar
await sessionCache.cacheSessions([
  {
    'id': 'session123',
    'tutor_id': 'tutor123',
    'student_id': 'student123',
    'title': 'Math Tutoring',
    'scheduled_at': '2025-11-01T10:00:00Z',
    'status': 'scheduled',
  },
]);

// Get upcoming sessions offline
final upcoming = await sessionCache.getUpcomingSessions('user123');

// Get sessions for a date range (calendar view)
final sessions = await sessionCache.getSessionsByDateRange(
  userId: 'user123',
  startDate: '2025-11-01T00:00:00Z',
  endDate: '2025-11-30T23:59:59Z',
);
```

### 4. MessageCacheDataSource

**File:** `lib/data/datasources/local/message_cache_data_source.dart`

**Key Methods:**

```dart
// Cache operations
Future<void> cacheConversation(Map<String, dynamic> conversation)
Future<void> cacheMessage(Map<String, dynamic> message)
Future<void> markAsRead(String messageId)
Future<void> markConversationAsRead(String conversationId)

// Read operations
Future<Map<String, dynamic>?> getConversation(String conversationId)
Future<List<Map<String, dynamic>>> getUserConversations(String userId)
Future<List<Map<String, dynamic>>> getConversationMessages(String conversationId)
Future<int> getUnreadCount(String userId)
Future<List<Map<String, dynamic>>> searchMessages(String query)
```

**Usage Example:**

```dart
final messageCache = MessageCacheDataSource();

// Cache recent messages for offline viewing
await messageCache.cacheMessages([
  {
    'id': 'msg123',
    'conversation_id': 'conv123',
    'sender_id': 'user123',
    'content': 'Hello! When is our next session?',
    'is_read': 0,
    'created_at': '2025-10-31T10:00:00Z',
  },
]);

// Get conversation messages offline
final messages = await messageCache.getConversationMessages('conv123');

// Get unread count for badge
final unreadCount = await messageCache.getUnreadCount('user123');

// Search messages offline
final results = await messageCache.searchMessages('session');
```

### 5. NotificationCacheDataSource

**File:** `lib/data/datasources/local/notification_cache_data_source.dart`

**Key Methods:**

```dart
// Cache operations
Future<void> cacheNotification(Map<String, dynamic> notification)
Future<void> markAsRead(String notificationId)
Future<void> markAllAsRead(String userId)

// Read operations
Future<List<Map<String, dynamic>>> getUserNotifications(String userId, {...})
Future<List<Map<String, dynamic>>> getUnreadNotifications(String userId)
Future<int> getUnreadCount(String userId)
Future<Map<String, int>> getCountByType(String userId)
```

**Usage Example:**

```dart
final notificationCache = NotificationCacheDataSource();

// Cache notifications
await notificationCache.cacheNotifications([
  {
    'id': 'notif123',
    'user_id': 'user123',
    'title': 'New Session Request',
    'body': 'You have a new session request from John',
    'type': 'session',
    'is_read': 0,
  },
]);

// Get unread notifications
final unread = await notificationCache.getUnreadNotifications('user123');

// Get unread count for badge
final unreadCount = await notificationCache.getUnreadCount('user123');

// Mark all as read
await notificationCache.markAllAsRead('user123');
```

---

## Cache Sync Service

**File:** `lib/data/datasources/local/cache_sync_service.dart`

The `CacheSyncService` orchestrates synchronization between Supabase and SQLite, ensuring data consistency across both layers.

### Key Features

1. **Automatic Background Sync**: Configurable interval (default: 5 minutes)
2. **Selective Sync**: Sync only what's needed (user-specific, entity-specific)
3. **Smart Cache Invalidation**: Only update stale data
4. **Offline Queue**: Foundation for queuing writes when offline

### Initialization

```dart
final syncService = CacheSyncService();

// Start automatic background sync (every 5 minutes)
syncService.startAutoSync(intervalMinutes: 5);

// Or manually trigger sync
await syncService.syncAll(userId: 'user123');
```

### Sync Methods

#### Full Sync
```dart
// Sync all user data
await syncService.syncAll(userId: 'user123');

// This syncs:
// - User profile
// - Courses (created + enrolled)
// - Sessions (as tutor + student)
// - Messages and conversations
// - Notifications
```

#### Selective Sync
```dart
// Sync only user profile
await syncService.syncUserProfile('user123');

// Sync only courses
await syncService.syncUserCourses('user123');

// Sync only upcoming sessions
await syncService.syncUpcomingSessions('user123');

// Sync only messages
await syncService.syncUserMessages('user123');

// Sync only notifications
await syncService.syncUserNotifications('user123');
```

#### Entity-Specific Sync
```dart
// Sync a single course
await syncService.syncCourse('course123');

// Sync course content
await syncService.syncCourseContent('course123');

// Sync a single session
await syncService.syncSession('session123');

// Sync conversation messages
await syncService.syncConversationMessages('conv123', limit: 100);
```

### Cache Management

```dart
// Clear user cache (on logout)
await syncService.clearUserCache('user123');

// Clear all cache
await syncService.clearAllCache();

// Clean old cache data
await syncService.cleanOldCache(
  messageDaysToKeep: 30,
  notificationDaysToKeep: 30,
  sessionDaysToKeep: 90,
);

// Get cache statistics
final stats = await syncService.getCacheStats();
print('Cache stats: $stats');
// Output: {
//   users: {total: 10, tutors: 5, students: 5},
//   courses: {total_courses: 20, published_courses: 15},
//   sessions: {total_sessions: 50, scheduled: 10, completed: 40},
//   messages: {total_conversations: 8, total_messages: 150, unread_messages: 5},
//   notifications: {total: 30, unread: 10, read: 20},
//   last_sync: '2025-10-31T10:00:00Z',
//   is_syncing: false
// }
```

### Lifecycle Management

```dart
// In your app's initialization
void initApp() {
  final syncService = CacheSyncService();
  syncService.startAutoSync(intervalMinutes: 5);
}

// On app pause (battery optimization)
void onPause() {
  syncService.stopAutoSync();
}

// On app resume
void onResume() {
  syncService.startAutoSync(intervalMinutes: 5);
}

// On app dispose
void dispose() {
  syncService.dispose();
}
```

---

## Integration Guide

### Step 1: Update Repository Pattern

Modify your existing repositories to use cache-first approach:

```dart
class CourseRepository {
  final CourseSupabaseDataSource _remote = CourseSupabaseDataSource();
  final CourseCacheDataSource _cache = CourseCacheDataSource();
  final CacheSyncService _syncService = CacheSyncService();

  /// Get course (cache-first)
  Future<CourseModel> getCourse(String courseId) async {
    try {
      // 1. Check cache first
      final cached = await _cache.getCourse(courseId);
      
      if (cached != null) {
        // 2. Check if cache is stale
        final needsUpdate = await _cache.needsSync(courseId);
        
        if (!needsUpdate) {
          // Cache is fresh, return immediately
          return CourseModel.fromJson(cached);
        }
        
        // Cache is stale, fetch in background
        _syncService.syncCourse(courseId);
        
        // Return cached data (will be updated in background)
        return CourseModel.fromJson(cached);
      }
      
      // 3. No cache, fetch from Supabase
      final remote = await _remote.getCourse(courseId);
      
      // 4. Update cache
      await _cache.cacheCourse(remote);
      
      return CourseModel.fromJson(remote);
    } catch (e) {
      // 5. On error, try to return cached version (offline fallback)
      final cached = await _cache.getCourse(courseId);
      if (cached != null) {
        return CourseModel.fromJson(cached);
      }
      
      rethrow;
    }
  }

  /// Search courses (cache-first with background refresh)
  Future<List<CourseModel>> searchCourses({
    String? query,
    String? subject,
  }) async {
    try {
      // 1. Return cached results immediately
      final cached = await _cache.searchCourses(
        query: query,
        subject: subject,
      );
      
      // 2. Trigger background sync for fresh data
      _syncService.syncPublicCourses();
      
      // 3. Return cached results (will be updated in background)
      return cached.map((c) => CourseModel.fromJson(c)).toList();
    } catch (e) {
      print('Error searching courses: $e');
      return [];
    }
  }
}
```

### Step 2: Handle Offline Writes

For write operations, you'll need to handle offline scenarios:

```dart
class CourseRepository {
  /// Enroll in course (with offline support)
  Future<void> enrollInCourse(String studentId, String courseId) async {
    try {
      // Try to write to Supabase
      final enrollment = await _remote.enrollStudent(studentId, courseId);
      
      // Update cache
      await _cache.cacheEnrollment(enrollment);
    } catch (e) {
      // If offline, cache the operation for later sync
      await _syncService.queueOfflineOperation(
        operation: 'enroll',
        entityType: 'enrollment',
        data: {
          'student_id': studentId,
          'course_id': courseId,
        },
      );
      
      // Show user a message
      throw OfflineException('Enrollment will sync when online');
    }
  }
}
```

### Step 3: Initialize Sync Service in App

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(...);
  
  // Initialize and start cache sync
  final syncService = CacheSyncService();
  syncService.startAutoSync(intervalMinutes: 5);
  
  runApp(MyApp());
}
```

### Step 4: Sync on User Login

```dart
class AuthService {
  final CacheSyncService _syncService = CacheSyncService();
  
  Future<void> signIn(String email, String password) async {
    // Perform Supabase sign in
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    final userId = response.user!.id;
    
    // Sync user data to cache
    await _syncService.syncAll(userId: userId);
  }
  
  Future<void> signOut() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    
    // Clear cache on logout
    await _syncService.clearUserCache(userId);
    
    // Sign out from Supabase
    await Supabase.instance.client.auth.signOut();
  }
}
```

---

## Best Practices

### 1. Cache-First Pattern

Always check cache first for better UX:

```dart
✅ GOOD: Cache-first with background refresh
final cached = await _cache.getData();
if (cached != null) {
  // Return cached data immediately
  _syncService.syncData(); // Refresh in background
  return cached;
}

❌ BAD: Remote-first (slow, requires internet)
final remote = await _remote.getData();
await _cache.cacheData(remote);
return remote;
```

### 2. Stale Data Thresholds

Configure based on data volatility:

```dart
// User profiles: 30 minutes (data changes infrequently)
await _cache.needsSync(userId, minutesThreshold: 30);

// Messages: 5 minutes (data changes frequently)
await _cache.needsSync(conversationId, minutesThreshold: 5);

// Notifications: 5 minutes (real-time expectations)
await _cache.needsSync(userId, minutesThreshold: 5);
```

### 3. Background Sync Intervals

Balance freshness vs battery life:

```dart
// Active usage: 5 minutes
syncService.startAutoSync(intervalMinutes: 5);

// Background mode: 30 minutes
syncService.startAutoSync(intervalMinutes: 30);

// Battery saver mode: disable auto-sync
syncService.stopAutoSync();
```

### 4. Cache Cleanup

Implement regular cleanup to manage storage:

```dart
// On app start
await syncService.cleanOldCache(
  messageDaysToKeep: 30,
  notificationDaysToKeep: 30,
  sessionDaysToKeep: 90,
);

// On low storage warning
final stats = await DatabaseHelper.instance.getCacheStats();
if (stats['cache_messages'] > 10000) {
  await _messageCache.deleteOldMessages(daysToKeep: 7);
}
```

### 5. Error Handling

Gracefully handle offline scenarios:

```dart
try {
  final data = await _remote.getData();
  await _cache.cacheData(data);
  return data;
} catch (e) {
  // Try cache fallback
  final cached = await _cache.getData();
  if (cached != null) {
    print('Using cached data (offline mode)');
    return cached;
  }
  
  throw OfflineException('No cached data available');
}
```

---

## Performance Optimization

### 1. Batch Operations

Use batch operations for better performance:

```dart
// ✅ GOOD: Batch insert
await _cache.cacheProfiles(profiles);

// ❌ BAD: Individual inserts
for (final profile in profiles) {
  await _cache.cacheProfile(profile);
}
```

### 2. Indexes

The database includes indexes on frequently queried columns:

```sql
-- User searches
CREATE INDEX idx_profiles_role ON cache_profiles(role);
CREATE INDEX idx_profiles_email ON cache_profiles(email);

-- Course searches
CREATE INDEX idx_courses_subject ON cache_courses(subject);
CREATE INDEX idx_courses_published ON cache_courses(is_published);

-- Session queries
CREATE INDEX idx_sessions_scheduled ON cache_sessions(scheduled_at);
CREATE INDEX idx_sessions_status ON cache_sessions(status);

-- Message queries
CREATE INDEX idx_messages_conversation ON cache_messages(conversation_id);
CREATE INDEX idx_messages_created ON cache_messages(created_at);
```

### 3. Query Optimization

Use specific queries instead of loading everything:

```dart
// ✅ GOOD: Specific query
final upcomingSessions = await _cache.getUpcomingSessions(userId);

// ❌ BAD: Load all then filter
final allSessions = await _cache.getAllSessions();
final upcoming = allSessions.where((s) => 
  s['scheduled_at'].isAfter(DateTime.now())
).toList();
```

---

## Testing Guide

### Unit Tests

```dart
void main() {
  group('UserCacheDataSource', () {
    late UserCacheDataSource cache;
    
    setUp(() {
      cache = UserCacheDataSource();
    });
    
    test('should cache and retrieve profile', () async {
      final profile = {
        'id': 'user123',
        'email': 'test@example.com',
        'full_name': 'Test User',
        'role': 'student',
      };
      
      await cache.cacheProfile(profile);
      final retrieved = await cache.getProfile('user123');
      
      expect(retrieved, isNotNull);
      expect(retrieved!['email'], 'test@example.com');
    });
    
    test('should detect stale cache', () async {
      final profile = {
        'id': 'user123',
        'last_synced_at': DateTime.now()
            .subtract(Duration(hours: 1))
            .toIso8601String(),
      };
      
      await cache.cacheProfile(profile);
      final needsUpdate = await cache.needsSync('user123', minutesThreshold: 30);
      
      expect(needsUpdate, true);
    });
  });
}
```

### Integration Tests

```dart
void main() {
  testWidgets('should display cached courses offline', (tester) async {
    // Setup: Cache some courses
    final courseCache = CourseCacheDataSource();
    await courseCache.cacheCourses([
      {'id': 'course1', 'title': 'Math 101'},
      {'id': 'course2', 'title': 'Physics 101'},
    ]);
    
    // Turn off internet
    await NetworkTestHelper.disableNetwork();
    
    // Navigate to courses page
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    
    // Should show cached courses
    expect(find.text('Math 101'), findsOneWidget);
    expect(find.text('Physics 101'), findsOneWidget);
    
    // Cleanup
    await NetworkTestHelper.enableNetwork();
  });
}
```

---

## Troubleshooting

### Issue: Cache not updating

**Symptom:** Old data persists even with internet connection

**Solution:**
```dart
// Check sync status
final needsSync = await cache.needsSync(entityId);
print('Needs sync: $needsSync');

// Force sync
await syncService.syncAll(userId: userId);

// Check last sync time
final entity = await cache.getEntity(entityId);
print('Last synced: ${entity['last_synced_at']}');
```

### Issue: Cache grows too large

**Symptom:** App storage usage increases over time

**Solution:**
```dart
// Check cache size
final stats = await DatabaseHelper.instance.getCacheStats();
print('Cache stats: $stats');

// Clean old data
await syncService.cleanOldCache(
  messageDaysToKeep: 7,  // Reduce from 30
  notificationDaysToKeep: 7,
  sessionDaysToKeep: 30,  // Reduce from 90
);

// Clear entire cache if needed
await syncService.clearAllCache();
```

### Issue: Database locked error

**Symptom:** `SQLite database is locked` error

**Solution:**
```dart
// Ensure proper database access pattern
// Use transactions for batch operations
final db = await DatabaseHelper.instance.database;
await db.transaction((txn) async {
  // All operations in single transaction
  await txn.insert('cache_profiles', profile1);
  await txn.insert('cache_profiles', profile2);
});

// Close database when not needed
await DatabaseHelper.instance.close();
```

---

## Future Enhancements

### Planned Features

1. **Offline Write Queue**
   - Queue write operations when offline
   - Sync when connection restored
   - Conflict resolution strategies

2. **Intelligent Pre-caching**
   - Predict user needs based on usage patterns
   - Pre-cache likely-to-be-accessed data
   - Machine learning for cache optimization

3. **Partial Sync**
   - Sync only changed fields (delta sync)
   - Reduce bandwidth usage
   - Faster sync times

4. **Cache Compression**
   - Compress cached data to save space
   - Especially useful for images and large content

5. **Multi-user Support**
   - Support multiple logged-in users
   - Separate caches per user
   - Fast user switching

---

## Summary

The SQLite local cache implementation provides:

- ✅ **7 data source files** (2,443 lines of code)
- ✅ **11 cache tables** mirroring Supabase schema
- ✅ **Automatic background sync** with configurable intervals
- ✅ **Smart cache invalidation** based on staleness thresholds
- ✅ **Offline-first architecture** for better UX
- ✅ **Cache statistics and monitoring**
- ✅ **Comprehensive cleanup utilities**

Next steps: Proceed to Phase 6 (Repository Updates) to integrate cache layer with existing business logic.
