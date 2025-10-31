import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// MessageCacheDataSource - Manages message and conversation caching in SQLite
class MessageCacheDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================================
  // CONVERSATIONS - CREATE / UPDATE
  // ============================================================

  /// Cache a conversation
  Future<void> cacheConversation(Map<String, dynamic> conversation) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...conversation,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_conversations',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple conversations
  Future<void> cacheConversations(List<Map<String, dynamic>> conversations) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final conversation in conversations) {
      final cacheData = {
        ...conversation,
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      batch.insert(
        'cache_conversations',
        cacheData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update conversation
  Future<void> updateConversation(String conversationId, Map<String, dynamic> updates) async {
    final db = await _dbHelper.database;
    
    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.update(
      'cache_conversations',
      updateData,
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // ============================================================
  // MESSAGES - CREATE / UPDATE
  // ============================================================

  /// Cache a message
  Future<void> cacheMessage(Map<String, dynamic> message) async {
    final db = await _dbHelper.database;
    
    final cacheData = {
      ...message,
      'last_synced_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      'cache_messages',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple messages
  Future<void> cacheMessages(List<Map<String, dynamic>> messages) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final message in messages) {
      final cacheData = {
        ...message,
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      batch.insert(
        'cache_messages',
        cacheData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_messages',
      {
        'is_read': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_messages',
      {
        'is_read': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'conversation_id = ? AND is_read = ?',
      whereArgs: [conversationId, 0],
    );
  }

  // ============================================================
  // CONVERSATIONS - READ / QUERY
  // ============================================================

  /// Get conversation by ID
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get all cached conversations
  Future<List<Map<String, dynamic>>> getAllConversations() async {
    final db = await _dbHelper.database;
    return await db.query(
      'cache_conversations',
      orderBy: 'last_message_at DESC',
    );
  }

  /// Get user's conversations
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_conversations',
      where: 'participant_ids LIKE ?',
      whereArgs: ['%$userId%'],
      orderBy: 'last_message_at DESC',
    );
  }

  // ============================================================
  // MESSAGES - READ / QUERY
  // ============================================================

  /// Get message by ID
  Future<Map<String, dynamic>?> getMessage(String messageId) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'cache_messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get unread messages count for a user
  Future<int> getUnreadCount(String userId) async {
    final db = await _dbHelper.database;
    
    // Get all conversations for this user
    final conversations = await getUserConversations(userId);
    if (conversations.isEmpty) return 0;

    final conversationIds = conversations.map((c) => c['id']).toList();
    final placeholders = conversationIds.map((_) => '?').join(',');

    final result = await db.rawQuery(
      '''SELECT COUNT(*) as count FROM cache_messages 
         WHERE conversation_id IN ($placeholders) 
         AND sender_id != ? 
         AND is_read = ?''',
      [...conversationIds, userId, 0],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get unread messages count for a conversation
  Future<int> getConversationUnreadCount(String conversationId, String userId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      '''SELECT COUNT(*) as count FROM cache_messages 
         WHERE conversation_id = ? 
         AND sender_id != ? 
         AND is_read = ?''',
      [conversationId, userId, 0],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    final db = await _dbHelper.database;
    
    return await db.query(
      'cache_messages',
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// Delete conversation and its messages
  Future<void> deleteConversation(String conversationId) async {
    final db = await _dbHelper.database;
    
    // Delete messages first
    await db.delete(
      'cache_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );

    // Delete conversation
    await db.delete(
      'cache_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cache_messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Clear all cached messages and conversations
  Future<void> clearAllMessages() async {
    final db = await _dbHelper.database;
    await db.delete('cache_messages');
    await db.delete('cache_conversations');
  }

  /// Delete old messages (older than X days)
  Future<void> deleteOldMessages({int daysToKeep = 30}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();

    await db.delete(
      'cache_messages',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  // ============================================================
  // SYNC STATUS
  // ============================================================

  /// Check if conversation needs sync
  Future<bool> needsSync(String conversationId, {int minutesThreshold = 5}) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null) return true;

    final lastSynced = DateTime.parse(conversation['last_synced_at'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastSynced).inMinutes;

    return difference >= minutesThreshold;
  }

  /// Update sync timestamp
  Future<void> updateSyncTimestamp(String conversationId) async {
    final db = await _dbHelper.database;
    
    await db.update(
      'cache_conversations',
      {'last_synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final db = await _dbHelper.database;
    
    final conversationsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_conversations',
    );
    final messagesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_messages',
    );
    final unreadResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cache_messages WHERE is_read = ?',
      [0],
    );

    return {
      'total_conversations': Sqflite.firstIntValue(conversationsResult) ?? 0,
      'total_messages': Sqflite.firstIntValue(messagesResult) ?? 0,
      'unread_messages': Sqflite.firstIntValue(unreadResult) ?? 0,
    };
  }
}
