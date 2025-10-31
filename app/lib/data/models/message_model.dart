import 'package:equatable/equatable.dart';
import '../../core/utils/base_model.dart';

/// Message model
class MessageModel extends BaseModelWithId {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final MessageType type;
  final List<String>? attachments;
  final DateTime sentAt;
  final bool isRead;
  final bool isEdited;
  final DateTime? editedAt;
  final MessageStatus status;

  const MessageModel({
    required String id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.type,
    this.attachments,
    required this.sentAt,
    this.isRead = false,
    this.isEdited = false,
    this.editedAt,
    this.status = MessageStatus.sent,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.toString(),
      'attachments': attachments,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'status': status.toString(),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>(),
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    List<String>? attachments,
    DateTime? sentAt,
    bool? isRead,
    bool? isEdited,
    DateTime? editedAt,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
    );
  }

  /// Check if message is from current user
  bool isFromUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Check if message has attachments
  bool get hasAttachments => attachments?.isNotEmpty == true;

  /// Check if message is text message
  bool get isTextMessage => type == MessageType.text;

  /// Check if message is image
  bool get isImageMessage => type == MessageType.image;

  /// Check if message is file
  bool get isFileMessage => type == MessageType.file;

  /// Get formatted send time
  String get formattedTime {
    return '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatar,
        content,
        type,
        attachments,
        sentAt,
        isRead,
        isEdited,
        editedAt,
        status,
      ];
}

/// Message types
enum MessageType {
  text,
  image,
  file,
  system,
  location,
}

/// Message status enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Conversation model
class ConversationModel extends BaseModelWithId {
  final String initiatorId;
  final String recipientId;
  final String initiatorName;
  final String initiatorAvatar;
  final String recipientName;
  final String recipientAvatar;
  final String? subject;
  final MessageModel? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ConversationStatus status;
  final bool isArchived;

  const ConversationModel({
    required String id,
    required this.initiatorId,
    required this.recipientId,
    required this.initiatorName,
    required this.initiatorAvatar,
    required this.recipientName,
    required this.recipientAvatar,
    this.subject,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.status = ConversationStatus.active,
    this.isArchived = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'initiatorId': initiatorId,
      'recipientId': recipientId,
      'initiatorName': initiatorName,
      'initiatorAvatar': initiatorAvatar,
      'recipientName': recipientName,
      'recipientAvatar': recipientAvatar,
      'subject': subject,
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toString(),
      'isArchived': isArchived,
    };
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      initiatorId: json['initiatorId'] as String,
      recipientId: json['recipientId'] as String,
      initiatorName: json['initiatorName'] as String,
      initiatorAvatar: json['initiatorAvatar'] as String,
      recipientName: json['recipientName'] as String,
      recipientAvatar: json['recipientAvatar'] as String,
      subject: json['subject'] as String?,
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: ConversationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ConversationStatus.active,
      ),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  ConversationModel copyWith({
    String? id,
    String? initiatorId,
    String? recipientId,
    String? initiatorName,
    String? initiatorAvatar,
    String? recipientName,
    String? recipientAvatar,
    String? subject,
    MessageModel? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    ConversationStatus? status,
    bool? isArchived,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      initiatorId: initiatorId ?? this.initiatorId,
      recipientId: recipientId ?? this.recipientId,
      initiatorName: initiatorName ?? this.initiatorName,
      initiatorAvatar: initiatorAvatar ?? this.initiatorAvatar,
      recipientName: recipientName ?? this.recipientName,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
      subject: subject ?? this.subject,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Get the other participant (not current user)
  String getOtherParticipantId(String currentUserId) {
    return currentUserId == initiatorId ? recipientId : initiatorId;
  }

  /// Get the other participant's name
  String getOtherParticipantName(String currentUserId) {
    return currentUserId == initiatorId ? recipientName : initiatorName;
  }

  /// Get the other participant's avatar
  String getOtherParticipantAvatar(String currentUserId) {
    return currentUserId == initiatorId ? recipientAvatar : initiatorAvatar;
  }

  /// Check if conversation is with current user
  bool isWithUser(String userId) {
    return initiatorId == userId || recipientId == userId;
  }

  @override
  List<Object?> get props => [
        id,
        initiatorId,
        recipientId,
        initiatorName,
        initiatorAvatar,
        recipientName,
        recipientAvatar,
        subject,
        lastMessage,
        createdAt,
        updatedAt,
        status,
        isArchived,
      ];
}

/// Conversation status enum
enum ConversationStatus {
  active,
  archived,
  muted,
  blocked,
}