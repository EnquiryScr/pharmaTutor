import 'package:flutter/foundation.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/failure.dart';

/// Provider for messaging functionality
/// Uses MessageRepositoryImpl with offline queue support
class MessageProvider extends ChangeNotifier {
  final SupabaseDependencies _dependencies = SupabaseDependencies();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  ConversationModel? _currentConversation;
  int _unreadCount = 0;
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 50;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get currentConversation => _currentConversation;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  /// Load user conversations
  Future<void> loadConversations(
    String userId, {
    bool loadMore = false,
  }) async {
    if (_isLoading) return;
    if (loadMore && !_hasMore) return;

    _setLoading(true);
    _clearError();

    if (!loadMore) {
      _currentPage = 0;
      _conversations = [];
      _hasMore = true;
    }

    try {
      final result = await _dependencies.messageRepository.getUserConversations(
        userId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (newConversations) {
          if (newConversations.length < _pageSize) {
            _hasMore = false;
          }
          _conversations.addAll(newConversations);
          _currentPage++;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(
    String conversationId, {
    bool loadMore = false,
  }) async {
    if (_isLoading) return;
    if (loadMore && !_hasMore) return;

    _setLoading(true);
    _clearError();

    if (!loadMore) {
      _currentPage = 0;
      _messages = [];
      _hasMore = true;
    }

    try {
      final result = await _dependencies.messageRepository.getConversationMessages(
        conversationId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (newMessages) {
          if (newMessages.length < _pageSize) {
            _hasMore = false;
          }
          // Insert at beginning to show oldest messages first
          _messages.insertAll(0, newMessages);
          _currentPage++;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Send message (works offline with queue)
  Future<bool> sendMessage(
    String conversationId,
    String senderId,
    String text, {
    List<String>? attachmentUrls,
  }) async {
    _clearError();

    try {
      final result = await _dependencies.messageRepository.sendMessage(
        conversationId,
        senderId,
        text,
        attachmentUrls: attachmentUrls,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (message) {
          // Add message to list immediately (optimistic update)
          _messages.add(message);
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get or create conversation
  Future<ConversationModel?> getOrCreateConversation(
    String user1Id,
    String user2Id,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.messageRepository.getOrCreateConversation(
        user1Id,
        user2Id,
      );

      ConversationModel? conversation;
      result.fold(
        (failure) => _setError(failure.message),
        (conv) {
          conversation = conv;
          _currentConversation = conv;
          
          // Add to conversations list if not exists
          final exists = _conversations.any((c) => c.conversationId == conv.conversationId);
          if (!exists) {
            _conversations.insert(0, conv);
          }
        },
      );

      _setLoading(false);
      notifyListeners();
      return conversation;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return null;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _dependencies.messageRepository.markMessageAsRead(messageId);
      
      // Update message in list
      final index = _messages.indexWhere((m) => m.messageId == messageId);
      if (index != -1 && !_messages[index].isRead) {
        _messages[index] = MessageModel(
          messageId: _messages[index].messageId,
          conversationId: _messages[index].conversationId,
          senderId: _messages[index].senderId,
          messageText: _messages[index].messageText,
          attachmentUrls: _messages[index].attachmentUrls,
          isRead: true,
          createdAt: _messages[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markAllAsRead(String conversationId) async {
    try {
      // Mark each unread message as read
      final unreadMessages = _messages
          .where((m) => m.conversationId == conversationId && !m.isRead)
          .toList();

      for (final message in unreadMessages) {
        await markMessageAsRead(message.messageId);
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Get unread messages count
  Future<void> loadUnreadCount(String userId) async {
    try {
      final result = await _dependencies.messageRepository.getUnreadMessagesCount(userId);
      
      result.fold(
        (failure) => debugPrint('Error loading unread count: ${failure.message}'),
        (count) {
          _unreadCount = count;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  /// Search messages in conversation
  Future<void> searchMessages(String conversationId, String query) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.messageRepository.searchMessages(
        conversationId,
        query,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (searchResults) {
          _messages = searchResults;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Upload attachment
  Future<String?> uploadAttachment(
    String conversationId,
    List<int> fileBytes,
    String fileName,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.messageRepository.uploadAttachment(
        conversationId,
        fileBytes,
        fileName,
      );

      String? url;
      result.fold(
        (failure) => _setError(failure.message),
        (attachmentUrl) => url = attachmentUrl,
      );

      _setLoading(false);
      return url;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return null;
    }
  }

  /// Set current conversation
  void setCurrentConversation(ConversationModel conversation) {
    _currentConversation = conversation;
    _messages = [];
    _hasMore = true;
    _currentPage = 0;
    notifyListeners();
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _messages = [];
    _hasMore = true;
    _currentPage = 0;
    notifyListeners();
  }

  /// Refresh conversations
  Future<void> refreshConversations(String userId) async {
    _currentPage = 0;
    _conversations = [];
    _hasMore = true;
    await loadConversations(userId);
    await loadUnreadCount(userId);
  }

  /// Refresh messages
  Future<void> refreshMessages(String conversationId) async {
    _currentPage = 0;
    _messages = [];
    _hasMore = true;
    await loadMessages(conversationId);
  }

  /// Clear all data
  void clear() {
    _conversations = [];
    _messages = [];
    _currentConversation = null;
    _unreadCount = 0;
    _errorMessage = null;
    _hasMore = true;
    _currentPage = 0;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
