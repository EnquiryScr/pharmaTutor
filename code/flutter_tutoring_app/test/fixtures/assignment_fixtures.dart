import '../test_config.dart';

/// Assignment test fixtures for consistent test data
class AssignmentFixtures {
  // Test assignments
  static const mathematicsAssignment = {
    'id': 'assignment-123',
    'title': 'Algebra Problem Set 3',
    'description': 'Solve the following algebraic equations and inequalities. Show all work clearly.',
    'subject': 'Mathematics',
    'topic': 'Algebra',
    'difficulty': 'intermediate',
    'estimatedDuration': 120, // minutes
    'totalPoints': 100,
    'createdBy': 'tutor-456',
    'createdByName': 'Jane Smith',
    'createdAt': '2024-01-01T00:00:00Z',
    'dueDate': '2024-01-08T23:59:59Z',
    'status': 'active',
    'instructions': [
      'Show all work for each problem',
      'Round final answers to two decimal places',
      'Include units in your answers where applicable',
    ],
    'questions': [
      {
        'id': 'q1',
        'type': 'multiple_choice',
        'question': 'What is the solution to 2x + 5 = 13?',
        'options': [
          {'value': 'a', 'text': 'x = 3'},
          {'value': 'b', 'text': 'x = 4'},
          {'value': 'c', 'text': 'x = 5'},
          {'value': 'd', 'text': 'x = 6'},
        ],
        'correctAnswer': 'b',
        'points': 20,
        'explanation': '2x + 5 = 13, so 2x = 8, therefore x = 4.',
      },
      {
        'id': 'q2',
        'type': 'short_answer',
        'question': 'Solve for x: 3x - 7 = 2x + 5',
        'correctAnswer': 'x = 12',
        'points': 30,
        'explanation': '3x - 7 = 2x + 5, so x = 12.',
      },
      {
        'id': 'q3',
        'type': 'essay',
        'question': 'Explain the difference between linear and quadratic equations. Provide examples of each.',
        'correctAnswer': null,
        'points': 50,
        'explanation': 'Look for clear understanding of both equation types with relevant examples.',
      },
    ],
    'attachments': [
      {
        'id': 'att-123',
        'filename': 'algebra_formulas.pdf',
        'url': 'https://example.com/files/algebra_formulas.pdf',
        'size': 1024000,
        'type': 'pdf',
        'uploadedAt': '2024-01-01T00:00:00Z',
      },
    ],
    'tags': ['algebra', 'equations', 'linear'],
    'isPublic': false,
    'maxAttempts': 3,
    'timeLimit': 180, // minutes
    'randomizeQuestions': false,
    'showResultsImmediately': true,
    'metadata': {
      'courseId': 'math-101',
      'chapter': 'Linear Equations',
      'learningObjectives': [
        'Solve linear equations',
        'Understand algebraic manipulation',
        'Apply equations to real-world problems',
      ],
    },
  };

  static const physicsAssignment = {
    'id': 'assignment-456',
    'title': 'Newton\'s Laws Application',
    'description': 'Apply Newton\'s three laws of motion to solve the following problems.',
    'subject': 'Physics',
    'topic': 'Classical Mechanics',
    'difficulty': 'advanced',
    'estimatedDuration': 150,
    'totalPoints': 150,
    'createdBy': 'tutor-789',
    'createdByName': 'Dr. Robert Johnson',
    'createdAt': '2024-01-02T00:00:00Z',
    'dueDate': '2024-01-10T23:59:59Z',
    'status': 'active',
    'instructions': [
      'Draw force diagrams for each problem',
      'Show all calculation steps',
      'Include units in all answers',
      'Check your answers using dimensional analysis',
    ],
    'questions': [
      {
        'id': 'q1',
        'type': 'problem_solving',
        'question': 'A 5kg object is pushed with a force of 20N. If friction is negligible, what is the acceleration?',
        'correctAnswer': '4 m/s²',
        'points': 50,
        'explanation': 'Using F = ma, a = F/m = 20N/5kg = 4 m/s²',
        'solutionSteps': [
          'Identify known values: F = 20N, m = 5kg',
          'Apply Newton\'s Second Law: F = ma',
          'Solve for acceleration: a = F/m',
          'Calculate: a = 20/5 = 4 m/s²',
        ],
      },
    ],
    'attachments': [],
    'tags': ['physics', 'newton', 'force', 'acceleration'],
    'isPublic': true,
    'maxAttempts': 2,
    'timeLimit': 120,
    'randomizeQuestions': true,
    'showResultsImmediately': false,
  };

  static const chemistryAssignment = {
    'id': 'assignment-789',
    'title': 'Organic Chemistry Reactions',
    'description': 'Identify the products of the following organic reactions.',
    'subject': 'Chemistry',
    'topic': 'Organic Chemistry',
    'difficulty': 'beginner',
    'estimatedDuration': 60,
    'totalPoints': 80,
    'createdBy': 'tutor-101',
    'createdByName': 'Dr. Sarah Wilson',
    'createdAt': '2024-01-03T00:00:00Z',
    'dueDate': '2024-01-12T23:59:59Z',
    'status': 'draft',
    'questions': [],
    'attachments': [],
    'tags': ['chemistry', 'organic', 'reactions'],
    'isPublic': false,
    'maxAttempts': 1,
    'timeLimit': 90,
    'randomizeQuestions': false,
    'showResultsImmediately': true,
  };

  // Test submissions
  static const completedSubmission = {
    'id': 'submission-123',
    'assignmentId': 'assignment-123',
    'studentId': 'student-123',
    'studentName': 'John Doe',
    'submittedAt': '2024-01-05T14:30:00Z',
    'status': 'submitted',
    'score': 85,
    'totalPoints': 100,
    'percentage': 85.0,
    'timeSpent': 95, // minutes
    'attemptNumber': 1,
    'answers': [
      {
        'questionId': 'q1',
        'answer': 'b',
        'isCorrect': true,
        'pointsEarned': 20,
        'timeSpent': 5,
      },
      {
        'questionId': 'q2',
        'answer': 'x = 12',
        'isCorrect': true,
        'pointsEarned': 30,
        'timeSpent': 10,
      },
      {
        'questionId': 'q3',
        'answer': 'Linear equations are first-degree polynomial equations...',
        'isCorrect': null, // Manual grading required
        'pointsEarned': 35, // Partial credit
        'timeSpent': 80,
      },
    ],
    'feedback': {
      'overall': 'Good work! You showed clear understanding of linear equations.',
      'strengths': [
        'Accurate calculation methods',
        'Clear work shown',
        'Correct application of concepts',
      ],
      'areasForImprovement': [
        'Essay response could be more detailed',
        'Consider including real-world applications',
      ],
    },
    'attachments': [
      {
        'id': 'sub-att-123',
        'filename': 'work_sheet.pdf',
        'url': 'https://example.com/files/student_work.pdf',
        'size': 2048000,
        'type': 'pdf',
      },
    ],
    'gradedBy': 'tutor-456',
    'gradedByName': 'Jane Smith',
    'gradedAt': '2024-01-06T10:00:00Z',
    'plagiarismCheck': {
      'score': 15, // 15% similarity
      'status': 'clear',
      'reportUrl': 'https://example.com/reports/plagiarism-123.pdf',
    },
  };

  static const inProgressSubmission = {
    'id': 'submission-124',
    'assignmentId': 'assignment-123',
    'studentId': 'student-456',
    'studentName': 'Alice Smith',
    'startedAt': '2024-01-05T15:00:00Z',
    'status': 'in_progress',
    'answers': [
      {
        'questionId': 'q1',
        'answer': 'a',
        'isCorrect': null, // Not answered yet
        'pointsEarned': 0,
        'timeSpent': 3,
      },
    ],
    'currentQuestionIndex': 1,
    'timeSpent': 25,
    'attemptsRemaining': 2,
  };

  static const overdueSubmission = {
    'id': 'submission-125',
    'assignmentId': 'assignment-123',
    'studentId': 'student-789',
    'studentName': 'Bob Johnson',
    'submittedAt': '2024-01-09T14:00:00Z', // After due date
    'status': 'submitted_late',
    'score': 78,
    'totalPoints': 100,
    'percentage': 78.0,
    'lateSubmissionPenalty': 0.1, // 10% penalty
    'adjustedScore': 70.2,
    'answers': [],
    'feedback': {
      'overall': 'Submitted after deadline with 10% penalty applied.',
    },
  };

  // Test assignment responses
  static const successfulAssignmentCreateResponse = {
    'success': true,
    'data': {
      'assignment': mathematicsAssignment,
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const successfulAssignmentListResponse = {
    'success': true,
    'data': {
      'assignments': [
        mathematicsAssignment,
        physicsAssignment,
        chemistryAssignment,
      ],
      'totalCount': 3,
      'hasMore': false,
      'currentPage': 1,
      'totalPages': 1,
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const successfulSubmissionCreateResponse = {
    'success': true,
    'data': {
      'submission': inProgressSubmission,
    },
    'timestamp': '2024-01-05T15:00:00Z',
  };

  static const successfulSubmissionListResponse = {
    'success': true,
    'data': {
      'submissions': [
        completedSubmission,
        inProgressSubmission,
        overdueSubmission,
      ],
      'totalCount': 3,
      'hasMore': false,
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const successfulSubmissionUpdateResponse = {
    'success': true,
    'data': {
      'submission': completedSubmission,
      'message': 'Submission updated successfully',
    },
    'timestamp': '2024-01-05T14:30:00Z',
  };

  static const assignmentNotFoundResponse = {
    'success': false,
    'error': {
      'code': 'ASSIGNMENT_NOT_FOUND',
      'message': 'Assignment not found',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const submissionNotFoundResponse = {
    'success': false,
    'error': {
      'code': 'SUBMISSION_NOT_FOUND',
      'message': 'Submission not found',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const accessDeniedResponse = {
    'success': false,
    'error': {
      'code': 'ACCESS_DENIED',
      'message': 'Access denied to this assignment',
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const submissionExpiredResponse = {
    'success': false,
    'error': {
      'code': 'SUBMISSION_EXPIRED',
      'message': 'Submission time has expired',
      'details': {
        'timeLimit': 180,
        'timeSpent': 185,
      },
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  static const maxAttemptsExceededResponse = {
    'success': false,
    'error': {
      'code': 'MAX_ATTEMPTS_EXCEEDED',
      'message': 'Maximum number of attempts exceeded',
      'details': {
        'maxAttempts': 3,
        'currentAttempt': 3,
      },
    },
    'timestamp': '2024-01-01T00:00:00Z',
  };

  // Grade analytics
  static const assignmentAnalytics = {
    'success': true,
    'data': {
      'assignment': mathematicsAssignment,
      'statistics': {
        'totalSubmissions': 25,
        'completedSubmissions': 20,
        'averageScore': 78.5,
        'medianScore': 82.0,
        'highestScore': 98.0,
        'lowestScore': 45.0,
        'passRate': 0.85,
        'averageTimeSpent': 105,
        'completionRate': 0.8,
      },
      'scoreDistribution': [
        {'range': '0-20', 'count': 1},
        {'range': '21-40', 'count': 2},
        {'range': '41-60', 'count': 3},
        {'range': '61-80', 'count': 8},
        {'range': '81-100', 'count': 11},
      ],
      'questionAnalytics': [
        {
          'questionId': 'q1',
          'question': 'What is the solution to 2x + 5 = 13?',
          'correctAnswers': 18,
          'incorrectAnswers': 2,
          'averageTime': 5.2,
          'difficultyLevel': 0.9,
        },
        {
          'questionId': 'q2',
          'question': 'Solve for x: 3x - 7 = 2x + 5',
          'correctAnswers': 15,
          'incorrectAnswers': 5,
          'averageTime': 12.8,
          'difficultyLevel': 0.75,
        },
      ],
      'recentSubmissions': [completedSubmission, inProgressSubmission],
    },
    'timestamp': '2024-01-06T12:00:00Z',
  };

  // File upload responses
  static const successfulFileUploadResponse = {
    'success': true,
    'data': {
      'fileId': 'file-123',
      'filename': 'assignment_attachment.pdf',
      'url': 'https://example.com/files/assignment_attachment.pdf',
      'size': 1024000,
      'type': 'pdf',
      'uploadedAt': DateTime.now().toIso8601String(),
    },
    'timestamp': DateTime.now().toIso8601String(),
  };

  static const failedFileUploadResponse = {
    'success': false,
    'error': {
      'code': 'FILE_UPLOAD_FAILED',
      'message': 'File upload failed',
      'details': {
        'reason': 'FILE_TOO_LARGE',
        'maxSize': AssignmentTestConfig.maxAttachmentSizeMB * 1024 * 1024,
        'actualSize': 20 * 1024 * 1024, // 20MB
      },
    },
    'timestamp': DateTime.now().toIso8601String(),
  };

  // Helper methods
  static Map<String, dynamic> createAssignment({
    String? id,
    String? title,
    String? subject,
    String? difficulty,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'assignment-${DateTime.now().millisecondsSinceEpoch}',
      'title': title ?? 'Test Assignment',
      'description': 'This is a test assignment description.',
      'subject': subject ?? 'Mathematics',
      'topic': 'General',
      'difficulty': difficulty ?? 'beginner',
      'estimatedDuration': 60,
      'totalPoints': 100,
      'createdBy': 'tutor-456',
      'createdAt': DateTime.now().toIso8601String(),
      'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'status': 'active',
      'questions': [],
      'attachments': [],
      'tags': [],
      'isPublic': false,
      'maxAttempts': 3,
      'timeLimit': 120,
      'randomizeQuestions': false,
      'showResultsImmediately': true,
      ...?metadata,
    };
  }

  static Map<String, dynamic> createSubmission({
    String? id,
    String? assignmentId,
    String? studentId,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'submission-${DateTime.now().millisecondsSinceEpoch}',
      'assignmentId': assignmentId ?? 'assignment-123',
      'studentId': studentId ?? 'student-123',
      'startedAt': DateTime.now().toIso8601String(),
      'status': status ?? 'in_progress',
      'answers': [],
      'timeSpent': 0,
      'attemptNumber': 1,
      'attemptsRemaining': 2,
      ...?metadata,
    };
  }

  static Map<String, dynamic> createAssignmentResponse({
    bool success = true,
    Map<String, dynamic>? data,
    String? errorCode,
    String? errorMessage,
  }) {
    if (success) {
      return {
        'success': true,
        'data': data ?? mathematicsAssignment,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      return {
        'success': false,
        'error': {
          'code': errorCode ?? 'ASSIGNMENT_ERROR',
          'message': errorMessage ?? 'Assignment operation failed',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static bool isValidAssignmentStatus(String status) {
    const validStatuses = ['draft', 'active', 'completed', 'archived', 'deleted'];
    return validStatuses.contains(status);
  }

  static bool isValidSubmissionStatus(String status) {
    const validStatuses = ['not_started', 'in_progress', 'submitted', 'graded', 'overdue'];
    return validStatuses.contains(status);
  }

  static bool isValidDifficultyLevel(String difficulty) {
    const validDifficulties = ['beginner', 'intermediate', 'advanced', 'expert'];
    return validDifficulties.contains(difficulty);
  }

  static bool isValidQuestionType(String type) {
    const validTypes = [
      'multiple_choice',
      'true_false',
      'short_answer',
      'essay',
      'problem_solving',
      'file_upload',
      'code_editor',
    ];
    return validTypes.contains(type);
  }

  static bool isValidScore(double score) {
    return score >= 0 && score <= 100;
  }

  static bool isValidTimeSpent(int timeSpent) {
    return timeSpent >= 0 && timeSpent <= 1440; // Max 24 hours
  }
}