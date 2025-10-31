import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification_model.dart';

/// Supabase data source for notification-related operations
class NotificationSupabaseDataSource {
  final SupabaseClient _supabase;

  NotificationSupabaseDataSource(this._supabase);

  // Create a new notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'body': body,
            'type': type,
            'data': data,
          })
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notification by ID
  Future<NotificationModel?> getNotification(String notificationId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('id', notificationId)
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get notification: $e');
    }
  }

  // Get user's notifications
  Future<List<NotificationModel>> getUserNotifications({
    required String userId,
    String? type,
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (type != null) {
        queryBuilder = queryBuilder.eq('type', type);
      }

      if (isRead != null) {
        if (isRead) {
          queryBuilder = queryBuilder.not('read_at', 'is', null);
        } else {
          queryBuilder = queryBuilder.isFilter('read_at', null);
        }
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId)
          .isFilter('read_at', null)
          .count();

      return response.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread notifications count: $e');
    }
  }

  // Mark notification as read
  Future<NotificationModel> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Delete old notifications (older than specified days)
  Future<void> deleteOldNotifications({
    required String userId,
    int daysOld = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate.toIso8601String());
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }

  // Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType({
    required String userId,
    required String type,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .limit(limit)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications by type: $e');
    }
  }

  // Bulk create notifications (for sending to multiple users)
  Future<List<NotificationModel>> createBulkNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
      }).toList();

      final response = await _supabase
          .from('notifications')
          .insert(notifications)
          .select();

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to create bulk notifications: $e');
    }
  }

  // Get notification statistics for a user
  Future<Map<String, dynamic>> getNotificationStatistics(String userId) async {
    try {
      final response = await _supabase.rpc('get_notification_statistics', params: {
        'user_id': userId,
      });

      return response ?? {
        'total': 0,
        'unread': 0,
        'by_type': {},
      };
    } catch (e) {
      throw Exception('Failed to get notification statistics: $e');
    }
  }

  // Search notifications
  Future<List<NotificationModel>> searchNotifications({
    required String userId,
    required String query,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,body.ilike.%$query%')
          .limit(limit)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search notifications: $e');
    }
  }

  // Send push notification to user (creates notification record)
  Future<NotificationModel> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification in database
      final notification = await createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      // TODO: Integrate with actual push notification service (FCM, APNs)
      // This would typically call an edge function that sends the push notification
      // await _supabase.functions.invoke('send-push-notification', body: {
      //   'userId': userId,
      //   'title': title,
      //   'body': body,
      //   'data': data,
      // });

      return notification;
    } catch (e) {
      throw Exception('Failed to send push notification: $e');
    }
  }

  // Real-time subscription to new notifications for a user
  RealtimeChannel subscribeToUserNotifications(
    String userId,
    void Function(NotificationModel) onNewNotification,
    void Function(NotificationModel) onNotificationUpdate,
  ) {
    final channel = _supabase.channel('user_notifications_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onNewNotification(NotificationModel.fromJson(payload.newRecord!));
        }
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onNotificationUpdate(NotificationModel.fromJson(payload.newRecord!));
        }
      },
    );

    return channel.subscribe();
  }

  // Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
