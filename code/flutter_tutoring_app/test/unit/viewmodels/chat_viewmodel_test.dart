import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/presentation/viewmodels/chat_viewmodel.dart';
import '../../lib/data/services/chat_service.dart';
import '../../mocks/mock_services.dart';
import '../../fixtures/chat_fixtures.dart';
import '../../test_config.dart';
import '../../helpers/test_helpers.dart';

/// Generate mock classes
@GenerateMocks([ChatService])
import 'chat_viewmodel_test.mocks.dart';

void main() {
  group('ChatViewModel', () {
    late ChatViewModel chatViewModel;
    late MockChatService mockChatService;

    setUp(() {
      mockChatService = MockChatService();
      chatViewModel = ChatViewModel(chatService: mockChatService);
    });

    tearDown(() {
      chatViewModel.dispose();
    });

    test('should initialize with unloaded state', () {
      expect(chatViewModel.state, equals(ViewState.unloaded));
      expect(chatViewModel.messages, isEmpty);
      expect(chatViewModel.currentRoomId, isNull);
      expect(chatViewModel.isLoading, isFalse);
      expect(chatViewModel.error, isNull);
    });

    group('sendMessage', () {
      test('should send message successfully', () async {
        // Arrange
        when(mockChatService.sendMessage('room-123', 'Hello', 'text'))
            .thenAnswer((_) async => ChatFixtures.successfulMessageSendResponse);

        // Act
        await chatViewModel.sendMessage('Hello', roomId: 'room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        expect(chatViewModel.error, isNull);
        verify(mockChatService.sendMessage('room-123', 'Hello', 'text')).called(1);
      });

      test('should handle send message failure', () async {
        // Arrange
        when(mockChatService.sendMessage('room-123', 'Hello', 'text'))
            .thenAnswer((_) async => ChatFixtures.failedMessageSendResponse);

        // Act
        await chatViewModel.sendMessage('Hello', roomId: 'room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.error));
        expect(chatViewModel.error, isNotNull);
      });

      test('should not send empty messages', () async {
        // Act & Assert
        expect(
          () => chatViewModel.sendMessage(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should not send messages without room', () async {
        // Act & Assert
        expect(
          () => chatViewModel.sendMessage('Hello'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('loadMessages', () {
      test('should load messages successfully', () async {
        // Arrange
        when(mockChatService.getMessages('room-123', limit: 50, lastMessageId: null))
            .thenAnswer((_) async => ChatFixtures.successfulMessageListResponse);

        // Act
        await chatViewModel.loadMessages('room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        expect(chatViewModel.currentRoomId, equals('room-123'));
        expect(chatViewModel.messages, isNotEmpty);
        verify(mockChatService.getMessages('room-123', limit: 50, lastMessageId: null)).called(1);
      });

      test('should handle load messages failure', () async {
        // Arrange
        when(mockChatService.getMessages('invalid-room', limit: 50, lastMessageId: null))
            .thenAnswer((_) async => {
              'success': false,
              'error': {'code': 'ROOM_NOT_FOUND', 'message': 'Room not found'},
            });

        // Act
        await chatViewModel.loadMessages('invalid-room');

        // Assert
        expect(chatViewModel.state, equals(ViewState.error));
        expect(chatViewModel.error, equals('Room not found'));
      });

      test('should load messages with pagination', () async {
        // Arrange
        when(mockChatService.getMessages('room-123', limit: 20, lastMessageId: 'msg-100'))
            .thenAnswer((_) async => {
              'success': true,
              'data': {
                'messages': [ChatFixtures.textMessage],
                'hasMore': false,
                'totalCount': 1,
              },
            });

        // Act
        await chatViewModel.loadMessages('room-123', limit: 20, lastMessageId: 'msg-100');

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        verify(mockChatService.getMessages('room-123', limit: 20, lastMessageId: 'msg-100')).called(1);
      });
    });

    group('createRoom', () {
      test('should create room successfully', () async {
        // Arrange
        when(mockChatService.createRoom(any))
            .thenAnswer((_) async => ChatFixtures.successfulRoomCreateResponse);

        // Act
        await chatViewModel.createRoom({
          'name': 'New Room',
          'type': 'private',
          'participants': ['user-123', 'user-456'],
        });

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        expect(chatViewModel.error, isNull);
        verify(mockChatService.createRoom(any)).called(1);
      });

      test('should handle room creation failure', () async {
        // Arrange
        when(mockChatService.createRoom(any))
            .thenAnswer((_) async => {
              'success': false,
              'error': {'code': 'ROOM_CREATE_FAILED', 'message': 'Failed to create room'},
            });

        // Act
        await chatViewModel.createRoom({
          'name': '',
          'type': 'invalid',
          'participants': [],
        });

        // Assert
        expect(chatViewModel.state, equals(ViewState.error));
        expect(chatViewModel.error, isNotNull);
      });
    });

    group('room management', () {
      test('should join room successfully', () async {
        // Arrange
        when(mockChatService.joinRoom('room-123'))
            .thenAnswer((_) async => {'success': true, 'data': {'roomId': 'room-123'}});

        // Act
        await chatViewModel.joinRoom('room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        verify(mockChatService.joinRoom('room-123')).called(1);
      });

      test('should leave room successfully', () async {
        // Arrange
        when(mockChatService.leaveRoom('room-123'))
            .thenAnswer((_) async => {'success': true, 'data': {'roomId': 'room-123'}});

        // Act
        await chatViewModel.leaveRoom('room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        verify(mockChatService.leaveRoom('room-123')).called(1);
      });
    });

    group('file upload', () {
      test('should upload file successfully', () async {
        // Arrange
        when(mockChatService.uploadFile(any, 'room-123'))
            .thenAnswer((_) async => {
              'success': true,
              'data': {
                'fileId': 'file-123',
                'url': 'https://example.com/files/image.jpg',
                'filename': 'image.jpg',
              },
            });

        // Act
        await chatViewModel.uploadFile('mock-file', 'room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        expect(chatViewModel.error, isNull);
        verify(mockChatService.uploadFile('mock-file', 'room-123')).called(1);
      });

      test('should handle file upload failure', () async {
        // Arrange
        when(mockChatService.uploadFile(any, 'room-123'))
            .thenAnswer((_) async => ChatFixtures.failedFileUploadResponse);

        // Act
        await chatViewModel.uploadFile('mock-file', 'room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.error));
        expect(chatViewModel.error, isNotNull);
      });
    });

    group('message management', () {
      test('should add message to list after sending', () async {
        // Arrange
        when(mockChatService.sendMessage('room-123', 'Hello', 'text'))
            .thenAnswer((_) async => ChatFixtures.successfulMessageSendResponse);

        // Act
        await chatViewModel.sendMessage('Hello', roomId: 'room-123');

        // Assert
        expect(chatViewModel.messages, isNotEmpty);
      });

      test('should clear messages', () async {
        // Arrange - First load some messages
        when(mockChatService.getMessages('room-123', limit: 50, lastMessageId: null))
            .thenAnswer((_) async => ChatFixtures.successfulMessageListResponse);
        await chatViewModel.loadMessages('room-123');

        // Act
        chatViewModel.clearMessages();

        // Assert
        expect(chatViewModel.messages, isEmpty);
      });

      test('should validate message types', () {
        expect(chatViewModel.isValidMessageType('text'), isTrue);
        expect(chatViewModel.isValidMessageType('image'), isTrue);
        expect(chatViewModel.isValidMessageType('file'), isTrue);
        expect(chatViewModel.isValidMessageType('invalid'), isFalse);
      });
    });

    group('error handling', () {
      test('should clear error state', () async {
        // Arrange - First trigger an error
        when(mockChatService.sendMessage('room-123', 'Hello', 'text'))
            .thenAnswer((_) async => ChatFixtures.failedMessageSendResponse);
        await chatViewModel.sendMessage('Hello', roomId: 'room-123');
        
        expect(chatViewModel.state, equals(ViewState.error));

        // Act
        chatViewModel.clearError();

        // Assert
        expect(chatViewModel.state, equals(ViewState.loaded));
        expect(chatViewModel.error, isNull);
      });

      test('should handle network errors', () async {
        // Arrange
        when(mockChatService.getMessages(any, limit: anyNamed('limit'), lastMessageId: anyNamed('lastMessageId')))
            .thenThrow(Exception('Network error'));

        // Act
        await chatViewModel.loadMessages('room-123');

        // Assert
        expect(chatViewModel.state, equals(ViewState.error));
        expect(chatViewModel.error, isNotNull);
      });
    });

    group('state management', () {
      test('should transition through correct states during message loading', () async {
        // Arrange
        when(mockChatService.getMessages('room-123', limit: 50, lastMessageId: null))
            .thenAnswer((_) async => ChatFixtures.successfulMessageListResponse);

        // Act & Assert
        expect(chatViewModel.state, equals(ViewState.unloaded));

        final future = chatViewModel.loadMessages('room-123');
        expect(chatViewModel.state, equals(ViewState.loading));
        expect(chatViewModel.isLoading, isTrue);

        await future;
        expect(chatViewModel.state, equals(ViewState.loaded));
        expect(chatViewModel.isLoading, isFalse);
      });

      test('should handle concurrent operations', () async {
        // Arrange
        when(mockChatService.getMessages('room-123', limit: 50, lastMessageId: null))
            .thenAnswer((_) async => ChatFixtures.successfulMessageListResponse);
        when(mockChatService.sendMessage('room-123', 'Message 1', 'text'))
            .thenAnswer((_) async => ChatFixtures.successfulMessageSendResponse);

        // Act
        final future1 = chatViewModel.loadMessages('room-123');
        final future2 = chatViewModel.sendMessage('Message 1', roomId: 'room-123');

        // Assert
        expect(chatViewModel.isLoading, isTrue);

        await Future.wait([future1, future2]);
        expect(chatViewModel.isLoading, isFalse);
        expect(chatViewModel.state, equals(ViewState.loaded));
      });
    });

    group('real-time features', () {
      test('should listen to message stream', () async {
        // This would test real-time message updates
        // Mock the message stream from the service
        // Verify that messages are automatically added to the list
        // Note: This is a conceptual test structure
        
        // Arrange
        // final messageStream = Stream.value(ChatFixtures.textMessage);
        // when(mockChatService.messageStream).thenReturn(messageStream);

        // Act
        // chatViewModel.initialize();

        // Assert
        // Verify that messages are added to the list when stream receives data
      });

      test('should listen to typing indicators', () async {
        // This would test typing indicator functionality
        // Mock the typing stream from the service
        // Verify that typing state is managed correctly
        
        // Arrange
        // final typingStream = Stream.value(ChatFixtures.typingIndicator);
        // when(mockChatService.typingStream).thenReturn(typingStream);

        // Act
        // chatViewModel.initialize();

        // Assert
        // Verify typing indicators are handled correctly
      });
    });

    group('performance', () {
      test('should handle large message lists efficiently', () async {
        // Arrange
        final largeMessageList = {
          'success': true,
          'data': {
            'messages': List.generate(1000, (index) => 
                {'id': 'msg-$index', 'content': 'Message $index'}),
            'hasMore': false,
            'totalCount': 1000,
          },
        };
        
        when(mockChatService.getMessages('room-123', limit: 50, lastMessageId: null))
            .thenAnswer((_) async => largeMessageList);

        // Act
        await TestHelpers.measureExecutionTime(
          () => chatViewModel.loadMessages('room-123'),
        );

        // Assert
        expect(chatViewModel.messages.length, equals(1000));
        expect(chatViewModel.state, equals(ViewState.loaded));
      });

      test('should handle rapid message sending', () async {
        // Arrange
        when(mockChatService.sendMessage(any, any, any))
            .thenAnswer((_) async => ChatFixtures.successfulMessageSendResponse);

        // Act
        final futures = List.generate(10, (index) => 
            chatViewModel.sendMessage('Message $index', roomId: 'room-123'));

        // Assert
        await Future.wait(futures);
        expect(chatViewModel.messages.length, equals(10));
      });
    });
  });
}