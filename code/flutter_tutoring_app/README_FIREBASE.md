# Firebase Integration for Tutoring Platform

This document provides comprehensive documentation for the Firebase integration implemented for the tutoring platform. The integration includes authentication, Firestore database, Firebase Storage, Cloud Messaging, Analytics, Crashlytics, and offline synchronization.

## 📋 Table of Contents

- [Overview](#overview)
- [Services Implemented](#services-implemented)
- [Database Models](#database-models)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Security Rules](#security-rules)
- [Offline Synchronization](#offline-synchronization)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🔍 Overview

The Firebase integration provides a complete backend solution for the tutoring platform with the following features:

- **Authentication & User Management**: Email/password, Google, and Apple sign-in
- **Database Operations**: CRUD operations for users, assignments, queries, messages, articles, schedules
- **File Storage**: Profile pictures, assignment attachments, and educational content
- **Real-time Messaging**: Chat between tutors and students
- **Push Notifications**: Assignment updates, session reminders, and general notifications
- **Analytics & Crash Reporting**: User behavior tracking and error monitoring
- **Offline Support**: Caching and synchronization for offline functionality

## 🛠 Services Implemented

### 1. Firebase Service (`firebase_service.dart`)
Central service that manages all Firebase service initialization and configuration.

**Key Features:**
- Singleton pattern for centralized access
- Automatic service initialization
- Crashlytics and Analytics setup
- Cloud Messaging configuration
- Remote Config integration

### 2. Authentication Service (`auth_service.dart`)
Handles user registration, login, and profile management.

**Supported Methods:**
- Email/Password authentication
- Google Sign-in (placeholder for implementation)
- Password reset and email verification
- Profile updates
- Role-based access control

### 3. Firestore Service (`firestore_service.dart`)
Comprehensive database operations for all tutoring platform entities.

**Collections Supported:**
- `users` - User profiles and preferences
- `assignments` - Student assignments and submissions
- `queries` - Student questions and tutor responses
- `conversations` - Chat conversations between users
- `messages` - Individual chat messages
- `articles` - Educational content and tutorials
- `schedules` - Tutoring session appointments

### 4. Storage Service (`storage_service.dart`)
File upload and management for various content types.

**Supported File Types:**
- Profile pictures (JPEG, PNG, WebP)
- Assignment attachments (PDF, DOC, DOCX, images)
- Article content (various formats)
- Message attachments (images, audio, video)

### 5. Notification Service (`notification_service.dart`)
Push notification and local notification management.

**Notification Types:**
- New messages
- Assignment updates
- Session reminders
- Query responses
- General announcements

### 6. Analytics Service (`analytics_service.dart`)
User behavior tracking and engagement metrics.

**Tracked Events:**
- User registration and login
- Assignment creation and completion
- Query interactions
- Message sending
- Session scheduling
- Article views and engagement

### 7. Error Handling Service (`error_handling_service.dart`)
Comprehensive error management with retry logic.

**Features:**
- Exponential backoff retry mechanism
- Network connectivity monitoring
- Firebase-specific error handling
- User-friendly error messages
- Automatic error logging to Crashlytics

### 8. Offline Sync Service (`offline_sync_service.dart`)
Caching and synchronization for offline functionality.

**Capabilities:**
- Local SQLite database for caching
- Sync queue for pending operations
- Automatic synchronization when online
- Offline action recording
- Cache expiration management

## 📊 Database Models

### User Model
```dart
class User {
  final String id;
  final String email;
  final String displayName;
  final UserRole role; // student, tutor, admin
  final UserStatus status;
  final List<String> subjects;
  final double? rating;
  // ... additional fields
}
```

### Assignment Model
```dart
class Assignment {
  final String id;
  final String title;
  final String description;
  final String studentId;
  final String tutorId;
  final AssignmentStatus status;
  final Priority priority;
  final DateTime dueDate;
  // ... additional fields
}
```

### Query Model
```dart
class Query {
  final String id;
  final String title;
  final String description;
  final String studentId;
  final QueryType type;
  final QueryStatus status;
  final List<String> tags;
  // ... additional fields
}
```

### Message Model
```dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  // ... additional fields
}
```

### Article Model
```dart
class Article {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final ArticleType type;
  final DifficultyLevel difficulty;
  final int readCount;
  // ... additional fields
}
```

### Schedule Model
```dart
class Schedule {
  final String id;
  final String studentId;
  final String tutorId;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleStatus status;
  final ScheduleType type;
  // ... additional fields
}
```

## ⚙️ Configuration

### Basic Initialization
```dart
import 'package:your_app/data/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseConfiguration.instance.initialize(
    enableAnalytics: true,
    enableCrashlytics: true,
    enableNotifications: true,
    enableOfflineSync: true,
    isDebugMode: false,
  );
  
  runApp(MyApp());
}
```

### Environment Configuration
Update `firebase_config.dart` with your Firebase project details:

```dart
static const String projectId = 'your-firebase-project-id';
static const String apiKey = 'your-api-key';
static const String appId = 'your-app-id';
static const String messagingSenderId = 'your-messaging-sender-id';
```

## 📝 Usage Examples

### User Authentication
```dart
// Register new user
final result = await FirebaseConfiguration.instance.authService.signUpWithEmail(
  email: 'student@example.com',
  password: 'password123',
  displayName: 'John Doe',
  role: UserRole.student,
);

// Sign in user
final signInResult = await FirebaseConfiguration.instance.authService.signInWithEmail(
  email: 'student@example.com',
  password: 'password123',
);
```

### Database Operations
```dart
// Create assignment
final assignment = Assignment(
  id: '',
  title: 'Math Problem Set',
  description: 'Solve quadratic equations',
  studentId: 'user123',
  tutorId: 'tutor456',
  subject: 'Mathematics',
  status: AssignmentStatus.pending,
  priority: Priority.medium,
  dueDate: DateTime.now().add(Duration(days: 7)),
  attachments: [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final assignmentId = await FirebaseConfiguration.instance.firestoreService
    .createAssignment(assignment);

// Get user assignments
final assignments = await FirebaseConfiguration.instance.firestoreService
    .getStudentAssignments(studentId: 'user123');
```

### File Upload
```dart
// Upload profile picture
final profilePictureUrl = await FirebaseConfiguration.instance.storageService
    .uploadProfilePicture(
      userId: 'user123',
      file: selectedImageFile,
    );

// Upload assignment attachment
final attachmentUrl = await FirebaseConfiguration.instance.storageService
    .uploadAssignmentAttachment(
      assignmentId: 'assignment456',
      file: documentFile,
    );
```

### Sending Notifications
```dart
// Send message notification
await FirebaseConfiguration.instance.notificationService
    .sendMessageNotification(
      receiverId: 'tutor456',
      senderName: 'John Doe',
      message: 'When is the next session?',
      conversationId: 'conv789',
    );

// Schedule session reminder
await FirebaseConfiguration.instance.notificationService
    .scheduleSessionReminder(
      scheduleId: 'session123',
      sessionTime: DateTime.now().add(Duration(minutes: 15)),
      reminderType: '15_minutes_before',
    );
```

### Analytics Tracking
```dart
// Log custom event
await FirebaseConfiguration.instance.analyticsService.logCustomEvent(
  eventName: 'assignment_completed',
  parameters: {
    'assignment_id': 'assignment456',
    'completion_time_hours': 2,
    'grade': 85.5,
  },
);

// Set user properties
await FirebaseConfiguration.instance.analyticsService.setUserProperties(
  userType: 'student',
  specialty: 'Mathematics',
  experienceLevel: 'intermediate',
);
```

### Offline Operations
```dart
// Check if service is available
final isOnline = await FirebaseConfiguration.instance.errorHandlingService
    .isServiceAvailable('firestore');

// Queue offline operation
await FirebaseConfiguration.instance.offlineSyncService
    .queueOperation(
      operationType: 'create',
      collection: 'assignments',
      data: assignment.toFirestore(),
    );
```

## 🔒 Security Rules

### Firestore Security Rules
The `firestore.rules` file implements comprehensive security rules:

- **Users**: Can only read/write their own data, public profiles are readable
- **Assignments**: Students and assigned tutors can access, role-based updates
- **Queries**: Students can manage their queries, tutors can respond
- **Messages**: Only conversation participants can read/send messages
- **Articles**: Published articles are public, authors can manage their content
- **Schedules**: Participants can manage their schedules

### Storage Security Rules
The `storage.rules` file implements file access controls:

- **Profile Pictures**: Users can manage their own, public read access
- **Assignment Attachments**: Only assignment participants can access
- **Message Attachments**: Only conversation participants
- **Article Content**: Public for published articles, authors manage their own

## 📱 Offline Synchronization

The offline sync service provides:

### Cache Management
- Documents are cached with expiration times
- Query results are cached for improved performance
- Automatic cache cleanup for expired data

### Sync Queue
- Operations are queued when offline
- Automatic sync when connection is restored
- Retry mechanism with exponential backoff

### Local Database
- SQLite database for persistent storage
- Efficient indexing for fast queries
- Configurable cache sizes and expiration

## 🛡️ Error Handling

### Retry Mechanism
```dart
// Execute with automatic retry
final result = await FirebaseConfiguration.instance.errorHandlingService
    .executeWithRetry(
      () => firestoreService.getAssignments(userId),
      operationName: 'get_assignments',
      maxAttempts: 3,
      initialDelay: Duration(seconds: 1),
    );
```

### Error Logging
```dart
// Log custom error
await FirebaseConfiguration.instance.errorHandlingService.logError(
  error: exception,
  reason: 'Custom operation failed',
  information: {'operation': 'data_sync'},
);
```

### User-Friendly Messages
```dart
// Get user-friendly error message
final errorMessage = FirebaseConfiguration.instance.errorHandlingService
    .getUserFriendlyErrorMessage(exception);
```

## 🎯 Best Practices

### 1. Service Initialization
- Initialize Firebase configuration early in app startup
- Use singleton pattern for service access
- Enable debug mode only in development

### 2. Error Handling
- Always wrap Firebase operations in try-catch
- Use retry mechanisms for network operations
- Log errors to Crashlytics for monitoring

### 3. Security
- Implement proper Firestore security rules
- Validate file uploads and sizes
- Use Firebase Authentication for user verification

### 4. Performance
- Use pagination for large datasets
- Cache frequently accessed data
- Implement offline-first architecture

### 5. Analytics
- Track meaningful user interactions
- Use custom events for business metrics
- Monitor app performance and crash rates

## 🔧 Troubleshooting

### Common Issues

#### Firebase Not Initializing
```dart
// Check initialization status
if (FirebaseConfiguration.instance.isInitialized) {
  // Services are ready to use
}
```

#### Authentication Errors
```dart
// Check user authentication
final currentUser = FirebaseConfiguration.instance.authService.getCurrentUser();
if (currentUser != null) {
  // User is authenticated
}
```

#### Network Issues
```dart
// Check connectivity
final isOnline = await FirebaseConfiguration.instance.errorHandlingService
    .isServiceAvailable('firestore');
```

#### Storage Issues
```dart
// Validate file before upload
if (await storageService.validateImageFile(file)) {
  await storageService.uploadProfilePicture(...);
}
```

### Debug Mode
Enable debug mode for development:
```dart
await FirebaseConfiguration.instance.initialize(
  isDebugMode: true,
  enableAnalytics: false,
);
```

### Health Checks
Check service health:
```dart
final isHealthy = await FirebaseConfiguration.instance.areAllServicesHealthy();
```

### Configuration Validation
Get configuration status:
```dart
final config = FirebaseConfiguration.instance.getConfigurationSummary();
```

## 📦 Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.6.0
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.8
  firebase_messaging: ^14.7.10
  firebase_remote_config: ^4.3.8
  cloud_functions: ^5.0.2
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  sqflite: ^2.3.0
  local_notifications: ^6.0.0
  path: ^1.8.3
  equatable: ^2.0.5
```

## 🚀 Deployment

### Firebase Project Setup
1. Create Firebase project
2. Enable Authentication, Firestore, Storage, Functions
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Deploy security rules

### Security Rules Deployment
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

### Cloud Functions Deployment
```bash
# Deploy all functions
firebase deploy --only functions
```

## 📚 Additional Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/rules)
- [Firebase Authentication Guide](https://firebase.google.com/docs/auth)
- [Firebase Storage Guide](https://firebase.google.com/docs/storage)
- [Firebase Analytics Guide](https://firebase.google.com/docs/analytics)

## 📞 Support

For issues or questions regarding the Firebase integration:
1. Check this documentation
2. Review the code comments
3. Check Firebase console for errors
4. Contact the development team

---

**Note**: Replace placeholder values in `firebase_config.dart` with your actual Firebase project configuration before deploying to production.