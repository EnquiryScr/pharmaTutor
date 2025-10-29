import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

// Import the actual service classes (you'll need to adjust these imports based on your project structure)
import '../../lib/data/services/auth_service.dart';
import '../../lib/data/services/chat_service.dart';
import '../../lib/data/services/payment_service.dart';
import '../../lib/data/services/assignment_service.dart';
import '../../lib/data/services/firebase_service.dart';
import '../../lib/data/services/notification_service.dart';
import '../../lib/data/services/offline_sync_service.dart';
import '../../lib/core/integrations/api_client.dart';
import '../../lib/core/integrations/authentication_service.dart';
import '../../lib/core/integrations/cache_service.dart';
import '../../lib/core/integrations/websocket_service.dart';
import '../../lib/core/secure_storage/secure_storage.dart';

/// Generate mock classes for all services
@GenerateMocks([
  AuthService,
  ChatService,
  PaymentService,
  AssignmentService,
  FirebaseService,
  NotificationService,
  OfflineSyncService,
  ApiClient,
  AuthenticationService,
  CacheService,
  WebSocketService,
  SecureStorage,
  http.Client,
])
import 'mock_services.mocks.dart';

/// Mock implementations for testing
class MockAuthService extends Mock implements AuthService {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email == 'test@example.com' && password == 'password123') {
      return {
        'success': true,
        'data': {
          'user': {'id': 'user-123', 'email': email, 'role': 'student'},
          'token': 'mock-token-123',
          'refreshToken': 'mock-refresh-123',
        },
      };
    }
    return {
      'success': false,
      'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid credentials'},
    };
  }

  @override
  Future<Map<String, dynamic>> register(String email, String password, Map<String, dynamic> userData) async {
    return {
      'success': true,
      'data': {
        'user': {'id': 'user-123', 'email': email, 'role': 'student'},
        'message': 'Registration successful',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> logout() async {
    return {
      'success': true,
      'data': {'message': 'Logout successful'},
    };
  }

  @override
  bool get isAuthenticated => true;

  @override
  String? get currentUserId => 'user-123';

  @override
  String? get currentUserRole => 'student';

  @override
  Future<Map<String, dynamic>> resetPassword(String email) async {
    return {
      'success': true,
      'data': {'message': 'Password reset email sent'},
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    return {
      'success': true,
      'data': {
        'user': {
          'id': 'user-123',
          'email': 'test@example.com',
          'role': 'student',
          ...userData,
        },
      },
    };
  }
}

class MockChatService extends Mock implements ChatService {
  @override
  Future<Map<String, dynamic>> sendMessage(String roomId, String content, String type) async {
    return {
      'success': true,
      'data': {
        'messageId': 'msg-123',
        'content': content,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': 'user-123',
        'status': 'sent',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getMessages(String roomId, {int? limit, String? lastMessageId}) async {
    return {
      'success': true,
      'data': {
        'messages': [
          {
            'id': 'msg-123',
            'content': 'Hello',
            'type': 'text',
            'timestamp': DateTime.now().toIso8601String(),
            'senderId': 'user-123',
          },
        ],
        'hasMore': false,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> roomData) async {
    return {
      'success': true,
      'data': {
        'room': {
          'id': 'room-123',
          'name': roomData['name'] ?? 'New Room',
          'type': roomData['type'] ?? 'private',
          'participants': roomData['participants'] ?? [],
          'createdAt': DateTime.now().toIso8601String(),
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> joinRoom(String roomId) async {
    return {
      'success': true,
      'data': {
        'roomId': roomId,
        'joinedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> leaveRoom(String roomId) async {
    return {
      'success': true,
      'data': {
        'roomId': roomId,
        'leftAt': DateTime.now().toIso8601String(),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> uploadFile(dynamic file, String roomId) async {
    return {
      'success': true,
      'data': {
        'fileId': 'file-123',
        'url': 'https://example.com/files/uploaded.jpg',
        'filename': 'uploaded.jpg',
        'size': 1024000,
        'type': 'image',
      },
    };
  }

  @override
  Stream<Map<String, dynamic>> get messageStream => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get typingStream => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get roomUpdateStream => const Stream.empty();
}

class MockPaymentService extends Mock implements PaymentService {
  @override
  Future<Map<String, dynamic>> createPaymentIntent(double amount, String currency, Map<String, dynamic> metadata) async {
    return {
      'success': true,
      'data': {
        'id': 'pi-123',
        'clientSecret': 'pi-123-secret',
        'amount': amount,
        'currency': currency,
        'status': 'requires_payment_method',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> confirmPayment(String paymentIntentId, Map<String, dynamic> paymentMethod) async {
    return {
      'success': true,
      'data': {
        'id': paymentIntentId,
        'status': 'succeeded',
        'amount': 9999,
        'currency': 'USD',
        'created': DateTime.now().millisecondsSinceEpoch,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getPaymentMethods(String userId) async {
    return {
      'success': true,
      'data': {
        'paymentMethods': [
          {
            'id': 'pm-123',
            'type': 'card',
            'card': {
              'brand': 'visa',
              'last4': '4242',
              'expMonth': 12,
              'expYear': 2025,
            },
            'isDefault': true,
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> savePaymentMethod(Map<String, dynamic> paymentMethodData) async {
    return {
      'success': true,
      'data': {
        'id': 'pm-123',
        'type': 'card',
        'card': {
          'brand': 'visa',
          'last4': '4242',
          'expMonth': 12,
          'expYear': 2025,
        },
        'isDefault': false,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> createSubscription(String priceId, String customerId) async {
    return {
      'success': true,
      'data': {
        'id': 'sub-123',
        'status': 'active',
        'currentPeriodStart': DateTime.now().toIso8601String(),
        'currentPeriodEnd': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'items': {
          'data': [
            {
              'price': {'id': priceId, 'unitAmount': 9999, 'currency': 'USD'},
            },
          ],
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    return {
      'success': true,
      'data': {
        'id': subscriptionId,
        'status': 'canceled',
        'canceledAt': DateTime.now().toIso8601String(),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getPaymentHistory(String userId, {int? limit, int? offset}) async {
    return {
      'success': true,
      'data': {
        'transactions': [
          {
            'id': 'txn-123',
            'amount': 9999,
            'currency': 'USD',
            'status': 'completed',
            'created': DateTime.now().millisecondsSinceEpoch,
            'description': 'Tutoring Session',
          },
        ],
        'totalCount': 1,
        'hasMore': false,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> processRefund(String paymentIntentId, {double? amount, String? reason}) async {
    return {
      'success': true,
      'data': {
        'id': 're-123',
        'amount': amount ?? 9999,
        'status': 'succeeded',
        'reason': reason ?? 'requested_by_customer',
      },
    };
  }
}

class MockAssignmentService extends Mock implements AssignmentService {
  @override
  Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> assignmentData) async {
    return {
      'success': true,
      'data': {
        'assignment': {
          'id': 'assignment-123',
          'title': assignmentData['title'] ?? 'New Assignment',
          'description': assignmentData['description'] ?? '',
          'subject': assignmentData['subject'] ?? 'General',
          'createdAt': DateTime.now().toIso8601String(),
          'createdBy': 'tutor-456',
          'status': 'active',
          ...assignmentData,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getAssignment(String assignmentId) async {
    return {
      'success': true,
      'data': {
        'assignment': {
          'id': assignmentId,
          'title': 'Test Assignment',
          'description': 'Test assignment description',
          'subject': 'Mathematics',
          'createdAt': DateTime.now().toIso8601String(),
          'status': 'active',
          'questions': [],
          'totalPoints': 100,
          'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getAssignments({Map<String, dynamic>? filters, int? limit, int? offset}) async {
    return {
      'success': true,
      'data': {
        'assignments': [
          {
            'id': 'assignment-123',
            'title': 'Math Assignment',
            'subject': 'Mathematics',
            'status': 'active',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        'totalCount': 1,
        'hasMore': false,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> updateAssignment(String assignmentId, Map<String, dynamic> updateData) async {
    return {
      'success': true,
      'data': {
        'assignment': {
          'id': assignmentId,
          'title': updateData['title'] ?? 'Updated Assignment',
          'updatedAt': DateTime.now().toIso8601String(),
          ...updateData,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    return {
      'success': true,
      'data': {
        'message': 'Assignment deleted successfully',
        'deletedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> startSubmission(String assignmentId) async {
    return {
      'success': true,
      'data': {
        'submission': {
          'id': 'submission-123',
          'assignmentId': assignmentId,
          'startedAt': DateTime.now().toIso8601String(),
          'status': 'in_progress',
          'answers': [],
          'timeSpent': 0,
          'attemptsRemaining': 3,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> submitAssignment(String assignmentId, Map<String, dynamic> submissionData) async {
    return {
      'success': true,
      'data': {
        'submission': {
          'id': 'submission-123',
          'assignmentId': assignmentId,
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'submitted',
          'score': 85,
          'totalPoints': 100,
          'percentage': 85.0,
          ...submissionData,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getSubmissions(String assignmentId, {String? studentId}) async {
    return {
      'success': true,
      'data': {
        'submissions': [
          {
            'id': 'submission-123',
            'assignmentId': assignmentId,
            'studentId': studentId ?? 'student-123',
            'status': 'submitted',
            'score': 85,
            'submittedAt': DateTime.now().toIso8601String(),
          },
        ],
        'totalCount': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> gradeSubmission(String submissionId, Map<String, dynamic> grades) async {
    return {
      'success': true,
      'data': {
        'submission': {
          'id': submissionId,
          'score': grades['score'] ?? 85,
          'feedback': grades['feedback'] ?? 'Good work!',
          'gradedAt': DateTime.now().toIso8601String(),
          'gradedBy': 'tutor-456',
          'status': 'graded',
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getSubmissionAnalytics(String assignmentId) async {
    return {
      'success': true,
      'data': {
        'statistics': {
          'totalSubmissions': 25,
          'averageScore': 78.5,
          'medianScore': 82.0,
          'highestScore': 98.0,
          'lowestScore': 45.0,
          'passRate': 0.85,
          'completionRate': 0.8,
        },
        'scoreDistribution': [
          {'range': '0-20', 'count': 1},
          {'range': '21-40', 'count': 2},
          {'range': '41-60', 'count': 3},
          {'range': '61-80', 'count': 8},
          {'range': '81-100', 'count': 11},
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> uploadAssignmentFile(String assignmentId, dynamic file) async {
    return {
      'success': true,
      'data': {
        'fileId': 'file-123',
        'filename': 'assignment_file.pdf',
        'url': 'https://example.com/files/assignment_file.pdf',
        'size': 1024000,
        'type': 'pdf',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    };
  }
}

class MockFirebaseService extends Mock implements FirebaseService {
  @override
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    return {
      'user': {'uid': 'user-123', 'email': email},
      'credential': {},
    };
  }

  @override
  Future<Map<String, dynamic>> createUserWithEmailAndPassword(String email, String password) async {
    return {
      'user': {'uid': 'user-123', 'email': email},
      'credential': {},
    };
  }

  @override
  Future<void> signOut() async {
    // Mock sign out
  }

  @override
  Stream<Map<String, dynamic>> get authStateChanges => const Stream.empty();

  @override
  Future<Map<String, dynamic>> uploadFile(String path, dynamic file, {Map<String, String>? metadata}) async {
    return {
      'downloadURL': 'https://example.com/files/$path',
      'metadata': metadata ?? {},
    };
  }

  @override
  Future<void> deleteFile(String path) async {
    // Mock file deletion
  }

  @override
  Future<Map<String, dynamic>> getDocument(String collection, String documentId) async {
    return {
      'exists': true,
      'data': {'id': documentId, 'createdAt': DateTime.now().toIso8601String()},
    };
  }

  @override
  Future<Map<String, dynamic>> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    return {
      'success': true,
      'documentId': documentId,
    };
  }

  @override
  Future<Map<String, dynamic>> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    return {
      'success': true,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> deleteDocument(String collection, String documentId) async {
    return {
      'success': true,
      'deletedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Stream<Map<String, dynamic>> getDocumentStream(String collection, String documentId) => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> getCollectionStream(String collection, {Map<String, dynamic>? query}) => const Stream.empty();
}

class MockNotificationService extends Mock implements NotificationService {
  @override
  Future<Map<String, dynamic>> checkPermissions() async {
    return {
      'granted': true,
      'permissions': {
        'alert': true,
        'badge': true,
        'sound': true,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> requestPermissions() async {
    return {
      'granted': true,
      'permissions': {
        'alert': true,
        'badge': true,
        'sound': true,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> showLocalNotification(Map<String, dynamic> notification) async {
    return {
      'success': true,
      'notificationId': 'notif-123',
    };
  }

  @override
  Future<Map<String, dynamic>> scheduleNotification(Map<String, dynamic> notification, DateTime scheduledTime) async {
    return {
      'success': true,
      'scheduledId': 'scheduled-123',
    };
  }

  @override
  Future<Map<String, dynamic>> cancelNotification(String notificationId) async {
    return {
      'success': true,
    };
  }

  @override
  Stream<Map<String, dynamic>> get notificationStream => const Stream.empty();
}

class MockOfflineSyncService extends Mock implements OfflineSyncService {
  @override
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  Future<Map<String, dynamic>> queueOperation(Map<String, dynamic> operation) async {
    return {
      'success': true,
      'operationId': 'op-123',
    };
  }

  @override
  Future<Map<String, dynamic>> syncPendingOperations() async {
    return {
      'success': true,
      'syncedCount': 5,
      'failedCount': 0,
    };
  }

  @override
  Future<Map<String, dynamic>> getSyncQueueStatus() async {
    return {
      'pendingOperations': 2,
      'syncedOperations': 10,
      'failedOperations': 0,
      'isSyncing': false,
    };
  }

  @override
  Future<Map<String, dynamic>> clearSyncQueue() async {
    return {
      'success': true,
      'clearedCount': 2,
    };
  }

  @override
  Stream<Map<String, dynamic>> get syncStatusStream => const Stream.empty();
}

/// Factory methods for creating mock services
class MockServiceFactory {
  static MockAuthService createAuthService() {
    return MockAuthService();
  }

  static MockChatService createChatService() {
    return MockChatService();
  }

  static MockPaymentService createPaymentService() {
    return MockPaymentService();
  }

  static MockAssignmentService createAssignmentService() {
    return MockAssignmentService();
  }

  static MockFirebaseService createFirebaseService() {
    return MockFirebaseService();
  }

  static MockNotificationService createNotificationService() {
    return MockNotificationService();
  }

  static MockOfflineSyncService createOfflineSyncService() {
    return MockOfflineSyncService();
  }
}

/// Helper methods for mock service setup
class MockServiceHelpers {
  static void setupAuthServiceSuccess(MockAuthService service) {
    when(service.login(any, any)).thenAnswer((_) async => service.login('test@example.com', 'password123'));
    when(service.isAuthenticated).thenReturn(true);
    when(service.currentUserId).thenReturn('user-123');
    when(service.currentUserRole).thenReturn('student');
  }

  static void setupAuthServiceFailure(MockAuthService service) {
    when(service.login(any, any)).thenAnswer((_) async => {
      'success': false,
      'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid credentials'},
    });
    when(service.isAuthenticated).thenReturn(false);
    when(service.currentUserId).thenReturn(null);
    when(service.currentUserRole).thenReturn(null);
  }

  static void setupChatServiceSuccess(MockChatService service) {
    when(service.sendMessage(any, any, any)).thenAnswer((_) async => {
      'success': true,
      'data': {'messageId': 'msg-123', 'status': 'sent'},
    });
    when(service.getMessages(any, limit: anyNamed('limit'), lastMessageId: anyNamed('lastMessageId')))
        .thenAnswer((_) async => {
      'success': true,
      'data': {'messages': [], 'hasMore': false},
    });
  }

  static void setupPaymentServiceSuccess(MockPaymentService service) {
    when(service.createPaymentIntent(any, any, any)).thenAnswer((_) async => {
      'success': true,
      'data': {'id': 'pi-123', 'status': 'requires_payment_method'},
    });
    when(service.confirmPayment(any, any)).thenAnswer((_) async => {
      'success': true,
      'data': {'status': 'succeeded'},
    });
  }

  static void setupAssignmentServiceSuccess(MockAssignmentService service) {
    when(service.createAssignment(any)).thenAnswer((_) async => {
      'success': true,
      'data': {'assignment': {'id': 'assignment-123', 'status': 'active'}},
    });
    when(service.getAssignment(any)).thenAnswer((_) async => {
      'success': true,
      'data': {'assignment': {'id': anyNamed('assignmentId'), 'status': 'active'}},
    });
  }
}