import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/repositories/irepository.dart';
import '../models/message_model.dart';
import '../datasources/remote/message_supabase_data_source.dart';
import '../datasources/local/message_cache_data_source.dart';

/// Message repository implementing offline-first pattern
class MessageRepositoryImpl implements IOfflineFirstRepository<MessageModel> {
  final MessageSupabaseDataSource _remoteDataSource;
  final MessageCacheDataSource _cacheDataSource;
  final Connectivity _connectivity;

  MessageRepositoryImpl({
    required MessageSupabaseDataSource remoteDataSource,
    required MessageCacheDataSource cacheDataSource,
    Connectivity? connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _cacheDataSource = cacheDataSource,
        _connectivity = connectivity ?? Connectivity();

  @override
  String get repositoryName => 'MessageRepository';

  Future<bool> get _isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get conversation messages with cache-first approach
  Future<Either<Failure, List<MessageModel>>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final cachedMessages = await _cacheDataSource.getConversationMessages(
        conversationId,
        limit: limit,
        offset: offset,
      );
      
      if (cachedMessages.isNotEmpty) {
        final messageModels = cachedMessages
            .map((data) => MessageModel.fromJson(data))
            .toList();
        
        if (await _isOnline) {
          _updateMessagesInBackground(conversationId, limit: limit);
        }
        
        return Right(messageModels);
      }

      if (await _isOnline) {
        final remoteMessages = await _remoteDataSource.getMessages(
          conversationId,
          limit: limit,
          offset: offset,
        );
        
        for (final message in remoteMessages) {
          await _cacheDataSource.insertMessage(message);
        }
        
        return Right(remoteMessages.map((data) => MessageModel.fromJson(data)).toList());
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get conversation messages: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateMessagesInBackground(String conversationId, {int limit = 50}) async {
    try {
      final remoteMessages = await _remoteDataSource.getMessages(
        conversationId,
        limit: limit,
      );
      
      for (final message in remoteMessages) {
        await _cacheDataSource.updateMessage(message['message_id'], message);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get user conversations
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserConversations(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final cachedConversations = await _cacheDataSource.getUserConversations(
        userId,
        limit: limit,
        offset: offset,
      );
      
      if (cachedConversations.isNotEmpty) {
        if (await _isOnline) {
          _updateConversationsInBackground(userId);
        }
        
        return Right(cachedConversations);
      }

      if (await _isOnline) {
        final remoteConversations = await _remoteDataSource.getUserConversations(
          userId,
          limit: limit,
          offset: offset,
        );
        
        for (final conversation in remoteConversations) {
          await _cacheDataSource.insertConversation(conversation);
        }
        
        return Right(remoteConversations);
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get user conversations: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateConversationsInBackground(String userId) async {
    try {
      final remoteConversations = await _remoteDataSource.getUserConversations(userId);
      
      for (final conversation in remoteConversations) {
        await _cacheDataSource.updateConversation(
          conversation['conversation_id'],
          conversation,
        );
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Send message
  Future<Either<Failure, MessageModel>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? attachmentUrl,
  }) async {
    try {
      if (await _isOnline) {
        final messageData = await _remoteDataSource.sendMessage(
          conversationId: conversationId,
          senderId: senderId,
          text: text,
          attachmentUrl: attachmentUrl,
        );
        
        await _cacheDataSource.insertMessage(messageData);
        
        return Right(MessageModel.fromJson(messageData));
      } else {
        // Store message locally for offline sending
        final localMessage = {
          'message_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'conversation_id': conversationId,
          'sender_id': senderId,
          'text': text,
          'attachment_url': attachmentUrl,
          'created_at': DateTime.now().toIso8601String(),
          'is_read': false,
        };
        
        await _cacheDataSource.insertMessage(localMessage);
        
        // TODO: Queue for sending when online
        
        return Right(MessageModel.fromJson(localMessage));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to send message: $e',
        exception: e,
      ));
    }
  }

  /// Mark message as read
  Future<Either<Failure, void>> markAsRead(String messageId) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.markMessageAsRead(messageId);
      }
      
      // Update cache regardless of online status
      await _cacheDataSource.markMessageAsRead(messageId);
      
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to mark message as read: $e',
        exception: e,
      ));
    }
  }

  /// Get unread messages count
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await _cacheDataSource.getUnreadMessagesCount(userId);
      
      if (await _isOnline) {
        _updateUnreadCountInBackground(userId);
      }
      
      return Right(count);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get unread count: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateUnreadCountInBackground(String userId) async {
    try {
      final remoteCount = await _remoteDataSource.getUnreadMessagesCount(userId);
      // The count will be updated when messages are synced
    } catch (e) {
      // Silent fail
    }
  }

  /// Search messages in conversation
  Future<Either<Failure, List<MessageModel>>> searchMessages(
    String conversationId,
    String query,
  ) async {
    try {
      final cachedMessages = await _cacheDataSource.searchMessages(conversationId, query);
      
      if (cachedMessages.isNotEmpty) {
        return Right(cachedMessages.map((data) => MessageModel.fromJson(data)).toList());
      }

      if (await _isOnline) {
        final remoteMessages = await _remoteDataSource.searchMessages(conversationId, query);
        
        return Right(remoteMessages.map((data) => MessageModel.fromJson(data)).toList());
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to search messages: $e',
        exception: e,
      ));
    }
  }

  // Offline-first interface implementation
  
  @override
  Future<Either<Failure, SyncResult<MessageModel>>> syncData() async {
    try {
      if (!await _isOnline) {
        return Left(Failure(
          message: 'Cannot sync while offline',
          code: 'OFFLINE',
        ));
      }

      // Sync logic would go here
      final syncedItems = <MessageModel>[];
      final failedItems = <String>[];

      return Right(SyncResult(
        syncedItems: syncedItems,
        failedItems: failedItems,
        totalSynced: syncedItems.length,
        totalFailed: failedItems.length,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'Sync failed: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<MessageModel>>> getOfflineData() async {
    try {
      // Would retrieve all cached messages here
      return const Right([]);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveOfflineData(List<MessageModel> data) async {
    try {
      for (final message in data) {
        await _cacheDataSource.insertMessage(message.toJson());
      }
      
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to save offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isDataSynced() async {
    try {
      // Check if we have any cached messages
      return const Right(true);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check sync status: $e',
        exception: e,
      ));
    }
  }

  // Base repository methods
  
  @override
  Future<Either<Failure, MessageModel>> getById(String id) async {
    try {
      final cachedMessage = await _cacheDataSource.getMessage(id);
      
      if (cachedMessage != null) {
        return Right(MessageModel.fromJson(cachedMessage));
      }

      return Left(Failure(
        message: 'Message not found',
        code: 'NOT_FOUND',
      ));
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get message: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, MessageModel>> create(MessageModel entity) async {
    return sendMessage(
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      text: entity.text,
      attachmentUrl: entity.attachmentUrl,
    );
  }

  @override
  Future<Either<Failure, MessageModel>> update(String id, MessageModel entity) async {
    return Left(Failure(
      message: 'Message update not supported',
      code: 'UNSUPPORTED_OPERATION',
    ));
  }

  @override
  Future<Either<Failure, bool>> delete(String id) async {
    try {
      if (await _isOnline) {
        // Would call remote delete here
        await _cacheDataSource.deleteMessage(id);
        return const Right(true);
      } else {
        return Left(Failure(
          message: 'Cannot delete message while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to delete message: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<MessageModel>>> getAll({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<MessageModel>>> search(String query) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, bool>> exists(String id) async {
    try {
      final message = await _cacheDataSource.getMessage(id);
      return Right(message != null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check if message exists: $e',
        exception: e,
      ));
    }
  }
}
