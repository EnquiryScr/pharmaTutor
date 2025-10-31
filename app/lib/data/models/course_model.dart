import 'package:equatable/equatable.dart';
import '../../core/utils/base_model.dart';

/// Course model
class CourseModel extends BaseModelWithId {
  final String title;
  final String description;
  final String subjectId;
  final String tutorId;
  final String tutorName;
  final String? tutorAvatar;
  final String? thumbnailUrl;
  final double? price;
  final int totalLessons;
  final int totalDuration; // in minutes
  final double? rating;
  final int totalStudents;
  final CourseLevel level;
  final String? syllabus;
  final List<String> prerequisites;
  final List<LearningObjective> learningObjectives;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final String? language;

  const CourseModel({
    required String id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.tutorId,
    required this.tutorName,
    this.tutorAvatar,
    this.thumbnailUrl,
    this.price,
    this.totalLessons = 0,
    this.totalDuration = 0,
    this.rating,
    this.totalStudents = 0,
    this.level = CourseLevel.beginner,
    this.syllabus,
    this.prerequisites = const [],
    this.learningObjectives = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.language,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'tutorAvatar': tutorAvatar,
      'thumbnailUrl': thumbnailUrl,
      'price': price,
      'totalLessons': totalLessons,
      'totalDuration': totalDuration,
      'rating': rating,
      'totalStudents': totalStudents,
      'level': level.toString(),
      'syllabus': syllabus,
      'prerequisites': prerequisites,
      'learningObjectives': learningObjectives.map((obj) => obj.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'language': language,
    };
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      subjectId: json['subjectId'] as String,
      tutorId: json['tutorId'] as String,
      tutorName: json['tutorName'] as String,
      tutorAvatar: json['tutorAvatar'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      price: json['price'] as double?,
      totalLessons: json['totalLessons'] as int? ?? 0,
      totalDuration: json['totalDuration'] as int? ?? 0,
      rating: json['rating'] as double?,
      totalStudents: json['totalStudents'] as int? ?? 0,
      level: CourseLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
        orElse: () => CourseLevel.beginner,
      ),
      syllabus: json['syllabus'] as String?,
      prerequisites: (json['prerequisites'] as List<dynamic>?)?.cast<String>() ?? [],
      learningObjectives: (json['learningObjectives'] as List<dynamic>?)
              ?.map((obj) => LearningObjective.fromJson(obj))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      language: json['language'] as String?,
    );
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    String? tutorId,
    String? tutorName,
    String? tutorAvatar,
    String? thumbnailUrl,
    double? price,
    int? totalLessons,
    int? totalDuration,
    double? rating,
    int? totalStudents,
    CourseLevel? level,
    String? syllabus,
    List<String>? prerequisites,
    List<LearningObjective>? learningObjectives,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? language,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      tutorId: tutorId ?? this.tutorId,
      tutorName: tutorName ?? this.tutorName,
      tutorAvatar: tutorAvatar ?? this.tutorAvatar,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      totalLessons: totalLessons ?? this.totalLessons,
      totalDuration: totalDuration ?? this.totalDuration,
      rating: rating ?? this.rating,
      totalStudents: totalStudents ?? this.totalStudents,
      level: level ?? this.level,
      syllabus: syllabus ?? this.syllabus,
      prerequisites: prerequisites ?? this.prerequisites,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      language: language ?? this.language,
    );
  }

  /// Get formatted duration string
  String get formattedDuration {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0) {
      return '${hours}h ${minutes > 0 ? '${minutes}m' : ''}'.trim();
    }
    return '${minutes}m';
  }

  /// Get difficulty level text
  String get levelText {
    switch (level) {
      case CourseLevel.beginner:
        return 'Beginner';
      case CourseLevel.intermediate:
        return 'Intermediate';
      case CourseLevel.advanced:
        return 'Advanced';
    }
  }

  /// Check if course is free
  bool get isFree => price == null || price == 0.0;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        subjectId,
        tutorId,
        tutorName,
        tutorAvatar,
        thumbnailUrl,
        price,
        totalLessons,
        totalDuration,
        rating,
        totalStudents,
        level,
        syllabus,
        prerequisites,
        learningObjectives,
        isActive,
        createdAt,
        updatedAt,
        tags,
        language,
      ];
}

/// Course levels
enum CourseLevel {
  beginner,
  intermediate,
  advanced,
}

/// Learning objective model
class LearningObjective extends BaseModel with EquatableMixin {
  final String title;
  final String? description;
  final List<String> topics;

  const LearningObjective({
    required this.title,
    this.description,
    this.topics = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'topics': topics,
    };
  }

  factory LearningObjective.fromJson(Map<String, dynamic> json) {
    return LearningObjective(
      title: json['title'] as String,
      description: json['description'] as String?,
      topics: (json['topics'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  List<Object?> get props => [title, description, topics];
}

/// Course content model
class CourseContent extends BaseModelWithId {
  final String courseId;
  final String title;
  final String description;
  final ContentType type;
  final String? contentUrl;
  final String? thumbnailUrl;
  final int orderIndex;
  final int duration; // in seconds
  final bool isCompleted;
  final bool isLocked;
  final Map<String, dynamic>? additionalData;

  const CourseContent({
    required String id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    this.contentUrl,
    this.thumbnailUrl,
    required this.orderIndex,
    this.duration = 0,
    this.isCompleted = false,
    this.isLocked = false,
    this.additionalData,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'type': type.toString(),
      'contentUrl': contentUrl,
      'thumbnailUrl': thumbnailUrl,
      'orderIndex': orderIndex,
      'duration': duration,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
      'additionalData': additionalData,
    };
  }

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ContentType.video,
      ),
      contentUrl: json['contentUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      orderIndex: json['orderIndex'] as int,
      duration: json['duration'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  CourseContent copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    ContentType? type,
    String? contentUrl,
    String? thumbnailUrl,
    int? orderIndex,
    int? duration,
    bool? isCompleted,
    bool? isLocked,
    Map<String, dynamic>? additionalData,
  }) {
    return CourseContent(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      contentUrl: contentUrl ?? this.contentUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Get formatted duration
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if content type is video
  bool get isVideo => type == ContentType.video;

  /// Check if content type is document
  bool get isDocument => type == ContentType.document;

  /// Check if content type is quiz
  bool get isQuiz => type == ContentType.quiz;

  /// Check if content type is assignment
  bool get isAssignment => type == ContentType.assignment;

  @override
  List<Object?> get props => [
        id,
        courseId,
        title,
        description,
        type,
        contentUrl,
        thumbnailUrl,
        orderIndex,
        duration,
        isCompleted,
        isLocked,
        additionalData,
      ];
}

/// Content types
enum ContentType {
  video,
  document,
  quiz,
  assignment,
  liveSession,
  interactive,
}

/// Course enrollment model
class CourseEnrollment extends BaseModelWithId {
  final String courseId;
  final String studentId;
  final DateTime enrolledAt;
  final double progress; // 0.0 to 1.0
  final DateTime? lastAccessedAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final double? finalGrade;
  final Map<String, dynamic>? additionalData;

  const CourseEnrollment({
    required String id,
    required this.courseId,
    required this.studentId,
    required this.enrolledAt,
    this.progress = 0.0,
    this.lastAccessedAt,
    this.isCompleted = false,
    this.completedAt,
    this.finalGrade,
    this.additionalData,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'studentId': studentId,
      'enrolledAt': enrolledAt.toIso8601String(),
      'progress': progress,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'finalGrade': finalGrade,
      'additionalData': additionalData,
    };
  }

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) {
    return CourseEnrollment(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      studentId: json['studentId'] as String,
      enrolledAt: DateTime.parse(json['enrolledAt']),
      progress: json['progress'] as double? ?? 0.0,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'])
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      finalGrade: json['finalGrade'] as double?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  CourseEnrollment copyWith({
    String? id,
    String? courseId,
    String? studentId,
    DateTime? enrolledAt,
    double? progress,
    DateTime? lastAccessedAt,
    bool? isCompleted,
    DateTime? completedAt,
    double? finalGrade,
    Map<String, dynamic>? additionalData,
  }) {
    return CourseEnrollment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      progress: progress ?? this.progress,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      finalGrade: finalGrade ?? this.finalGrade,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Get progress percentage
  int get progressPercentage => (progress * 100).round();

  /// Check if enrollment is active
  bool get isActive => !isCompleted;

  @override
  List<Object?> get props => [
        id,
        courseId,
        studentId,
        enrolledAt,
        progress,
        lastAccessedAt,
        isCompleted,
        completedAt,
        finalGrade,
        additionalData,
      ];
}

/// Course progress model
class CourseProgress extends BaseModel with EquatableMixin {
  final String courseId;
  final String studentId;
  final Map<String, bool> completedLessons; // lessonId -> isCompleted
  final double overallProgress; // 0.0 to 1.0
  final int totalLessonsCompleted;
  final int totalLessons;
  final DateTime? lastAccessedAt;
  final Map<String, double>? lessonProgress; // lessonId -> progress
  final List<String> downloadedLessons;

  const CourseProgress({
    required this.courseId,
    required this.studentId,
    this.completedLessons = const {},
    this.overallProgress = 0.0,
    this.totalLessonsCompleted = 0,
    this.totalLessons = 0,
    this.lastAccessedAt,
    this.lessonProgress = const {},
    this.downloadedLessons = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'studentId': studentId,
      'completedLessons': completedLessons,
      'overallProgress': overallProgress,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalLessons': totalLessons,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'lessonProgress': lessonProgress,
      'downloadedLessons': downloadedLessons,
    };
  }

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] as String,
      studentId: json['studentId'] as String,
      completedLessons: Map<String, bool>.from(json['completedLessons'] ?? {}),
      overallProgress: json['overallProgress'] as double? ?? 0.0,
      totalLessonsCompleted: json['totalLessonsCompleted'] as int? ?? 0,
      totalLessons: json['totalLessons'] as int? ?? 0,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'])
          : null,
      lessonProgress: Map<String, double>.from(json['lessonProgress'] ?? {}),
      downloadedLessons: (json['downloadedLessons'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
  }

  /// Get progress percentage
  int get progressPercentage => (overallProgress * 100).round();

  /// Check if lesson is completed
  bool isLessonCompleted(String lessonId) {
    return completedLessons[lessonId] ?? false;
  }

  /// Mark lesson as completed
  CourseProgress markLessonCompleted(String lessonId) {
    final newCompletedLessons = {...completedLessons, lessonId: true};
    final newCompletedCount = completedLessons.values.where((completed) => completed).length + 1;
    final newOverallProgress = newCompletedCount / totalLessons;

    return copyWith(
      completedLessons: newCompletedLessons,
      totalLessonsCompleted: newCompletedCount,
      overallProgress: newOverallProgress,
      lastAccessedAt: DateTime.now(),
    );
  }

  /// Update lesson progress
  CourseProgress updateLessonProgress(String lessonId, double progress) {
    final newLessonProgress = {...lessonProgress, lessonId: progress};
    return copyWith(lessonProgress: newLessonProgress);
  }

  CourseProgress copyWith({
    String? courseId,
    String? studentId,
    Map<String, bool>? completedLessons,
    double? overallProgress,
    int? totalLessonsCompleted,
    int? totalLessons,
    DateTime? lastAccessedAt,
    Map<String, double>? lessonProgress,
    List<String>? downloadedLessons,
  }) {
    return CourseProgress(
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      completedLessons: completedLessons ?? this.completedLessons,
      overallProgress: overallProgress ?? this.overallProgress,
      totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalLessons: totalLessons ?? this.totalLessons,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      downloadedLessons: downloadedLessons ?? this.downloadedLessons,
    );
  }

  @override
  List<Object?> get props => [
        courseId,
        studentId,
        completedLessons,
        overallProgress,
        totalLessonsCompleted,
        totalLessons,
        lastAccessedAt,
        lessonProgress,
        downloadedLessons,
      ];
}

/// Assignment submission model
class AssignmentSubmission extends BaseModelWithId {
  final String assignmentId;
  final String studentId;
  final List<String> fileUrls;
  final String? textAnswer;
  final SubmissionStatus status;
  final double? grade;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final Map<String, dynamic>? additionalData;

  const AssignmentSubmission({
    required String id,
    required this.assignmentId,
    required this.studentId,
    this.fileUrls = const [],
    this.textAnswer,
    this.status = SubmissionStatus.submitted,
    this.grade,
    this.feedback,
    required this.submittedAt,
    this.gradedAt,
    this.additionalData,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'fileUrls': fileUrls,
      'textAnswer': textAnswer,
      'status': status.toString(),
      'grade': grade,
      'feedback': feedback,
      'submittedAt': submittedAt.toIso8601String(),
      'gradedAt': gradedAt?.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'] as String,
      assignmentId: json['assignmentId'] as String,
      studentId: json['studentId'] as String,
      fileUrls: (json['fileUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      textAnswer: json['textAnswer'] as String?,
      status: SubmissionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => SubmissionStatus.submitted,
      ),
      grade: json['grade'] as double?,
      feedback: json['feedback'] as String?,
      submittedAt: DateTime.parse(json['submittedAt']),
      gradedAt: json['gradedAt'] != null
          ? DateTime.parse(json['gradedAt'])
          : null,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  AssignmentSubmission copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    List<String>? fileUrls,
    String? textAnswer,
    SubmissionStatus? status,
    double? grade,
    String? feedback,
    DateTime? submittedAt,
    DateTime? gradedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return AssignmentSubmission(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      fileUrls: fileUrls ?? this.fileUrls,
      textAnswer: textAnswer ?? this.textAnswer,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Check if submission is graded
  bool get isGraded => status == SubmissionStatus.graded;

  /// Check if submission is late
  bool get isLate {
    // This would need assignment due date to properly calculate
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        assignmentId,
        studentId,
        fileUrls,
        textAnswer,
        status,
        grade,
        feedback,
        submittedAt,
        gradedAt,
        additionalData,
      ];
}

/// Submission status enum
enum SubmissionStatus {
  submitted,
  graded,
  late,
  rejected,
}

/// Subject statistics model
class SubjectStatistics extends BaseModel with EquatableMixin {
  final String subjectId;
  final int totalTutors;
  final int totalStudents;
  final int totalSessions;
  final double averageRating;
  final int totalCourses;
  final double averageSessionPrice;
  final Map<String, int> sessionDistribution; // Price ranges -> count
  final List<String> popularTimeSlots;

  const SubjectStatistics({
    required this.subjectId,
    this.totalTutors = 0,
    this.totalStudents = 0,
    this.totalSessions = 0,
    this.averageRating = 0.0,
    this.totalCourses = 0,
    this.averageSessionPrice = 0.0,
    this.sessionDistribution = const {},
    this.popularTimeSlots = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'totalTutors': totalTutors,
      'totalStudents': totalStudents,
      'totalSessions': totalSessions,
      'averageRating': averageRating,
      'totalCourses': totalCourses,
      'averageSessionPrice': averageSessionPrice,
      'sessionDistribution': sessionDistribution,
      'popularTimeSlots': popularTimeSlots,
    };
  }

  factory SubjectStatistics.fromJson(Map<String, dynamic> json) {
    return SubjectStatistics(
      subjectId: json['subjectId'] as String,
      totalTutors: json['totalTutors'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      averageRating: json['averageRating'] as double? ?? 0.0,
      totalCourses: json['totalCourses'] as int? ?? 0,
      averageSessionPrice: json['averageSessionPrice'] as double? ?? 0.0,
      sessionDistribution: Map<String, int>.from(json['sessionDistribution'] ?? {}),
      popularTimeSlots: (json['popularTimeSlots'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        totalTutors,
        totalStudents,
        totalSessions,
        averageRating,
        totalCourses,
        averageSessionPrice,
        sessionDistribution,
        popularTimeSlots,
      ];
}