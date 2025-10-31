import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message_model.dart';

/// Supabase data source for messaging-related operations
class MessageSupabaseDataSource {
  final SupabaseClient _supabase;

  MessageSupabaseDataSource(this._supabase);

  // Create a new conversation
  Future<Map<String, dynamic>> createConversation({
    required List<String> participantIds,
  }) async {
    try {
      // Check if conversation already exists between these participants
      final existingConversation = await _supabase
          .from('conversations')
          .select()
          .contains('participant_ids', participantIds)
          .maybeSingle();

      if (existingConversation != null) {
        return existingConversation;
      }

      // Create new conversation
      final response = await _supabase
          .from('conversations')
          .insert({
            'participant_ids': participantIds,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Get conversation by ID
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  // Get user's conversations
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .contains('participant_ids', [userId])
          .order('last_message_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get user conversations: $e');
    }
  }

  // Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
    String messageType = 'text',
    List<String>? attachments,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'message_text': messageText,
            'message_type': messageType,
            'attachments': attachments,
          })
          .select()
          .single();

      // Update conversation's last_message and last_message_at
      await _supabase
          .from('conversations')
          .update({
            'last_message': messageText,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      return MessageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a conversation
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:profiles!messages_sender_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // Get unread messages count for a user
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      // Get all conversations for this user
      final conversations = await getUserConversations(userId);
      
      int totalUnread = 0;
      for (var conversation in conversations) {
        final count = await _supabase
            .from('messages')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('conversation_id', conversation['id'])
            .neq('sender_id', userId)
            .isFilter('read_at', null)
            .count();
        
        totalUnread += count.count ?? 0;
      }

      return totalUnread;
    } catch (e) {
      throw Exception('Failed to get unread messages count: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .isFilter('read_at', null); // Only update if not already read
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Mark all messages in a conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Upload message attachment to storage
  Future<String> uploadAttachment({
    required String conversationId,
    required File file,
  }) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${conversationId}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$conversationId/$fileName';

      // Upload to message-attachments bucket
      await _supabase.storage
          .from('message-attachments')
          .upload(filePath, file);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('message-attachments')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // Delete attachment from storage
  Future<void> deleteAttachment(String attachmentUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(attachmentUrl);
      final filePath = uri.pathSegments.skip(5).join('/');

      // Delete from storage
      await _supabase.storage
          .from('message-attachments')
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  // Search messages in a conversation
  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:profiles!messages_sender_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .ilike('message_text', '%$query%')
          .limit(limit)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Get conversation between two users
  Future<Map<String, dynamic>?> getConversationBetweenUsers({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final participants = [userId1, userId2]..sort();
      
      final response = await _supabase
          .from('conversations')
          .select()
          .contains('participant_ids', participants)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get conversation between users: $e');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages first
      await _supabase
          .from('messages')
          .delete()
          .eq('conversation_id', conversationId);

      // Delete conversation
      await _supabase
          .from('conversations')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Real-time subscription to new messages in a conversation
  RealtimeChannel subscribeToConversationMessages(
    String conversationId,
    void Function(MessageModel) onNewMessage,
    void Function(MessageModel) onMessageUpdate,
  ) {
    final channel = _supabase.channel('conversation_messages_$conversationId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onNewMessage(MessageModel.fromJson(payload.newRecord!));
        }
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onMessageUpdate(MessageModel.fromJson(payload.newRecord!));
        }
      },
    );

    return channel.subscribe();
  }

  // Subscribe to all user's conversations for real-time updates
  RealtimeChannel subscribeToUserConversations(
    String userId,
    void Function(Map<String, dynamic>) onConversationUpdate,
  ) {
    return _supabase
        .channel('user_conversations_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            if (payload.newRecord != null) {
              final participantIds = payload.newRecord!['participant_ids'] as List;
              if (participantIds.contains(userId)) {
                onConversationUpdate(payload.newRecord!);
              }
            }
          },
        )
        .subscribe();
  }

  // Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
