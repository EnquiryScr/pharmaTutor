import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../data/models/models.dart';
import 'irepository.dart';
import 'i_auth_repository.dart';

/// User repository interface
abstract class IUserRepository extends IRepository<UserModel> {
  const IUserRepository() : super();

  /// Get user profile
  /// Returns Either<Failure, UserModel>
  Future<Either<Failure, UserModel>> getProfile();

  /// Update user profile
  /// Returns Either<Failure, UserModel>
  Future<Either<Failure, UserModel>> updateProfile(UserModel user);

  /// Update user avatar
  /// Returns Either<Failure, String> (avatar URL)
  Future<Either<Failure, String>> updateAvatar(String imagePath);

  /// Change user password
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Delete user account
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> deleteAccount();
}

/// Tutor repository interface
abstract class ITutorRepository extends IPaginatedRepository<TutorModel> {
  const ITutorRepository() : super();

  /// Get tutors by subject
  /// Returns Either<Failure, List<TutorModel>>
  Future<Either<Failure, List<TutorModel>>> getTutorsBySubject(String subjectId);

  /// Get featured tutors
  /// Returns Either<Failure, List<TutorModel>>
  Future<Either<Failure, List<TutorModel>>> getFeaturedTutors();

  /// Get tutor availability
  /// Returns Either<Failure, List<AvailabilitySlot>>
  Future<Either<Failure, List<AvailabilitySlot>>> getTutorAvailability(String tutorId);

  /// Book a session with tutor
  /// Returns Either<Failure, BookingResult>
  Future<Either<Failure, BookingResult>> bookSession({
    required String tutorId,
    required String subjectId,
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Get tutor reviews
  /// Returns Either<Failure, List<ReviewModel>>
  Future<Either<Failure, List<ReviewModel>>> getTutorReviews(String tutorId);

  /// Submit tutor review
  /// Returns Either<Failure, ReviewModel>
  Future<Either<Failure, ReviewModel>> submitReview({
    required String tutorId,
    required String studentId,
    required int rating,
    required String comment,
  });
}

/// Subject repository interface
abstract class ISubjectRepository extends IPaginatedRepository<SubjectModel> {
  const ISubjectRepository() : super();

  /// Get subjects by category
  /// Returns Either<Failure, List<SubjectModel>>
  Future<Either<Failure, List<SubjectModel>>> getSubjectsByCategory(String categoryId);

  /// Get popular subjects
  /// Returns Either<Failure, List<SubjectModel>>
  Future<Either<Failure, List<SubjectModel>>> getPopularSubjects();

  /// Search subjects
  /// Returns Either<Failure, List<SubjectModel>>
  Future<Either<Failure, List<SubjectModel>>> searchSubjects(String query);

  /// Get subject statistics
  /// Returns Either<Failure, SubjectStatistics>
  Future<Either<Failure, SubjectStatistics>> getSubjectStatistics(String subjectId);
}

/// Course repository interface
abstract class ICourseRepository extends IPaginatedRepository<CourseModel> {
  const ICourseRepository() : super();

  /// Get courses by subject
  /// Returns Either<Failure, List<CourseModel>>
  Future<Either<Failure, List<CourseModel>>> getCoursesBySubject(String subjectId);

  /// Get enrolled courses for student
  /// Returns Either<Failure, List<CourseModel>>
  Future<Either<Failure, List<CourseModel>>> getEnrolledCourses(String studentId);

  /// Enroll in a course
  /// Returns Either<Failure, CourseEnrollment>
  Future<Either<Failure, CourseEnrollment>> enrollInCourse({
    required String courseId,
    required String studentId,
  });

  /// Get course progress
  /// Returns Either<Failure, CourseProgress>
  Future<Either<Failure, CourseProgress>> getCourseProgress({
    required String courseId,
    required String studentId,
  });

  /// Get course content
  /// Returns Either<Failure, List<CourseContent>>
  Future<Either<Failure, List<CourseContent>>> getCourseContent(String courseId);

  /// Mark lesson as completed
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> markLessonCompleted({
    required String lessonId,
    required String studentId,
  });

  /// Submit assignment
  /// Returns Either<Failure, AssignmentSubmission>
  Future<Either<Failure, AssignmentSubmission>> submitAssignment({
    required String assignmentId,
    required String studentId,
    required List<String> filePaths,
  });
}

/// Session repository interface
abstract class ISessionRepository extends IPaginatedRepository<SessionModel> {
  const ISessionRepository() : super();

  /// Get upcoming sessions for user
  /// Returns Either<Failure, List<SessionModel>>
  Future<Either<Failure, List<SessionModel>>> getUpcomingSessions(String userId);

  /// Get session history
  /// Returns Either<Failure, List<SessionModel>>
  Future<Either<Failure, List<SessionModel>>> getSessionHistory(String userId);

  /// Cancel session
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> cancelSession({
    required String sessionId,
    required String reason,
  });

  /// Reschedule session
  /// Returns Either<Failure, SessionModel>
  Future<Either<Failure, SessionModel>> rescheduleSession({
    required String sessionId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  });

  /// Start session
  /// Returns Either<Failure, SessionModel>
  Future<Either<Failure, SessionModel>> startSession(String sessionId);

  /// End session
  /// Returns Either<Failure, SessionModel>
  Future<Either<Failure, SessionModel>> endSession(String sessionId);

  /// Get session feedback
  /// Returns Either<Failure, SessionFeedback>
  Future<Either<Failure, SessionFeedback>> getSessionFeedback(String sessionId);

  /// Submit session feedback
  /// Returns Either<Failure, SessionFeedback>
  Future<Either<Failure, SessionFeedback>> submitSessionFeedback({
    required String sessionId,
    required String studentId,
    required int rating,
    required String comment,
    String? improvements,
  });
}

/// Message repository interface
abstract class IMessageRepository extends IRepository<MessageModel> {
  const IMessageRepository() : super();

  /// Get conversations for user
  /// Returns Either<Failure, List<ConversationModel>>
  Future<Either<Failure, List<ConversationModel>>> getConversations(String userId);

  /// Get messages for conversation
  /// Returns Either<Failure, List<MessageModel>>
  Future<Either<Failure, List<MessageModel>>> getMessages({
    required String conversationId,
    int? page,
    int? limit,
  });

  /// Send message
  /// Returns Either<Failure, MessageModel>
  Future<Either<Failure, MessageModel>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    List<String>? attachments,
  });

  /// Mark conversation as read
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> markAsRead(String conversationId, String userId);

  /// Create new conversation
  /// Returns Either<Failure, ConversationModel>
  Future<Either<Failure, ConversationModel>> createConversation({
    required String initiatorId,
    required String recipientId,
    String? subject,
  });

  /// Upload message attachment
  /// Returns Either<Failure, String> (attachment URL)
  Future<Either<Failure, String>> uploadAttachment(String filePath);
}

/// Payment repository interface
abstract class IPaymentRepository extends IRepository<PaymentModel> {
  const IPaymentRepository() : super();

  /// Get payment methods for user
  /// Returns Either<Failure, List<PaymentMethod>>
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods(String userId);

  /// Add payment method
  /// Returns Either<Failure, PaymentMethod>
  Future<Either<Failure, PaymentMethod>> addPaymentMethod({
    required String userId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  });

  /// Process payment for session
  /// Returns Either<Failure, PaymentResult>
  Future<Either<Failure, PaymentResult>> processSessionPayment({
    required String sessionId,
    required String studentId,
    required String paymentMethodId,
    required double amount,
  });

  /// Get payment history
  /// Returns Either<Failure, List<PaymentModel>>
  Future<Either<Failure, List<PaymentModel>>> getPaymentHistory(String userId);

  /// Request refund
  /// Returns Either<Failure, RefundRequest>
  Future<Either<Failure, RefundRequest>> requestRefund({
    required String paymentId,
    required String reason,
    required double amount,
  });

  /// Get invoice
  /// Returns Either<Failure, InvoiceModel>
  Future<Either<Failure, InvoiceModel>> getInvoice(String paymentId);
}

/// Notification repository interface
abstract class INotificationRepository extends IPaginatedRepository<NotificationModel> {
  const INotificationRepository() : super();

  /// Get unread notifications count
  /// Returns Either<Failure, int>
  Future<Either<Failure, int>> getUnreadCount(String userId);

  /// Mark notification as read
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> markAllAsRead(String userId);

  /// Update notification settings
  /// Returns Either<Failure, NotificationSettings>
  Future<Either<Failure, NotificationSettings>> updateSettings({
    required String userId,
    required NotificationSettings settings,
  });

  /// Get notification settings
  /// Returns Either<Failure, NotificationSettings>
  Future<Either<Failure, NotificationSettings>> getSettings(String userId);
}

/// File repository interface
abstract class IFileRepository extends IRepository {
  const IFileRepository() : super();

  /// Upload file
  /// Returns Either<Failure, String> (file URL)
  Future<Either<Failure, String>> uploadFile({
    required String filePath,
    required String fileName,
    required String contentType,
    String? folder,
  });

  /// Download file
  /// Returns Either<Failure, String> (local file path)
  Future<Either<Failure, String>> downloadFile({
    required String fileUrl,
    String? fileName,
  });

  /// Delete file
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> deleteFile(String fileUrl);

  /// Get file info
  /// Returns Either<Failure, FileInfo>
  Future<Either<Failure, FileInfo>> getFileInfo(String fileUrl);

  /// Generate file thumbnail
  /// Returns Either<Failure, String> (thumbnail URL)
  Future<Either<Failure, String>> generateThumbnail({
    required String fileUrl,
    int? width,
    int? height,
  });
}

/// Analytics repository interface
abstract class IAnalyticsRepository extends IRepository {
  const IAnalyticsRepository() : super();

  /// Get student progress analytics
  /// Returns Either<Failure, StudentAnalytics>
  Future<Either<Failure, StudentAnalytics>> getStudentProgress(String studentId);

  /// Get tutor performance analytics
  /// Returns Either<Failure, TutorAnalytics>
  Future<Either<Failure, TutorAnalytics>> getTutorPerformance(String tutorId);

  /// Get platform analytics
  /// Returns Either<Failure, PlatformAnalytics>
  Future<Either<Failure, PlatformAnalytics>> getPlatformAnalytics();

  /// Track user event
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> trackEvent({
    required String userId,
    required String eventName,
    Map<String, dynamic>? properties,
  });

  /// Get revenue analytics
  /// Returns Either<Failure, RevenueAnalytics>
  Future<Either<Failure, RevenueAnalytics>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  });
}