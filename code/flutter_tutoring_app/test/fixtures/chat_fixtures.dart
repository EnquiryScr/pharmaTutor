import '../test_config.dart';

/// Chat test fixtures for consistent test data
class ChatFixtures {
  // Test chat rooms
  static const privateRoom = {
    'id': 'room-private-123',
    'name': 'Private Tutoring Session',
    'type': 'private',
    'participants': ['student-123', 'tutor-456'],
    'createdAt': '2024-01-01T00:00:00Z',
    'updatedAt': '2024-01-01T00:00:00Z',
    'isActive': true,
    'metadata': {
      'subject': 'Mathematics',
      'topic': 'Algebra',
      'sessionId': 'session-123',
    },
  };

  static const groupRoom = {
    'id': 'room-group-456',
    'name': 'Study Group - Physics',
    'type': 'group',
    'participants': ['student-123', 'student-456', 'student-789', 'tutor-456'],
    'createdAt': '2024-01-01T00:00:00Z',
    'updatedAt': '2024-01-01T00:00:00Z',
    'isActive': true,
    'metadata': {
      'description': 'Physics study group for exam preparation',
      'subject': 'Physics',
      'maxParticipants': 10,
    },
  };

  static const supportRoom = {
    'id': 'room-support-789',
    'name': 'Technical Support',
    'type': 'support',
    'participants': ['student-123', 'admin-789'],
    'createdAt': '2024-01-01T00:00:00Z',
    'updatedAt': '2024-01-01T00:00:00Z',
    'isActive': true,
    'priority': 'high',
    'metadata': {
      'category': 'technical',
      'status': 'open',
    },
  };

  // Test messages
  static const textMessage = {
    'id': 'msg-123',
    'roomId': 'room-private-123',
    'senderId': 'student-123',
    'senderName': 'John Doe',
    'senderRole': 'student',
    'type': 'text',
    'content': 'Hello, I need help with this math problem.',
    'timestamp': '2024-01-01T10:00:00Z',
    'isEdited': false,
    'isDeleted': false,
    'replyTo': null,
    'reactions': [],
    'readBy': ['student-123', 'tutor-456'],
    'deliveryStatus': 'delivered',
  };

  static const imageMessage = {
    'id': 'msg-124',
    'roomId': 'room-private-123',
    'senderId': 'student-123',
    'senderName': 'John Doe',
    'senderRole': 'student',
    'type': 'image',
    'content': 'https://example.com/image.jpg',
    'timestamp': '2024-01-01T10:01:00Z',
    'isEdited': false,
    'isDeleted': false,
    'replyTo': null,
    'reactions': [],
    'readBy': ['student-123'],
    'deliveryStatus': 'delivered',
    'metadata': {
      'filename': 'math_problem.jpg',
      'size': 1024000,
      'mimeType': 'image/jpeg',
      'width': 1920,
      'height': 1080,
    },
  };

  static const fileMessage = {
    'id': 'msg-125',
    'roomId': 'room-private-123',
    'senderId': 'tutor-456',
    'senderName': 'Jane Smith',
    'senderRole': 'tutor',
    'type': 'file',
    'content': 'assignment_solutions.pdf',
    'timestamp': '2024-01-01T10:02:00Z',
    'isEdited': false,
    'isDeleted': false,
    'replyTo': null,
    'reactions': [],
    'readBy': ['student-123', 'tutor-456'],
    'deliveryStatus': 'delivered',
    'metadata': {
      'filename': 'assignment_solutions.pdf',
      'size': 2048000,
      'mimeType': 'application/pdf',
      'downloadUrl': 'https://example.com/files/assignment_solutions.pdf',
    },
  };

  static const systemMessage = {
    'id': 'msg-126',
    'roomId': 'room-private-123',
    'senderId': 'system',
    'senderName': 'System',
    'senderRole': 'system',
    'type': 'system',
    'content': 'John Doe joined the tutoring session',
    'timestamp': '2024-01-01T10:00:00Z',
    'isEdited': false,
    'isDeleted': false,
    'replyTo': null,
    'reactions': [],
    'readBy': ['student-123', 'tutor-456'],
    'deliveryStatus': 'delivered',
    'metadata': {
      'eventType': 'user_joined',
      'userId': 'student-123',
    },
  };

  static const assignmentMessage = {
    'id': 'msg-127',
    'roomId': 'room-private-123',
    'senderId': 'tutor-456',
    'senderName': 'Jane Smith',
    'senderRole': 'tutor',
    'type': 'assignment',
    'content': 'New assignment posted: Calculus Problem Set 3',
    'timestamp': '2024-01-01T10:03:00Z',
    'isEdited': false,
    'isDeleted': false,
    'replyTo': null,
    'reactions': [],
    'readBy': ['student-123'],
    'deliveryStatus': 'delivered',
    'metadata': {
      'assignmentId': 'assignment-123',
      'assignmentTitle': 'Calculus Problem Set 3',
      'dueDate': '2024-01-08T00:00:00Z',
    },
  };

  // Message reactions
  static const messageReaction = {
    'emoji': '👍',
    'users': ['student-456', 'student-789'],
    'count': 2,
  };

  static const messageReactionList = [messageReaction];

  // Typing indicators
  static const typingIndicator = {
    'roomId': 'room-private-123',
    'userId': 'student-123',
    'userName': 'John Doe',
    'isTyping': true,
    'timestamp': '2024-01-01T10:04:00Z',
  };

  static const typingIndicatorInactive = {
    'roomId': 'room-private-123',
    'userId': 'student-123',
    'userName': 'John Doe',
    'isTyping': false,
    'timestamp': '2024-01-01T10:05:00Z',
  };

  // Online presence
  static const userPresence = {
    'userId': 'student-123',
    'status': 'online',
    'lastSeen': '2024-01-01T10:05:00Z',
    'roomId': 'room-private-123',
    'deviceType': 'mobile',
  };

  static const userPresenceOffline = {
    'userId': 'student-456',
    'status': 'offline',
    'lastSeen': '2024-01-01T09:30:00Z',
    'roomId': 'room-private-123',
    'deviceType': 'web',
  };

  // Chat responses
  static const successfulMessageSendResponse = {
    'success': true,
    'data': {
      'message': textMessage,
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const successfulRoomListResponse = {
    'success': true,
    'data': {
      'rooms': [privateRoom, groupRoom, supportRoom],
      'totalCount': 3,
      'hasMore': false,
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const successfulMessageListResponse = {
    'success': true,
    'data': {
      'messages': [textMessage, imageMessage, fileMessage, systemMessage],
      'totalCount': 4,
      'hasMore': false,
      'roomId': 'room-private-123',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const successfulRoomCreateResponse = {
    'success': true,
    'data': {
      'room': {
        'id': 'room-new-999',
        'name': 'New Tutoring Session',
        'type': 'private',
        'participants': ['student-123', 'tutor-456'],
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      },
    },
    'timestamp': DateTime.now().toIso8601String(),
  };

  static const failedMessageSendResponse = {
    'success': false,
    'error': {
      'code': 'MESSAGE_SEND_FAILED',
      'message': 'Failed to send message',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const roomNotFoundResponse = {
    'success': false,
    'error': {
      'code': 'ROOM_NOT_FOUND',
      'message': 'Chat room not found',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const accessDeniedResponse = {
    'success': false,
    'error': {
      'code': 'ACCESS_DENIED',
      'message': 'Access denied to chat room',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // WebSocket events
  static const messageReceivedEvent = {
    'event': 'message_received',
    'data': textMessage,
  };

  static const userTypingEvent = {
    'event': 'user_typing',
    'data': typingIndicator,
  };

  static const userJoinedEvent = {
    'event': 'user_joined',
    'data': {
      'userId': 'student-123',
      'userName': 'John Doe',
      'timestamp': '2024-01-01T10:00:00Z',
    },
  };

  static const userLeftEvent = {
    'event': 'user_left',
    'data': {
      'userId': 'student-123',
      'userName': 'John Doe',
      'timestamp': '2024-01-01T10:30:00Z',
    },
  };

  static const roomUpdatedEvent = {
    'event': 'room_updated',
    'data': {
      'roomId': 'room-private-123',
      'updates': {
        'name': 'Updated Room Name',
        'lastActivity': DateTime.now().toIso8601String(),
      },
    },
  };

  // Message search results
  static const messageSearchResults = {
    'success': true,
    'data': {
      'results': [
        {
          'message': textMessage,
          'relevance': 0.95,
          'highlights': ['math problem'],
        },
        {
          'message': assignmentMessage,
          'relevance': 0.75,
          'highlights': ['assignment', 'Calculus'],
        },
      ],
      'totalCount': 2,
      'query': 'assignment',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // File upload response
  static const successfulFileUploadResponse = {
    'success': true,
    'data': {
      'url': 'https://example.com/files/uploaded_file.jpg',
      'filename': 'uploaded_file.jpg',
      'size': 1024000,
      'mimeType': 'image/jpeg',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const failedFileUploadResponse = {
    'success': false,
    'error': {
      'code': 'FILE_UPLOAD_FAILED',
      'message': 'File upload failed',
      'details': {
        'reason': 'FILE_TOO_LARGE',
        'maxSize': 10485760, // 10MB
        'actualSize': 15728640, // 15MB
      },
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // Helper methods
  static Map<String, dynamic> createMessage({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      'roomId': roomId ?? 'room-123',
      'senderId': senderId ?? 'user-123',
      'senderName': 'Test User',
      'senderRole': 'student',
      'type': type ?? 'text',
      'content': content ?? 'Test message',
      'timestamp': DateTime.now().toIso8601String(),
      'isEdited': false,
      'isDeleted': false,
      'replyTo': null,
      'reactions': [],
      'readBy': [],
      'deliveryStatus': 'sending',
      ...?metadata,
    };
  }

  static Map<String, dynamic> createRoom({
    String? id,
    String? name,
    String? type,
    List<String>? participants,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'room-${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Test Room',
      'type': type ?? 'private',
      'participants': participants ?? ['user-123'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'isActive': true,
      ...?metadata,
    };
  }

  static Map<String, dynamic> createChatResponse({
    bool success = true,
    Map<String, dynamic>? data,
    String? errorCode,
    String? errorMessage,
  }) {
    if (success) {
      return {
        'success': true,
        'data': data ?? {'message': textMessage},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      return {
        'success': false,
        'error': {
          'code': errorCode ?? 'CHAT_ERROR',
          'message': errorMessage ?? 'Chat operation failed',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static bool isValidMessageType(String type) {
    const validTypes = ['text', 'image', 'file', 'audio', 'video', 'assignment', 'system'];
    return validTypes.contains(type);
  }

  static bool isValidRoomType(String type) {
    const validTypes = ['private', 'group', 'support', 'broadcast'];
    return validTypes.contains(type);
  }

  static bool isValidDeliveryStatus(String status) {
    const validStatuses = ['sending', 'sent', 'delivered', 'read', 'failed'];
    return validStatuses.contains(status);
  }
}