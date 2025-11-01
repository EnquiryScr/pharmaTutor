import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter_tutoring_app/presentation/providers/message_provider.dart';
import 'package:flutter_tutoring_app/core/utils/supabase_dependencies.dart';
import 'package:flutter_tutoring_app/data/repositories/message_repository_impl.dart';
import 'package:flutter_tutoring_app/data/models/message_model.dart';
import 'package:flutter_tutoring_app/data/models/conversation_model.dart';
import 'package:flutter_tutoring_app/data/models/failure.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([MessageRepositoryImpl, SupabaseDependencies])
import 'message_provider_test.mocks.dart';

void main() {
  late MessageProvider provider;
  late MockSupabaseDependencies mockDependencies;
  late MockMessageRepositoryImpl mockMessageRepository;

  setUp(() {
    mockDependencies = MockSupabaseDependencies();
    mockMessageRepository = MockMessageRepositoryImpl();
    
    when(mockDependencies.messageRepository).thenReturn(mockMessageRepository);
    
    provider = MessageProvider();
  });

  group('MessageProvider - Load Conversations', () {
    const userId = 'test-user-id';
    final testConversations = [
      ConversationModel(
        conversationId: 'conv-1',
        user1Id: userId,
        user2Id: 'user-2',
        lastMessageText: 'Hello',
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      ConversationModel(
        conversationId: 'conv-2',
        user1Id: userId,
        user2Id: 'user-3',
        lastMessageText: 'Hi there',
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];

    test('should load conversations successfully', () async {
      // Arrange
      when(mockMessageRepository.getUserConversations(
        userId,
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Right(testConversations));

      // Act
      await provider.loadConversations(userId);

      // Assert
      expect(provider.conversations.length, 2);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, null);
    });

    test('should handle load conversations error', () async {
      // Arrange
      when(mockMessageRepository.getUserConversations(
        userId,
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Left(Failure(message: 'Failed to load')));

      // Act
      await provider.loadConversations(userId);

      // Assert
      expect(provider.conversations.isEmpty, true);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('should support pagination', () async {
      // Arrange
      final firstBatch = [testConversations[0]];
      final secondBatch = [testConversations[1]];
      
      when(mockMessageRepository.getUserConversations(
        userId,
        limit: anyNamed('limit'),
        offset: 0,
      )).thenAnswer((_) async => Right(firstBatch));
      
      when(mockMessageRepository.getUserConversations(
        userId,
        limit: anyNamed('limit'),
        offset: 50,
      )).thenAnswer((_) async => Right(secondBatch));

      // Act
      await provider.loadConversations(userId);
      await provider.loadConversations(userId, loadMore: true);

      // Assert
      expect(provider.conversations.length, 2);
    });
  });

  group('MessageProvider - Send Message', () {
    const conversationId = 'conv-1';
    const senderId = 'user-1';
    const messageText = 'Hello, how are you?';
    
    final testMessage = MessageModel(
      messageId: 'msg-1',
      conversationId: conversationId,
      senderId: senderId,
      messageText: messageText,
      isRead: false,
      createdAt: DateTime.now(),
    );

    test('should send message successfully', () async {
      // Arrange
      when(mockMessageRepository.sendMessage(
        conversationId,
        senderId,
        messageText,
        attachmentUrls: anyNamed('attachmentUrls'),
      )).thenAnswer((_) async => Right(testMessage));

      // Act
      final success = await provider.sendMessage(
        conversationId,
        senderId,
        messageText,
      );

      // Assert
      expect(success, true);
      expect(provider.messages.length, 1);
      expect(provider.messages[0].messageText, messageText);
      expect(provider.errorMessage, null);
    });

    test('should handle send message error', () async {
      // Arrange
      when(mockMessageRepository.sendMessage(
        conversationId,
        senderId,
        messageText,
        attachmentUrls: anyNamed('attachmentUrls'),
      )).thenAnswer((_) async => Left(Failure(message: 'Failed to send')));

      // Act
      final success = await provider.sendMessage(
        conversationId,
        senderId,
        messageText,
      );

      // Assert
      expect(success, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('should send message with attachments', () async {
      // Arrange
      final attachments = ['https://example.com/image.jpg'];
      when(mockMessageRepository.sendMessage(
        conversationId,
        senderId,
        messageText,
        attachmentUrls: attachments,
      )).thenAnswer((_) async => Right(testMessage.copyWith(
        attachmentUrls: attachments,
      )));

      // Act
      final success = await provider.sendMessage(
        conversationId,
        senderId,
        messageText,
        attachmentUrls: attachments,
      );

      // Assert
      expect(success, true);
      expect(provider.messages[0].attachmentUrls, attachments);
    });
  });

  group('MessageProvider - Mark as Read', () {
    const messageId = 'msg-1';
    final testMessage = MessageModel(
      messageId: messageId,
      conversationId: 'conv-1',
      senderId: 'user-1',
      messageText: 'Test message',
      isRead: false,
      createdAt: DateTime.now(),
    );

    test('should mark message as read', () async {
      // Arrange
      provider.messages.add(testMessage);
      when(mockMessageRepository.markMessageAsRead(messageId))
          .thenAnswer((_) async => Right(null));

      // Act
      await provider.markMessageAsRead(messageId);

      // Assert
      expect(provider.messages[0].isRead, true);
    });

    test('should handle mark as read error gracefully', () async {
      // Arrange
      provider.messages.add(testMessage);
      when(mockMessageRepository.markMessageAsRead(messageId))
          .thenThrow(Exception('Failed to mark as read'));

      // Act & Assert (should not throw)
      await provider.markMessageAsRead(messageId);
      expect(provider.messages[0].isRead, false); // Should remain unchanged
    });
  });

  group('MessageProvider - Unread Count', () {
    const userId = 'user-1';
    const unreadCount = 5;

    test('should load unread count', () async {
      // Arrange
      when(mockMessageRepository.getUnreadMessagesCount(userId))
          .thenAnswer((_) async => Right(unreadCount));

      // Act
      await provider.loadUnreadCount(userId);

      // Assert
      expect(provider.unreadCount, unreadCount);
    });

    test('should handle unread count error gracefully', () async {
      // Arrange
      when(mockMessageRepository.getUnreadMessagesCount(userId))
          .thenAnswer((_) async => Left(Failure(message: 'Failed')));

      // Act (should not throw)
      await provider.loadUnreadCount(userId);

      // Assert
      expect(provider.unreadCount, 0); // Should remain at default
    });
  });

  group('MessageProvider - State Management', () {
    test('should clear all data', () async {
      // Arrange
      provider.conversations.add(ConversationModel(
        conversationId: 'conv-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        createdAt: DateTime.now(),
      ));
      provider.messages.add(MessageModel(
        messageId: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        messageText: 'Test',
        isRead: false,
        createdAt: DateTime.now(),
      ));

      // Act
      provider.clear();

      // Assert
      expect(provider.conversations.isEmpty, true);
      expect(provider.messages.isEmpty, true);
      expect(provider.currentConversation, null);
      expect(provider.unreadCount, 0);
    });

    test('should set and clear current conversation', () {
      // Arrange
      final conversation = ConversationModel(
        conversationId: 'conv-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        createdAt: DateTime.now(),
      );

      // Act - Set
      provider.setCurrentConversation(conversation);

      // Assert - Set
      expect(provider.currentConversation, conversation);
      expect(provider.messages.isEmpty, true);

      // Act - Clear
      provider.clearCurrentConversation();

      // Assert - Clear
      expect(provider.currentConversation, null);
    });
  });
}

extension MessageModelCopyWith on MessageModel {
  MessageModel copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? messageText,
    List<String>? attachmentUrls,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageText: messageText ?? this.messageText,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
