import 'package:equatable/equatable.dart';
import '../../core/utils/base_model.dart';

/// Notification model
class NotificationModel extends BaseModelWithId {
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final String? iconUrl;
  final String? imageUrl;
  final String? actionText;
  final String? actionUrl;
  final NotificationPriority priority;
  final bool isDismissible;
  final DateTime? expiresAt;

  const NotificationModel({
    required String id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.iconUrl,
    this.imageUrl,
    this.actionText,
    this.actionUrl,
    this.priority = NotificationPriority.normal,
    this.isDismissible = true,
    this.expiresAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'actionText': actionText,
      'actionUrl': actionUrl,
      'priority': priority.toString(),
      'isDismissible': isDismissible,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.info,
      ),
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      iconUrl: json['iconUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      actionText: json['actionText'] as String?,
      actionUrl: json['actionUrl'] as String?,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      isDismissible: json['isDismissible'] as bool? ?? true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    String? iconUrl,
    String? imageUrl,
    String? actionText,
    String? actionUrl,
    NotificationPriority? priority,
    bool? isDismissible,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      actionText: actionText ?? this.actionText,
      actionUrl: actionUrl ?? this.actionUrl,
      priority: priority ?? this.priority,
      isDismissible: isDismissible ?? this.isDismissible,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification is urgent
  bool get isUrgent => priority == NotificationPriority.high;

  /// Check if notification is session-related
  bool get isSessionNotification => [
        NotificationType.sessionScheduled,
        NotificationType.sessionReminder,
        NotificationType.sessionCompleted,
        NotificationType.sessionCancelled,
      ].contains(type);

  /// Check if notification is payment-related
  bool get isPaymentNotification => [
        NotificationType.paymentReceived,
        NotificationType.paymentFailed,
        NotificationType.refundProcessed,
      ].contains(type);

  /// Get notification icon based on type
  String? getNotificationIcon() {
    switch (type) {
      case NotificationType.sessionScheduled:
      case NotificationType.sessionReminder:
      case NotificationType.sessionCompleted:
        return 'calendar';
      case NotificationType.messageReceived:
        return 'message';
      case NotificationType.paymentReceived:
      case NotificationType.paymentFailed:
      case NotificationType.refundProcessed:
        return 'payment';
      case NotificationType.courseEnrollment:
        return 'course';
      case NotificationType.assignmentDue:
        return 'assignment';
      case NotificationType.systemMaintenance:
        return 'maintenance';
      default:
        return iconUrl;
    }
  }

  /// Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        message,
        type,
        data,
        isRead,
        createdAt,
        iconUrl,
        imageUrl,
        actionText,
        actionUrl,
        priority,
        isDismissible,
        expiresAt,
      ];
}

/// Notification types
enum NotificationType {
  info,
  success,
  warning,
  error,
  sessionScheduled,
  sessionReminder,
  sessionCompleted,
  sessionCancelled,
  sessionRescheduled,
  messageReceived,
  paymentReceived,
  paymentFailed,
  refundProcessed,
  courseEnrollment,
  assignmentDue,
  gradePosted,
  systemMaintenance,
  promotion,
  security,
}

/// Notification priority enum
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification settings model
class NotificationSettings extends BaseModel with EquatableMixin {
  final String userId;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool sessionNotifications;
  final bool messageNotifications;
  final bool paymentNotifications;
  final bool courseNotifications;
  final bool marketingNotifications;
  final bool systemNotifications;
  final Map<NotificationType, bool> typeSpecificSettings;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool quietHoursEnabled;
  final DateTime updatedAt;

  const NotificationSettings({
    required this.userId,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.sessionNotifications = true,
    this.messageNotifications = true,
    this.paymentNotifications = true,
    this.courseNotifications = true,
    this.marketingNotifications = false,
    this.systemNotifications = true,
    this.typeSpecificSettings = const {},
    this.quietHoursStart,
    this.quietHoursEnd,
    this.quietHoursEnabled = false,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'sessionNotifications': sessionNotifications,
      'messageNotifications': messageNotifications,
      'paymentNotifications': paymentNotifications,
      'courseNotifications': courseNotifications,
      'marketingNotifications': marketingNotifications,
      'systemNotifications': systemNotifications,
      'typeSpecificSettings': typeSpecificSettings,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursEnabled': quietHoursEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['userId'] as String,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? false,
      sessionNotifications: json['sessionNotifications'] as bool? ?? true,
      messageNotifications: json['messageNotifications'] as bool? ?? true,
      paymentNotifications: json['paymentNotifications'] as bool? ?? true,
      courseNotifications: json['courseNotifications'] as bool? ?? true,
      marketingNotifications: json['marketingNotifications'] as bool? ?? false,
      systemNotifications: json['systemNotifications'] as bool? ?? true,
      typeSpecificSettings: Map<NotificationType, bool>.from(
        json['typeSpecificSettings'] ?? {}
      ),
      quietHoursStart: json['quietHoursStart'] as String?,
      quietHoursEnd: json['quietHoursEnd'] as String?,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  NotificationSettings copyWith({
    String? userId,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? sessionNotifications,
    bool? messageNotifications,
    bool? paymentNotifications,
    bool? courseNotifications,
    bool? marketingNotifications,
    bool? systemNotifications,
    Map<NotificationType, bool>? typeSpecificSettings,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      sessionNotifications: sessionNotifications ?? this.sessionNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      courseNotifications: courseNotifications ?? this.courseNotifications,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      typeSpecificSettings: typeSpecificSettings ?? this.typeSpecificSettings,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if notifications are enabled for a specific type
  bool isNotificationEnabled(NotificationType type) {
    // Check type-specific settings first
    if (typeSpecificSettings.containsKey(type)) {
      return typeSpecificSettings[type]!;
    }
    
    // Check category-based settings
    switch (type) {
      case NotificationType.sessionScheduled:
      case NotificationType.sessionReminder:
      case NotificationType.sessionCompleted:
      case NotificationType.sessionCancelled:
      case NotificationType.sessionRescheduled:
        return sessionNotifications;
      case NotificationType.messageReceived:
        return messageNotifications;
      case NotificationType.paymentReceived:
      case NotificationType.paymentFailed:
      case NotificationType.refundProcessed:
        return paymentNotifications;
      case NotificationType.courseEnrollment:
      case NotificationType.assignmentDue:
      case NotificationType.gradePosted:
        return courseNotifications;
      case NotificationType.marketingNotifications:
      case NotificationType.promotion:
        return marketingNotifications;
      case NotificationType.systemMaintenance:
      case NotificationType.security:
      case NotificationType.systemNotifications:
        return systemNotifications;
      default:
        return pushNotifications;
    }
  }

  /// Check if user is in quiet hours
  bool isInQuietHours() {
    if (!quietHoursEnabled || quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    if (quietHoursStart! == quietHoursEnd!) {
      // 24-hour quiet period
      return true;
    }
    
    if (quietHoursStart! < quietHoursEnd!) {
      // Same day quiet period
      return currentTime >= quietHoursStart! && currentTime <= quietHoursEnd!;
    } else {
      // Overnight quiet period
      return currentTime >= quietHoursStart! || currentTime <= quietHoursEnd!;
    }
  }

  @override
  List<Object?> get props => [
        userId,
        emailNotifications,
        pushNotifications,
        smsNotifications,
        sessionNotifications,
        messageNotifications,
        paymentNotifications,
        courseNotifications,
        marketingNotifications,
        systemNotifications,
        typeSpecificSettings,
        quietHoursStart,
        quietHoursEnd,
        quietHoursEnabled,
        updatedAt,
      ];
}

/// Push notification token model
class PushTokenModel extends BaseModel with EquatableMixin {
  final String userId;
  final String token;
  final String platform; // 'ios', 'android', 'web'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final Map<String, dynamic>? metadata;

  const PushTokenModel({
    required this.userId,
    required this.token,
    required this.platform,
    this.isActive = true,
    required this.createdAt,
    this.lastUsedAt,
    this.metadata,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'token': token,
      'platform': platform,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PushTokenModel.fromJson(Map<String, dynamic> json) {
    return PushTokenModel(
      userId: json['userId'] as String,
      token: json['token'] as String,
      platform: json['platform'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        token,
        platform,
        isActive,
        createdAt,
        lastUsedAt,
        metadata,
      ];
}