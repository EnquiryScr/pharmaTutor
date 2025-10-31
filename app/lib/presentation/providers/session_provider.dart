import 'package:flutter/foundation.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../../data/models/session_model.dart';
import '../../data/models/session_feedback_model.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/failure.dart';

/// Provider for tutoring session management
/// Uses SessionRepositoryImpl with cache-first pattern
class SessionProvider extends ChangeNotifier {
  final SupabaseDependencies _dependencies = SupabaseDependencies();

  List<SessionModel> _sessions = [];
  SessionModel? _currentSession;
  List<SessionFeedbackModel> _feedback = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SessionModel> get sessions => _sessions;
  SessionModel? get currentSession => _currentSession;
  List<SessionFeedbackModel> get feedback => _feedback;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load sessions for tutor
  Future<void> loadTutorSessions(
    String tutorId, {
    String? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.getTutorSessions(
        tutorId,
        status: status,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (sessions) {
          _sessions = sessions;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load sessions for student
  Future<void> loadStudentSessions(
    String studentId, {
    String? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.getStudentSessions(
        studentId,
        status: status,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (sessions) {
          _sessions = sessions;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load upcoming sessions for user
  Future<void> loadUpcomingSessions(
    String userId,
    String role, {
    int limit = 10,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.getUpcomingSessions(
        userId,
        role,
        limit: limit,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (sessions) {
          _sessions = sessions;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load past sessions for user
  Future<void> loadPastSessions(
    String userId,
    String role, {
    int limit = 20,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.getPastSessions(
        userId,
        role,
        limit: limit,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (sessions) {
          _sessions = sessions;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get session details
  Future<void> loadSessionDetails(String sessionId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.getSession(sessionId);

      result.fold(
        (failure) => _setError(failure.message),
        (session) {
          _currentSession = session;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Schedule new session
  Future<bool> scheduleSession(Map<String, dynamic> sessionData) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.scheduleSession(sessionData);

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (session) {
          _sessions.insert(0, session);
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Update session status
  Future<bool> updateSessionStatus(
    String sessionId,
    String status,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.updateSessionStatus(
        sessionId,
        status,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (session) {
          // Update in list
          final index = _sessions.indexWhere((s) => s.sessionId == sessionId);
          if (index != -1) {
            _sessions[index] = session;
          }
          if (_currentSession?.sessionId == sessionId) {
            _currentSession = session;
          }
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Accept session (tutor)
  Future<bool> acceptSession(String sessionId) async {
    return updateSessionStatus(sessionId, 'scheduled');
  }

  /// Decline session (tutor)
  Future<bool> declineSession(String sessionId) async {
    return updateSessionStatus(sessionId, 'cancelled');
  }

  /// Complete session
  Future<bool> completeSession(String sessionId) async {
    return updateSessionStatus(sessionId, 'completed');
  }

  /// Cancel session
  Future<bool> cancelSession(String sessionId) async {
    return updateSessionStatus(sessionId, 'cancelled');
  }

  /// Submit session feedback
  Future<bool> submitFeedback(Map<String, dynamic> feedbackData) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.submitFeedback(feedbackData);

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (feedback) {
          _feedback.add(feedback);
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Get session feedback
  Future<void> loadSessionFeedback(String sessionId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.sessionRepository.getSessionFeedback(sessionId);

      result.fold(
        (failure) => _setError(failure.message),
        (feedbackList) {
          _feedback = feedbackList;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Filter sessions by date range
  List<SessionModel> getSessionsByDateRange(DateTime start, DateTime end) {
    return _sessions.where((session) {
      final scheduledTime = session.scheduledAt;
      return scheduledTime.isAfter(start) && scheduledTime.isBefore(end);
    }).toList();
  }

  /// Filter sessions by status
  List<SessionModel> getSessionsByStatus(String status) {
    return _sessions.where((session) => session.status == status).toList();
  }

  /// Get pending sessions
  List<SessionModel> get pendingSessions => getSessionsByStatus('pending');

  /// Get scheduled sessions
  List<SessionModel> get scheduledSessions => getSessionsByStatus('scheduled');

  /// Get completed sessions
  List<SessionModel> get completedSessions => getSessionsByStatus('completed');

  /// Get cancelled sessions
  List<SessionModel> get cancelledSessions => getSessionsByStatus('cancelled');

  /// Refresh sessions
  Future<void> refreshSessions(String userId, String role) async {
    await loadUpcomingSessions(userId, role);
  }

  /// Clear all data
  void clear() {
    _sessions = [];
    _currentSession = null;
    _feedback = [];
    _errorMessage = null;
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
