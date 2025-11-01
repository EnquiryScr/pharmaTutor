import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

/// Mock repositories for testing
/// These would typically mirror your actual repository interfaces

/// Mock User Repository
class MockUserRepository {
  static Map<String, dynamic> mockUser = {
    'id': 'user-123',
    'email': 'test@example.com',
    'firstName': 'John',
    'lastName': 'Doe',
    'role': 'student',
    'profilePicture': 'https://example.com/avatar.jpg',
    'createdAt': '2024-01-01T00:00:00Z',
    'lastLoginAt': '2024-01-01T00:00:00Z',
    'isEmailVerified': true,
    'isActive': true,
  };

  static Future<Map<String, dynamic>> getUserById(String userId) async {
    if (userId == 'user-123') {
      return {'success': true, 'data': mockUser};
    }
    return {'success': false, 'error': {'code': 'USER_NOT_FOUND', 'message': 'User not found'}};
  }

  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> updateData) async {
    return {
      'success': true,
      'data': {...mockUser, ...updateData, 'updatedAt': DateTime.now().toIso8601String()},
    };
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    return {
      'success': true,
      'message': 'User deleted successfully',
      'deletedAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> searchUsers(Map<String, dynamic> filters) async {
    return {
      'success': true,
      'data': {
        'users': [mockUser],
        'totalCount': 1,
        'hasMore': false,
      },
    };
  }

  static Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    return {
      'success': true,
      'data': {
        'totalSessions': 15,
        'completedAssignments': 8,
        'averageScore': 85.5,
        'totalSpent': 299.97,
        'joinDate': '2024-01-01T00:00:00Z',
        'lastActivity': '2024-01-01T00:00:00Z',
      },
    };
  }
}

/// Mock Assignment Repository
class MockAssignmentRepository {
  static List<Map<String, dynamic>> mockAssignments = [
    {
      'id': 'assignment-123',
      'title': 'Math Assignment',
      'description': 'Solve algebra problems',
      'subject': 'Mathematics',
      'difficulty': 'intermediate',
      'createdBy': 'tutor-456',
      'status': 'active',
      'dueDate': '2024-01-08T23:59:59Z',
      'totalPoints': 100,
    },
    {
      'id': 'assignment-456',
      'title': 'Physics Quiz',
      'description': 'Newton\'s Laws quiz',
      'subject': 'Physics',
      'difficulty': 'beginner',
      'createdBy': 'tutor-789',
      'status': 'completed',
      'dueDate': '2024-01-05T23:59:59Z',
      'totalPoints': 50,
    },
  ];

  static Future<Map<String, dynamic>> getAssignments({Map<String, dynamic>? filters, int? limit, int? offset}) async {
    return {
      'success': true,
      'data': {
        'assignments': mockAssignments,
        'totalCount': mockAssignments.length,
        'hasMore': false,
      },
    };
  }

  static Future<Map<String, dynamic>> getAssignmentById(String assignmentId) async {
    final assignment = mockAssignments.firstWhere(
      (a) => a['id'] == assignmentId,
      orElse: () => <String, dynamic>{},
    );
    
    if (assignment.isNotEmpty) {
      return {'success': true, 'data': assignment};
    }
    return {'success': false, 'error': {'code': 'ASSIGNMENT_NOT_FOUND', 'message': 'Assignment not found'}};
  }

  static Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> assignmentData) async {
    final newAssignment = {
      'id': 'assignment-${DateTime.now().millisecondsSinceEpoch}',
      ...assignmentData,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'active',
    };
    mockAssignments.add(newAssignment);
    
    return {'success': true, 'data': newAssignment};
  }

  static Future<Map<String, dynamic>> updateAssignment(String assignmentId, Map<String, dynamic> updateData) async {
    final index = mockAssignments.indexWhere((a) => a['id'] == assignmentId);
    if (index != -1) {
      mockAssignments[index] = {
        ...mockAssignments[index],
        ...updateData,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      return {'success': true, 'data': mockAssignments[index]};
    }
    return {'success': false, 'error': {'code': 'ASSIGNMENT_NOT_FOUND', 'message': 'Assignment not found'}};
  }

  static Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    final index = mockAssignments.indexWhere((a) => a['id'] == assignmentId);
    if (index != -1) {
      mockAssignments.removeAt(index);
      return {
        'success': true,
        'message': 'Assignment deleted successfully',
        'deletedAt': DateTime.now().toIso8601String(),
      };
    }
    return {'success': false, 'error': {'code': 'ASSIGNMENT_NOT_FOUND', 'message': 'Assignment not found'}};
  }

  static Future<Map<String, dynamic>> searchAssignments(String query) async {
    final filtered = mockAssignments.where((a) =>
      a['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
      a['description'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
    
    return {
      'success': true,
      'data': {
        'assignments': filtered,
        'totalCount': filtered.length,
        'query': query,
      },
    };
  }
}

/// Mock Submission Repository
class MockSubmissionRepository {
  static List<Map<String, dynamic>> mockSubmissions = [
    {
      'id': 'submission-123',
      'assignmentId': 'assignment-123',
      'studentId': 'student-123',
      'status': 'submitted',
      'score': 85,
      'totalPoints': 100,
      'submittedAt': '2024-01-05T14:30:00Z',
      'timeSpent': 95,
      'answers': [
        {'questionId': 'q1', 'answer': 'b', 'isCorrect': true},
        {'questionId': 'q2', 'answer': 'x = 12', 'isCorrect': true},
      ],
    },
  ];

  static Future<Map<String, dynamic>> getSubmissions(String assignmentId, {String? studentId}) async {
    var submissions = mockSubmissions.where((s) => s['assignmentId'] == assignmentId);
    
    if (studentId != null) {
      submissions = submissions.where((s) => s['studentId'] == studentId);
    }
    
    return {
      'success': true,
      'data': {
        'submissions': submissions.toList(),
        'totalCount': submissions.length,
      },
    };
  }

  static Future<Map<String, dynamic>> getSubmissionById(String submissionId) async {
    final submission = mockSubmissions.firstWhere(
      (s) => s['id'] == submissionId,
      orElse: () => <String, dynamic>{},
    );
    
    if (submission.isNotEmpty) {
      return {'success': true, 'data': submission};
    }
    return {'success': false, 'error': {'code': 'SUBMISSION_NOT_FOUND', 'message': 'Submission not found'}};
  }

  static Future<Map<String, dynamic>> createSubmission(Map<String, dynamic> submissionData) async {
    final newSubmission = {
      'id': 'submission-${DateTime.now().millisecondsSinceEpoch}',
      ...submissionData,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'in_progress',
      'answers': [],
      'timeSpent': 0,
    };
    mockSubmissions.add(newSubmission);
    
    return {'success': true, 'data': newSubmission};
  }

  static Future<Map<String, dynamic>> updateSubmission(String submissionId, Map<String, dynamic> updateData) async {
    final index = mockSubmissions.indexWhere((s) => s['id'] == submissionId);
    if (index != -1) {
      mockSubmissions[index] = {
        ...mockSubmissions[index],
        ...updateData,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      return {'success': true, 'data': mockSubmissions[index]};
    }
    return {'success': false, 'error': {'code': 'SUBMISSION_NOT_FOUND', 'message': 'Submission not found'}};
  }

  static Future<Map<String, dynamic>> gradeSubmission(String submissionId, Map<String, dynamic> gradeData) async {
    final index = mockSubmissions.indexWhere((s) => s['id'] == submissionId);
    if (index != -1) {
      mockSubmissions[index] = {
        ...mockSubmissions[index],
        'score': gradeData['score'],
        'feedback': gradeData['feedback'],
        'gradedAt': DateTime.now().toIso8601String(),
        'gradedBy': gradeData['gradedBy'],
        'status': 'graded',
      };
      return {'success': true, 'data': mockSubmissions[index]};
    }
    return {'success': false, 'error': {'code': 'SUBMISSION_NOT_FOUND', 'message': 'Submission not found'}};
  }

  static Future<Map<String, dynamic>> getSubmissionAnalytics(String assignmentId) async {
    return {
      'success': true,
      'data': {
        'totalSubmissions': 25,
        'averageScore': 78.5,
        'medianScore': 82.0,
        'highestScore': 98.0,
        'lowestScore': 45.0,
        'passRate': 0.85,
        'completionRate': 0.8,
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
}

/// Mock Chat Repository
class MockChatRepository {
  static List<Map<String, dynamic>> mockMessages = [
    {
      'id': 'msg-123',
      'roomId': 'room-123',
      'senderId': 'user-123',
      'content': 'Hello, I need help with math',
      'type': 'text',
      'timestamp': '2024-01-01T10:00:00Z',
      'status': 'delivered',
    },
  ];

  static List<Map<String, dynamic>> mockRooms = [
    {
      'id': 'room-123',
      'name': 'Math Tutoring',
      'type': 'private',
      'participants': ['user-123', 'tutor-456'],
      'createdAt': '2024-01-01T09:00:00Z',
      'lastMessage': mockMessages.last,
      'unreadCount': 0,
      'isActive': true,
    },
  ];

  static Future<Map<String, dynamic>> getRooms({String? userId}) async {
    return {
      'success': true,
      'data': {
        'rooms': mockRooms,
        'totalCount': mockRooms.length,
      },
    };
  }

  static Future<Map<String, dynamic>> getRoomById(String roomId) async {
    final room = mockRooms.firstWhere(
      (r) => r['id'] == roomId,
      orElse: () => <String, dynamic>{},
    );
    
    if (room.isNotEmpty) {
      return {'success': true, 'data': room};
    }
    return {'success': false, 'error': {'code': 'ROOM_NOT_FOUND', 'message': 'Room not found'}};
  }

  static Future<Map<String, dynamic>> createRoom(Map<String, dynamic> roomData) async {
    final newRoom = {
      'id': 'room-${DateTime.now().millisecondsSinceEpoch}',
      ...roomData,
      'createdAt': DateTime.now().toIso8601String(),
      'lastMessage': null,
      'unreadCount': 0,
      'isActive': true,
    };
    mockRooms.add(newRoom);
    
    return {'success': true, 'data': newRoom};
  }

  static Future<Map<String, dynamic>> getMessages(String roomId, {int? limit, String? lastMessageId}) async {
    final roomMessages = mockMessages.where((m) => m['roomId'] == roomId).toList();
    
    return {
      'success': true,
      'data': {
        'messages': roomMessages,
        'hasMore': false,
        'totalCount': roomMessages.length,
      },
    };
  }

  static Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> messageData) async {
    final newMessage = {
      'id': 'msg-${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'sent',
      ...messageData,
    };
    mockMessages.add(newMessage);
    
    return {'success': true, 'data': newMessage};
  }

  static Future<Map<String, dynamic>> updateMessageReadStatus(String messageId, String userId) async {
    final index = mockMessages.indexWhere((m) => m['id'] == messageId);
    if (index != -1) {
      // Mock read status update
      return {'success': true, 'data': {'messageId': messageId, 'readBy': [userId]}};
    }
    return {'success': false, 'error': {'code': 'MESSAGE_NOT_FOUND', 'message': 'Message not found'}};
  }

  static Future<Map<String, dynamic>> searchMessages(String roomId, String query) async {
    final roomMessages = mockMessages.where((m) =>
      m['roomId'] == roomId && m['content'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
    
    return {
      'success': true,
      'data': {
        'messages': roomMessages,
        'totalCount': roomMessages.length,
        'query': query,
      },
    };
  }
}

/// Mock Payment Repository
class MockPaymentRepository {
  static List<Map<String, dynamic>> mockTransactions = [
    {
      'id': 'txn-123',
      'userId': 'user-123',
      'amount': 99.99,
      'currency': 'USD',
      'status': 'completed',
      'description': 'Tutoring Session',
      'paymentMethod': 'card',
      'createdAt': '2024-01-01T10:00:00Z',
      'completedAt': '2024-01-01T10:00:30Z',
    },
  ];

  static Future<Map<String, dynamic>> getTransactions(String userId, {int? limit, int? offset}) async {
    return {
      'success': true,
      'data': {
        'transactions': mockTransactions,
        'totalCount': mockTransactions.length,
        'hasMore': false,
      },
    };
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transactionData) async {
    final newTransaction = {
      'id': 'txn-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      ...transactionData,
    };
    mockTransactions.add(newTransaction);
    
    return {'success': true, 'data': newTransaction};
  }

  static Future<Map<String, dynamic>> updateTransactionStatus(String transactionId, String status) async {
    final index = mockTransactions.indexWhere((t) => t['id'] == transactionId);
    if (index != -1) {
      mockTransactions[index] = {
        ...mockTransactions[index],
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      return {'success': true, 'data': mockTransactions[index]};
    }
    return {'success': false, 'error': {'code': 'TRANSACTION_NOT_FOUND', 'message': 'Transaction not found'}};
  }

  static Future<Map<String, dynamic>> getPaymentMethods(String userId) async {
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

  static Future<Map<String, dynamic>> savePaymentMethod(String userId, Map<String, dynamic> paymentMethodData) async {
    return {
      'success': true,
      'data': {
        'id': 'pm-${DateTime.now().millisecondsSinceEpoch}',
        'type': 'card',
        'card': paymentMethodData['card'],
        'isDefault': false,
        'createdAt': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> processRefund(String transactionId, {double? amount, String? reason}) async {
    return {
      'success': true,
      'data': {
        'refundId': 'refund-${DateTime.now().millisecondsSinceEpoch}',
        'transactionId': transactionId,
        'amount': amount ?? 99.99,
        'reason': reason ?? 'requested_by_customer',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> getPaymentAnalytics(String userId) async {
    return {
      'success': true,
      'data': {
        'totalSpent': 299.97,
        'totalTransactions': 3,
        'averageTransactionAmount': 99.99,
        'currency': 'USD',
        'paymentMethodBreakdown': {
          'card': 3,
        },
        'monthlySpending': [
          {'month': '2024-01', 'amount': 299.97},
        ],
      },
    };
  }
}

/// Mock Schedule Repository
class MockScheduleRepository {
  static List<Map<String, dynamic>> mockSessions = [
    {
      'id': 'session-123',
      'studentId': 'student-123',
      'tutorId': 'tutor-456',
      'title': 'Math Tutoring Session',
      'subject': 'Mathematics',
      'scheduledTime': '2024-01-08T10:00:00Z',
      'duration': 60,
      'status': 'scheduled',
      'roomId': 'room-123',
    },
  ];

  static Future<Map<String, dynamic>> getAvailableSlots(DateTime date, {String? tutorId}) async {
    return {
      'success': true,
      'data': {
        'slots': [
          {
            'id': 'slot-1',
            'startTime': '2024-01-08T10:00:00Z',
            'endTime': '2024-01-08T11:00:00Z',
            'duration': 60,
            'isAvailable': true,
          },
          {
            'id': 'slot-2',
            'startTime': '2024-01-08T11:00:00Z',
            'endTime': '2024-01-08T12:00:00Z',
            'duration': 60,
            'isAvailable': true,
          },
        ],
      },
    };
  }

  static Future<Map<String, dynamic>> bookSession(Map<String, dynamic> sessionData) async {
    final newSession = {
      'id': 'session-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'scheduled',
      'createdAt': DateTime.now().toIso8601String(),
      ...sessionData,
    };
    mockSessions.add(newSession);
    
    return {'success': true, 'data': newSession};
  }

  static Future<Map<String, dynamic>> getSessions({String? userId, DateTime? startDate, DateTime? endDate}) async {
    return {
      'success': true,
      'data': {
        'sessions': mockSessions,
        'totalCount': mockSessions.length,
      },
    };
  }

  static Future<Map<String, dynamic>> updateSession(String sessionId, Map<String, dynamic> updateData) async {
    final index = mockSessions.indexWhere((s) => s['id'] == sessionId);
    if (index != -1) {
      mockSessions[index] = {
        ...mockSessions[index],
        ...updateData,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      return {'success': true, 'data': mockSessions[index]};
    }
    return {'success': false, 'error': {'code': 'SESSION_NOT_FOUND', 'message': 'Session not found'}};
  }

  static Future<Map<String, dynamic>> cancelSession(String sessionId, {String? reason}) async {
    final index = mockSessions.indexWhere((s) => s['id'] == sessionId);
    if (index != -1) {
      mockSessions[index] = {
        ...mockSessions[index],
        'status': 'cancelled',
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancellationReason': reason,
      };
      return {'success': true, 'data': mockSessions[index]};
    }
    return {'success': false, 'error': {'code': 'SESSION_NOT_FOUND', 'message': 'Session not found'}};
  }

  static Future<Map<String, dynamic>> getSessionAnalytics({String? userId}) async {
    return {
      'success': true,
      'data': {
        'totalSessions': 15,
        'completedSessions': 12,
        'cancelledSessions': 2,
        'upcomingSessions': 1,
        'totalRevenue': 599.85,
        'averageSessionDuration': 65,
        'completionRate': 0.86,
      },
    };
  }
}

/// Repository Factory for easy mock creation
class MockRepositoryFactory {
  static MockUserRepository createUserRepository() => MockUserRepository();
  static MockAssignmentRepository createAssignmentRepository() => MockAssignmentRepository();
  static MockSubmissionRepository createSubmissionRepository() => MockSubmissionRepository();
  static MockChatRepository createChatRepository() => MockChatRepository();
  static MockPaymentRepository createPaymentRepository() => MockPaymentRepository();
  static MockScheduleRepository createScheduleRepository() => MockScheduleRepository();
}

/// Helper methods for repository testing
class MockRepositoryHelpers {
  static void resetAllRepositories() {
    MockUserRepository.mockUser = {
      'id': 'user-123',
      'email': 'test@example.com',
      'firstName': 'John',
      'lastName': 'Doe',
      'role': 'student',
    };
    
    MockAssignmentRepository.mockAssignments.clear();
    MockSubmissionRepository.mockSubmissions.clear();
    MockChatRepository.mockMessages.clear();
    MockChatRepository.mockRooms.clear();
    MockPaymentRepository.mockTransactions.clear();
    MockScheduleRepository.mockSessions.clear();
  }

  static void setupUserRepositorySuccess() {
    MockUserRepository.getUserById = (String userId) async => {
      'success': true,
      'data': MockUserRepository.mockUser,
    };
  }

  static void setupUserRepositoryFailure() {
    MockUserRepository.getUserById = (String userId) async => {
      'success': false,
      'error': {'code': 'USER_NOT_FOUND', 'message': 'User not found'},
    };
  }

  static void setupAssignmentRepositoryEmpty() {
    MockAssignmentRepository.mockAssignments.clear();
  }

  static void setupChatRepositoryWithMessages() {
    MockChatRepository.mockMessages.addAll([
      {
        'id': 'msg-124',
        'roomId': 'room-123',
        'senderId': 'tutor-456',
        'content': 'Sure, I can help you with that',
        'type': 'text',
        'timestamp': '2024-01-01T10:01:00Z',
        'status': 'delivered',
      },
    ]);
  }

  static void setupPaymentRepositoryWithTransactions() {
    MockPaymentRepository.mockTransactions.addAll([
      {
        'id': 'txn-124',
        'userId': 'user-123',
        'amount': 199.98,
        'currency': 'USD',
        'status': 'completed',
        'description': 'Extended Tutoring Session',
        'paymentMethod': 'card',
        'createdAt': '2024-01-02T10:00:00Z',
        'completedAt': '2024-01-02T10:00:30Z',
      },
    ]);
  }
}