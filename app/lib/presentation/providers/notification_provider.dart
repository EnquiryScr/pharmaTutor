import 'package:flutter/foundation.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../../data/models/notification_model.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/failure.dart';

/// Provider for notification management
/// Uses NotificationRepositoryImpl with cache-first pattern
class NotificationProvider extends ChangeNotifier {
  final SupabaseDependencies _dependencies = SupabaseDependencies();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  Map<String, int> _notificationStats = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  String? _currentFilter; // 'all', 'session', 'message', 'payment', 'course'

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  Map<String, int> get notificationStats => _notificationStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String? get currentFilter => _currentFilter;

  /// Load notifications with optional filtering
  Future<void> loadNotifications(
    String userId, {
    String? type,
    bool? isRead,
    bool loadMore = false,
  }) async {
    if (_isLoading) return;
    if (loadMore && !_hasMore) return;

    _setLoading(true);
    _clearError();

    if (!loadMore) {
      _currentPage = 0;
      _notifications = [];
      _hasMore = true;
      _currentFilter = type ?? 'all';
    }

    try {
      final result = await _dependencies.notificationRepository.getUserNotifications(
        userId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        type: type,
        isRead: isRead,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (newNotifications) {
          if (newNotifications.length < _pageSize) {
            _hasMore = false;
          }
          _notifications.addAll(newNotifications);
          _currentPage++;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load unread notifications only
  Future<void> loadUnreadNotifications(String userId) async {
    await loadNotifications(userId, isRead: false);
  }

  /// Load notifications by type
  Future<void> loadNotificationsByType(String userId, String type) async {
    await loadNotifications(userId, type: type);
  }

  /// Get unread count
  Future<void> loadUnreadCount(String userId) async {
    try {
      final result = await _dependencies.notificationRepository.getUnreadCount(userId);
      
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

  /// Get notification statistics
  Future<void> loadNotificationStats(String userId) async {
    try {
      final result = await _dependencies.notificationRepository.getNotificationStats(userId);
      
      result.fold(
        (failure) => debugPrint('Error loading stats: ${failure.message}'),
        (stats) {
          _notificationStats = stats;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  /// Mark single notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final result = await _dependencies.notificationRepository.markAsRead(notificationId);
      
      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (_) {
          // Update notification in list
          final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
          if (index != -1 && !_notifications[index].isRead) {
            _notifications[index] = NotificationModel(
              notificationId: _notifications[index].notificationId,
              userId: _notifications[index].userId,
              type: _notifications[index].type,
              title: _notifications[index].title,
              message: _notifications[index].message,
              data: _notifications[index].data,
              isRead: true,
              createdAt: _notifications[index].createdAt,
            );
            
            // Decrement unread count
            if (_unreadCount > 0) {
              _unreadCount--;
            }
            
            notifyListeners();
          }
          return true;
        },
      );
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.notificationRepository.markAllAsRead(userId);
      
      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (_) {
          // Update all notifications in list
          _notifications = _notifications.map((notification) {
            return NotificationModel(
              notificationId: notification.notificationId,
              userId: notification.userId,
              type: notification.type,
              title: notification.title,
              message: notification.message,
              data: notification.data,
              isRead: true,
              createdAt: notification.createdAt,
            );
          }).toList();
          
          _unreadCount = 0;
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final result = await _dependencies.notificationRepository.deleteNotification(notificationId);
      
      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (_) {
          // Remove from list
          final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
          if (index != -1) {
            final wasUnread = !_notifications[index].isRead;
            _notifications.removeAt(index);
            
            if (wasUnread && _unreadCount > 0) {
              _unreadCount--;
            }
            
            notifyListeners();
          }
          return true;
        },
      );
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Clear all notifications for user
  Future<bool> clearAllNotifications(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Delete all notifications one by one
      final notificationIds = _notifications.map((n) => n.notificationId).toList();
      
      for (final id in notificationIds) {
        await _dependencies.notificationRepository.deleteNotification(id);
      }
      
      _notifications = [];
      _unreadCount = 0;
      _notificationStats = {};
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Filter notifications by type locally
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get read notifications
  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  /// Refresh notifications (force update from Supabase)
  Future<void> refreshNotifications(String userId) async {
    _currentPage = 0;
    _notifications = [];
    _hasMore = true;
    await loadNotifications(userId, type: _currentFilter == 'all' ? null : _currentFilter);
    await loadUnreadCount(userId);
    await loadNotificationStats(userId);
  }

  /// Apply filter
  Future<void> applyFilter(String userId, String filter) async {
    if (filter == 'all') {
      await loadNotifications(userId);
    } else if (filter == 'unread') {
      await loadUnreadNotifications(userId);
    } else {
      await loadNotificationsByType(userId, filter);
    }
  }

  /// Clear all data
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _notificationStats = {};
    _errorMessage = null;
    _hasMore = true;
    _currentPage = 0;
    _currentFilter = null;
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
