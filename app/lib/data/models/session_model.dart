import 'package:equatable/equatable.dart';
import '../../core/utils/base_model.dart';

/// Session model
class SessionModel extends BaseModelWithId {
  final String tutorId;
  final String studentId;
  final String subjectId;
  final DateTime startTime;
  final DateTime endTime;
  final SessionStatus status;
  final SessionType type;
  final String? topic;
  final String? description;
  final double? hourlyRate;
  final String? meetingLink;
  final List<String>? attachments;
  final Map<String, dynamic>? notes;
  final SessionFeedback? feedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? totalAmount;
  final PaymentStatus paymentStatus;

  const SessionModel({
    required String id,
    required this.tutorId,
    required this.studentId,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.type,
    this.topic,
    this.description,
    this.hourlyRate,
    this.meetingLink,
    this.attachments,
    this.notes,
    this.feedback,
    this.createdAt,
    this.updatedAt,
    this.totalAmount,
    this.paymentStatus = PaymentStatus.pending,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutorId': tutorId,
      'studentId': studentId,
      'subjectId': subjectId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.toString(),
      'type': type.toString(),
      'topic': topic,
      'description': description,
      'hourlyRate': hourlyRate,
      'meetingLink': meetingLink,
      'attachments': attachments,
      'notes': notes,
      'feedback': feedback?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus.toString(),
    };
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      tutorId: json['tutorId'] as String,
      studentId: json['studentId'] as String,
      subjectId: json['subjectId'] as String,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      type: SessionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SessionType.online,
      ),
      topic: json['topic'] as String?,
      description: json['description'] as String?,
      hourlyRate: json['hourlyRate'] as double?,
      meetingLink: json['meetingLink'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>(),
      notes: json['notes'] as Map<String, dynamic>?,
      feedback: json['feedback'] != null
          ? SessionFeedback.fromJson(json['feedback'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      totalAmount: json['totalAmount'] as double?,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
    );
  }

  SessionModel copyWith({
    String? id,
    String? tutorId,
    String? studentId,
    String? subjectId,
    DateTime? startTime,
    DateTime? endTime,
    SessionStatus? status,
    SessionType? type,
    String? topic,
    String? description,
    double? hourlyRate,
    String? meetingLink,
    List<String>? attachments,
    Map<String, dynamic>? notes,
    SessionFeedback? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalAmount,
    PaymentStatus? paymentStatus,
  }) {
    return SessionModel(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      type: type ?? this.type,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      meetingLink: meetingLink ?? this.meetingLink,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  /// Get session duration in minutes
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Check if session is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(startTime);
  }

  /// Check if session is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if session is completed
  bool get isCompleted {
    return DateTime.now().isAfter(endTime);
  }

  @override
  List<Object?> get props => [
        id,
        tutorId,
        studentId,
        subjectId,
        startTime,
        endTime,
        status,
        type,
        topic,
        description,
        hourlyRate,
        meetingLink,
        attachments,
        notes,
        feedback,
        createdAt,
        updatedAt,
        totalAmount,
        paymentStatus,
      ];
}

/// Session status enum
enum SessionStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled,
}

/// Session type enum
enum SessionType {
  online,
  inPerson,
  phoneCall,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  partialRefund,
}

/// Availability slot model
class AvailabilitySlot extends BaseModel with EquatableMixin {
  final String tutorId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? notes;
  final String? timezone;

  const AvailabilitySlot({
    required this.tutorId,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.notes,
    this.timezone,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'tutorId': tutorId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAvailable': isAvailable,
      'notes': notes,
      'timezone': timezone,
    };
  }

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      tutorId: json['tutorId'] as String,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isAvailable: json['isAvailable'] as bool? ?? true,
      notes: json['notes'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        tutorId,
        startTime,
        endTime,
        isAvailable,
        notes,
        timezone,
      ];

  /// Get slot duration in minutes
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }
}

/// Session feedback model
class SessionFeedback extends BaseModel with EquatableMixin {
  final String sessionId;
  final String studentId;
  final int rating; // 1-5
  final String? comment;
  final String? improvements;
  final DateTime? createdAt;
  final Map<String, dynamic>? additionalRatings; // For detailed feedback

  const SessionFeedback({
    required this.sessionId,
    required this.studentId,
    required this.rating,
    this.comment,
    this.improvements,
    this.createdAt,
    this.additionalRatings,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'studentId': studentId,
      'rating': rating,
      'comment': comment,
      'improvements': improvements,
      'createdAt': createdAt?.toIso8601String(),
      'additionalRatings': additionalRatings,
    };
  }

  factory SessionFeedback.fromJson(Map<String, dynamic> json) {
    return SessionFeedback(
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      improvements: json['improvements'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      additionalRatings: json['additionalRatings'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        studentId,
        rating,
        comment,
        improvements,
        createdAt,
        additionalRatings,
      ];
}

/// Booking result model
class BookingResult extends BaseModel with EquatableMixin {
  final String sessionId;
  final bool success;
  final String? message;
  final String? paymentRequired;
  final Map<String, dynamic>? paymentDetails;

  const BookingResult({
    required this.sessionId,
    required this.success,
    this.message,
    this.paymentRequired,
    this.paymentDetails,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'success': success,
      'message': message,
      'paymentRequired': paymentRequired,
      'paymentDetails': paymentDetails,
    };
  }

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      sessionId: json['sessionId'] as String,
      success: json['success'] as bool,
      message: json['message'] as String?,
      paymentRequired: json['paymentRequired'] as String?,
      paymentDetails: json['paymentDetails'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        success,
        message,
        paymentRequired,
        paymentDetails,
      ];
}

/// Review model
class ReviewModel extends BaseModelWithId {
  final String tutorId;
  final String studentId;
  final String studentName;
  final String studentAvatar;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? sessionId;
  final bool isVerified;

  const ReviewModel({
    required String id,
    required this.tutorId,
    required this.studentId,
    required this.studentName,
    required this.studentAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.sessionId,
    this.isVerified = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutorId': tutorId,
      'studentId': studentId,
      'studentName': studentName,
      'studentAvatar': studentAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'sessionId': sessionId,
      'isVerified': isVerified,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      tutorId: json['tutorId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      studentAvatar: json['studentAvatar'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt']),
      sessionId: json['sessionId'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  ReviewModel copyWith({
    String? id,
    String? tutorId,
    String? studentId,
    String? studentName,
    String? studentAvatar,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? sessionId,
    bool? isVerified,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      sessionId: sessionId ?? this.sessionId,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tutorId,
        studentId,
        studentName,
        studentAvatar,
        rating,
        comment,
        createdAt,
        sessionId,
        isVerified,
      ];
}

/// Education model
class EducationModel extends BaseModel with EquatableMixin {
  final String institution;
  final String degree;
  final String? field;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrentlyStudying;
  final String? description;

  const EducationModel({
    required this.institution,
    required this.degree,
    this.field,
    this.startDate,
    this.endDate,
    this.isCurrentlyStudying = false,
    this.description,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'field': field,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrentlyStudying': isCurrentlyStudying,
      'description': description,
    };
  }

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      institution: json['institution'] as String,
      degree: json['degree'] as String,
      field: json['field'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      isCurrentlyStudying: json['isCurrentlyStudying'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        institution,
        degree,
        field,
        startDate,
        endDate,
        isCurrentlyStudying,
        description,
      ];
}

/// Work experience model
class WorkExperienceModel extends BaseModel with EquatableMixin {
  final String company;
  final String position;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrentlyWorking;
  final String? description;

  const WorkExperienceModel({
    required this.company,
    required this.position,
    this.startDate,
    this.endDate,
    this.isCurrentlyWorking = false,
    this.description,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrentlyWorking': isCurrentlyWorking,
      'description': description,
    };
  }

  factory WorkExperienceModel.fromJson(Map<String, dynamic> json) {
    return WorkExperienceModel(
      company: json['company'] as String,
      position: json['position'] as String,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      isCurrentlyWorking: json['isCurrentlyWorking'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        company,
        position,
        startDate,
        endDate,
        isCurrentlyWorking,
        description,
      ];
}