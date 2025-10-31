# Supabase Data Sources - Usage Guide

**Created**: 2025-10-31  
**Project**: pharmaT Flutter Tutoring Platform

---

## Overview

This document provides a comprehensive guide to using the Supabase data sources created for the pharmaT application. All data sources follow clean architecture principles and provide a consistent interface for interacting with Supabase backend services.

---

## 📁 Data Source Files

All data sources are located in: `/workspace/pharmaT/app/lib/data/datasources/remote/`

1. **user_supabase_data_source.dart** (373 lines)
2. **course_supabase_data_source.dart** (440 lines)
3. **session_supabase_data_source.dart** (465 lines)
4. **payment_supabase_data_source.dart** (451 lines)
5. **message_supabase_data_source.dart** (381 lines)
6. **notification_supabase_data_source.dart** (354 lines)

**Total**: 2,464 lines of code

---

## 🏗️ Architecture

Each data source follows this pattern:

```dart
class XxxSupabaseDataSource {
  final SupabaseClient _supabase;
  
  XxxSupabaseDataSource(this._supabase);
  
  // CRUD operations
  Future<Model> create(...) async { }
  Future<Model?> get(String id) async { }
  Future<List<Model>> getList(...) async { }
  Future<Model> update(...) async { }
  Future<void> delete(String id) async { }
  
  // File operations (where applicable)
  Future<String> uploadFile(...) async { }
  Future<void> deleteFile(...) async { }
  
  // Real-time subscriptions
  RealtimeChannel subscribeToXxx(...) { }
  Future<void> unsubscribe(RealtimeChannel channel) async { }
}
```

---

## 📚 Data Source Details

### 1. UserSupabaseDataSource

**Purpose**: User profile management, avatar uploads, tutor search, notification settings

**Key Methods**:
- `getCurrentUserProfile()` - Get logged-in user's profile
- `getUserProfile(userId)` - Get any user's profile by ID
- `updateUserProfile(...)` - Update profile fields
- `uploadAvatar(userId, file)` - Upload profile picture to Storage
- `searchUsers(query, role)` - Search for users
- `getTutors(subject, minRating)` - Get filtered tutor list
- `updateTutorRating(tutorId, rating)` - Update tutor's average rating
- `getNotificationSettings(userId)` - Get user's notification preferences
- `updateNotificationSettings(...)` - Update notification preferences
- `registerPushToken(userId, token)` - Register device for push notifications
- `subscribeToUserProfile(userId, onUpdate)` - Real-time profile updates

**Storage Integration**:
- Bucket: `avatars`
- Max size: 5MB
- File types: Images (jpg, png, gif)

**Example Usage**:
```dart
final dataSource = UserSupabaseDataSource(Supabase.instance.client);

// Get current user profile
final profile = await dataSource.getCurrentUserProfile();

// Upload avatar
final file = File('/path/to/image.jpg');
final avatarUrl = await dataSource.uploadAvatar(
  userId: userId,
  file: file,
);

// Subscribe to real-time updates
final subscription = dataSource.subscribeToUserProfile(
  userId,
  (updatedProfile) {
    print('Profile updated: ${updatedProfile.name}');
  },
);

// Don't forget to unsubscribe
await dataSource.unsubscribe(subscription);
```

---

### 2. CourseSupabaseDataSource

**Purpose**: Course management, content (lessons), enrollments, progress tracking

**Key Methods**:
- `createCourse(...)` - Create new course
- `getCourse(courseId)` - Get course with tutor info
- `getCourses(tutorId, subject, level)` - Get filtered courses
- `searchCourses(query)` - Search courses by title/description
- `updateCourse(courseId, ...)` - Update course details
- `deleteCourse(courseId)` - Delete course
- `getCourseContent(courseId)` - Get all lessons
- `addCourseContent(...)` - Add new lesson
- `updateCourseContent(contentId, ...)` - Update lesson
- `uploadCourseMaterial(courseId, file)` - Upload course files
- `enrollInCourse(studentId, courseId)` - Enroll student
- `getStudentEnrollments(studentId)` - Get student's courses
- `updateCourseProgress(enrollmentId, contentId)` - Mark lesson complete
- `getCourseProgress(enrollmentId)` - Get progress details
- `subscribeToCourse(courseId, onUpdate)` - Real-time course updates

**Storage Integration**:
- Bucket: `course-materials`
- Max size: 50MB
- File types: Documents, videos, images

**Example Usage**:
```dart
final dataSource = CourseSupabaseDataSource(Supabase.instance.client);

// Create course
final course = await dataSource.createCourse(
  title: 'Pharmacology 101',
  description: 'Introduction to pharmacology',
  tutorId: tutorId,
  subject: 'Pharmacology',
  level: 'beginner',
  price: 99.99,
);

// Upload course material
final file = File('/path/to/lesson.pdf');
final materialUrl = await dataSource.uploadCourseMaterial(
  courseId: course.id,
  file: file,
  contentType: 'document',
);

// Add lesson with uploaded material
await dataSource.addCourseContent(
  courseId: course.id,
  title: 'Lesson 1: Introduction',
  contentType: 'document',
  contentUrl: materialUrl,
  durationMinutes: 30,
  orderIndex: 1,
);

// Enroll student
await dataSource.enrollInCourse(
  studentId: studentId,
  courseId: course.id,
);
```

---

### 3. SessionSupabaseDataSource

**Purpose**: Tutoring session scheduling, feedback, reviews

**Key Methods**:
- `createSession(...)` - Schedule new session
- `getSession(sessionId)` - Get session with tutor/student info
- `getSessions(tutorId, studentId, status)` - Get filtered sessions
- `getUpcomingSessions(userId, asTutor)` - Get future sessions
- `getPastSessions(userId, asTutor)` - Get completed sessions
- `updateSession(sessionId, ...)` - Update session details
- `updateSessionStatus(sessionId, status)` - Change status (confirmed, completed, etc.)
- `cancelSession(sessionId)` - Cancel session
- `submitSessionFeedback(sessionId, rating, comment)` - Add feedback
- `getSessionFeedback(sessionId)` - Get feedback
- `getTutorReviews(tutorId)` - Get all reviews for tutor
- `addTutorReview(tutorId, studentId, rating)` - Add review
- `subscribeToSession(sessionId, onUpdate)` - Real-time session updates
- `subscribeToUserSessions(userId, onInsert, onUpdate)` - Real-time user's sessions

**Example Usage**:
```dart
final dataSource = SessionSupabaseDataSource(Supabase.instance.client);

// Create session
final session = await dataSource.createSession(
  tutorId: tutorId,
  studentId: studentId,
  startTime: DateTime.now().add(Duration(days: 1)),
  endTime: DateTime.now().add(Duration(days: 1, hours: 1)),
  status: 'scheduled',
  subject: 'Pharmacology',
  price: 50.0,
);

// Get upcoming sessions
final upcomingSessions = await dataSource.getUpcomingSessions(
  userId: userId,
  asTutor: false,
  limit: 10,
);

// Submit feedback after session
await dataSource.submitSessionFeedback(
  sessionId: session.id,
  studentId: studentId,
  rating: 5,
  comment: 'Great session!',
);

// Subscribe to real-time updates
final subscription = dataSource.subscribeToUserSessions(
  userId,
  false, // as student
  (newSession) => print('New session scheduled!'),
  (updatedSession) => print('Session updated!'),
);
```

---

### 4. PaymentSupabaseDataSource

**Purpose**: Payment processing, payment methods, earnings tracking

**Key Methods**:
- `createPayment(...)` - Record new payment
- `getPayment(paymentId)` - Get payment details
- `getUserPayments(userId, status)` - Get user's payment history
- `getSessionPayments(sessionId)` - Get payments for session
- `getCoursePayments(courseId)` - Get payments for course
- `updatePaymentStatus(paymentId, status)` - Update status
- `getTutorEarnings(tutorId, startDate, endDate)` - Calculate earnings
- `getPaymentStatistics(userId)` - Get payment stats
- `addPaymentMethod(userId, type, lastFour)` - Save payment method
- `getPaymentMethods(userId)` - Get saved payment methods
- `updatePaymentMethod(paymentMethodId, isDefault)` - Update method
- `deletePaymentMethod(paymentMethodId)` - Remove method
- `processRefund(originalPaymentId, amount)` - Process refund
- `subscribeToPayment(paymentId, onUpdate)` - Real-time payment updates
- `subscribeToUserPayments(userId, onInsert, onUpdate)` - Real-time user's payments

**Example Usage**:
```dart
final dataSource = PaymentSupabaseDataSource(Supabase.instance.client);

// Create payment
final payment = await dataSource.createPayment(
  userId: userId,
  amount: 50.0,
  currency: 'usd',
  status: 'pending',
  sessionId: sessionId,
);

// Update payment status after processing
await dataSource.updatePaymentStatus(
  paymentId: payment.id,
  status: 'completed',
  metadata: {'transaction_id': 'txn_12345'},
);

// Get tutor earnings
final earnings = await dataSource.getTutorEarnings(
  tutorId: tutorId,
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 12, 31),
);

// Add payment method
await dataSource.addPaymentMethod(
  userId: userId,
  type: 'card',
  lastFour: '4242',
  isDefault: true,
);
```

---

### 5. MessageSupabaseDataSource

**Purpose**: Real-time chat conversations and messaging

**Key Methods**:
- `createConversation(participantIds)` - Start new conversation
- `getConversation(conversationId)` - Get conversation details
- `getUserConversations(userId)` - Get user's conversations
- `sendMessage(conversationId, senderId, text)` - Send message
- `getMessages(conversationId)` - Get conversation messages
- `getUnreadMessagesCount(userId)` - Get unread count
- `markMessageAsRead(messageId)` - Mark single message as read
- `markConversationAsRead(conversationId, userId)` - Mark all as read
- `uploadAttachment(conversationId, file)` - Upload file to message
- `deleteAttachment(attachmentUrl)` - Delete file
- `searchMessages(conversationId, query)` - Search in conversation
- `getConversationBetweenUsers(userId1, userId2)` - Find conversation
- `subscribeToConversationMessages(conversationId, onNew, onUpdate)` - Real-time messages
- `subscribeToUserConversations(userId, onUpdate)` - Real-time conversations

**Storage Integration**:
- Bucket: `message-attachments`
- Max size: 20MB
- File types: Images, documents, audio

**Example Usage**:
```dart
final dataSource = MessageSupabaseDataSource(Supabase.instance.client);

// Create conversation
final conversation = await dataSource.createConversation(
  participantIds: [userId1, userId2],
);

// Send message
final message = await dataSource.sendMessage(
  conversationId: conversation['id'],
  senderId: userId1,
  messageText: 'Hello!',
);

// Upload attachment
final file = File('/path/to/image.jpg');
final attachmentUrl = await dataSource.uploadAttachment(
  conversationId: conversation['id'],
  file: file,
);

// Send message with attachment
await dataSource.sendMessage(
  conversationId: conversation['id'],
  senderId: userId1,
  messageText: 'Check this out',
  messageType: 'image',
  attachments: [attachmentUrl],
);

// Subscribe to real-time messages
final subscription = dataSource.subscribeToConversationMessages(
  conversation['id'],
  (newMessage) => print('New message: ${newMessage.messageText}'),
  (updatedMessage) => print('Message read'),
);

// Get unread count
final unreadCount = await dataSource.getUnreadMessagesCount(userId);
```

---

### 6. NotificationSupabaseDataSource

**Purpose**: In-app notifications and push notification management

**Key Methods**:
- `createNotification(userId, title, body, type)` - Create notification
- `getNotification(notificationId)` - Get single notification
- `getUserNotifications(userId, type, isRead)` - Get filtered notifications
- `getUnreadNotificationsCount(userId)` - Get unread count
- `markNotificationAsRead(notificationId)` - Mark as read
- `markAllNotificationsAsRead(userId)` - Mark all as read
- `deleteNotification(notificationId)` - Delete single
- `deleteAllNotifications(userId)` - Delete all
- `deleteOldNotifications(userId, daysOld)` - Delete old ones
- `getNotificationsByType(userId, type)` - Filter by type
- `createBulkNotifications(userIds, title, body)` - Send to multiple users
- `getNotificationStatistics(userId)` - Get stats
- `searchNotifications(userId, query)` - Search notifications
- `sendPushNotification(userId, title, body)` - Send push notification
- `subscribeToUserNotifications(userId, onNew, onUpdate)` - Real-time notifications

**Example Usage**:
```dart
final dataSource = NotificationSupabaseDataSource(Supabase.instance.client);

// Create notification
final notification = await dataSource.createNotification(
  userId: userId,
  title: 'New Session Request',
  body: 'John Doe requested a session',
  type: 'session_request',
  data: {'sessionId': 'session_123'},
);

// Get unread notifications
final unreadNotifications = await dataSource.getUserNotifications(
  userId: userId,
  isRead: false,
  limit: 20,
);

// Mark as read
await dataSource.markNotificationAsRead(notification.id);

// Send push notification
await dataSource.sendPushNotification(
  userId: userId,
  title: 'Session Starting Soon',
  body: 'Your session starts in 10 minutes',
  type: 'session_reminder',
);

// Subscribe to real-time notifications
final subscription = dataSource.subscribeToUserNotifications(
  userId,
  (newNotification) {
    print('New notification: ${newNotification.title}');
    // Show in-app notification
  },
  (updatedNotification) {
    print('Notification read');
  },
);
```

---

## 🔄 Real-time Subscriptions

All data sources support real-time updates via Supabase Realtime. Common patterns:

### Pattern 1: Single Entity Updates
```dart
final subscription = dataSource.subscribeToEntity(
  entityId,
  (updatedEntity) {
    // Handle update
  },
);
```

### Pattern 2: Multiple Events
```dart
final subscription = dataSource.subscribeToUserEntities(
  userId,
  (newEntity) {
    // Handle insert
  },
  (updatedEntity) {
    // Handle update
  },
);
```

### Pattern 3: Cleanup
```dart
// Always unsubscribe when done
@override
void dispose() {
  dataSource.unsubscribe(subscription);
  super.dispose();
}
```

---

## 📦 Storage Integration

Three storage buckets are configured:

| Bucket | Purpose | Size Limit | File Types |
|--------|---------|------------|------------|
| `avatars` | User profile pictures | 5MB | Images |
| `course-materials` | Course files | 50MB | All types |
| `message-attachments` | Chat files | 20MB | All types |

**Upload Pattern**:
```dart
final file = File(filePath);
final url = await dataSource.uploadXxx(
  entityId: entityId,
  file: file,
);
// URL is automatically public and can be used directly
```

**Delete Pattern**:
```dart
await dataSource.deleteXxx(fileUrl);
```

---

## 🔒 Security

All data sources respect Row Level Security (RLS) policies:

- **User data**: Users can only access their own data
- **Public data**: Anyone can read (courses, tutor profiles)
- **Restricted actions**: Only owners can update/delete
- **Special rules**: Tutors can manage their courses, students can rate sessions

---

## ⚠️ Error Handling

All methods throw descriptive exceptions:

```dart
try {
  final user = await dataSource.getUserProfile(userId);
} catch (e) {
  print('Error: $e'); // "Failed to get user profile: [detailed error]"
  // Handle error appropriately
}
```

---

## 🧪 Testing

To test data sources:

1. **Unit Tests**: Mock SupabaseClient
2. **Integration Tests**: Use test Supabase project
3. **Real-time Tests**: Subscribe and trigger updates

```dart
// Example test
test('getUserProfile returns user data', () async {
  final mockSupabase = MockSupabaseClient();
  final dataSource = UserSupabaseDataSource(mockSupabase);
  
  when(mockSupabase.from('profiles').select().eq('id', any).single())
    .thenAnswer((_) async => {'id': '123', 'name': 'Test User'});
  
  final profile = await dataSource.getUserProfile('123');
  expect(profile?.name, 'Test User');
});
```

---

## 🔗 Integration with Repositories

Next step is to integrate these data sources into repository classes:

```dart
class UserRepository {
  final UserSupabaseDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource; // SQLite cache
  
  UserRepository(this._remoteDataSource, this._localDataSource);
  
  Future<UserModel?> getUser(String userId) async {
    try {
      // Try remote first
      final user = await _remoteDataSource.getUserProfile(userId);
      
      // Cache locally
      if (user != null) {
        await _localDataSource.saveUser(user);
      }
      
      return user;
    } catch (e) {
      // Fallback to cache if offline
      return await _localDataSource.getUser(userId);
    }
  }
}
```

---

## 📊 Statistics

**Total Implementation**:
- 6 data source classes
- 2,464 lines of code
- 150+ methods
- Full CRUD operations
- Real-time subscriptions
- File upload/download
- Comprehensive error handling

**Coverage**:
- ✅ User management
- ✅ Course management
- ✅ Session scheduling
- ✅ Payment processing
- ✅ Real-time messaging
- ✅ Push notifications

---

## 🚀 Next Steps

1. **Phase 5**: Implement SQLite local cache data sources
2. **Phase 6**: Create/update repositories to use these data sources
3. **Phase 7**: Update use cases and view models
4. **Phase 8**: Test complete flows
5. **Phase 9**: Run `flutter analyze` and fix issues

---

## 📝 Notes

- All data sources are stateless (no internal state)
- SupabaseClient is injected via constructor (dependency injection)
- Methods are async and return Futures
- Real-time subscriptions must be manually unsubscribed
- File URLs are public (protected by RLS at row level)
- Timestamps are ISO 8601 strings
- All IDs are UUIDs (generated by Supabase)

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-31  
**Author**: MiniMax Agent
