import 'package:flutter/foundation.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../../data/models/course_model.dart';
import '../../data/models/course_content_model.dart';
import '../../data/models/enrollment_model.dart';
import '../../data/models/course_progress_model.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/failure.dart';

/// Provider for course management
/// Uses CourseRepositoryImpl with cache-first pattern
class CourseProvider extends ChangeNotifier {
  final SupabaseDependencies _dependencies = SupabaseDependencies();

  List<CourseModel> _courses = [];
  CourseModel? _currentCourse;
  List<CourseContentModel> _courseContent = [];
  List<EnrollmentModel> _enrollments = [];
  List<CourseProgressModel> _progress = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // Getters
  List<CourseModel> get courses => _courses;
  CourseModel? get currentCourse => _currentCourse;
  List<CourseContentModel> get courseContent => _courseContent;
  List<EnrollmentModel> get enrollments => _enrollments;
  List<CourseProgressModel> get progress => _progress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  /// Load courses with pagination
  Future<void> loadCourses({
    String? search,
    String? tutorId,
    String? subject,
    bool loadMore = false,
  }) async {
    if (_isLoading) return;
    if (loadMore && !_hasMore) return;

    _setLoading(true);
    _clearError();

    if (!loadMore) {
      _currentPage = 0;
      _courses = [];
      _hasMore = true;
    }

    try {
      final result = await _dependencies.courseRepository.searchCourses(
        query: search,
        tutorId: tutorId,
        subject: subject,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      result.fold(
        (failure) => _setError(failure.message),
        (newCourses) {
          if (newCourses.length < _pageSize) {
            _hasMore = false;
          }
          _courses.addAll(newCourses);
          _currentPage++;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get course details
  Future<void> loadCourseDetails(String courseId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.getCourse(courseId);
      
      result.fold(
        (failure) => _setError(failure.message),
        (course) {
          _currentCourse = course;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get course content/lessons
  Future<void> loadCourseContent(String courseId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.getCourseContent(courseId);
      
      result.fold(
        (failure) => _setError(failure.message),
        (content) {
          _courseContent = content;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Enroll in course
  Future<bool> enrollInCourse(String courseId, String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.enrollInCourse(
        courseId,
        studentId,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (enrollment) {
          _enrollments.add(enrollment);
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Get student enrollments
  Future<void> loadStudentEnrollments(String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.getStudentEnrollments(studentId);
      
      result.fold(
        (failure) => _setError(failure.message),
        (enrollments) {
          _enrollments = enrollments;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get course progress
  Future<void> loadCourseProgress(String enrollmentId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.getCourseProgress(enrollmentId);
      
      result.fold(
        (failure) => _setError(failure.message),
        (progress) {
          _progress = progress;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Update progress (mark content as completed)
  Future<bool> updateProgress(
    String progressId,
    Map<String, dynamic> updates,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.updateProgress(
        progressId,
        updates,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (updatedProgress) {
          // Update in list
          final index = _progress.indexWhere((p) => p.progressId == progressId);
          if (index != -1) {
            _progress[index] = updatedProgress;
            notifyListeners();
          }
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Create new course (tutor only)
  Future<bool> createCourse(Map<String, dynamic> courseData) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.createCourse(courseData);

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (course) {
          _courses.insert(0, course);
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Update course (tutor only)
  Future<bool> updateCourse(String courseId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.updateCourse(courseId, updates);

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (course) {
          // Update in list
          final index = _courses.indexWhere((c) => c.courseId == courseId);
          if (index != -1) {
            _courses[index] = course;
          }
          if (_currentCourse?.courseId == courseId) {
            _currentCourse = course;
          }
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Upload course material
  Future<String?> uploadMaterial(
    String courseId,
    List<int> fileBytes,
    String fileName,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.courseRepository.uploadCourseMaterial(
        courseId,
        fileBytes,
        fileName,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return null;
        },
        (url) => url,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh courses (force update from Supabase)
  Future<void> refreshCourses() async {
    _currentPage = 0;
    _courses = [];
    _hasMore = true;
    await loadCourses();
  }

  /// Clear all data
  void clear() {
    _courses = [];
    _currentCourse = null;
    _courseContent = [];
    _enrollments = [];
    _progress = [];
    _errorMessage = null;
    _hasMore = true;
    _currentPage = 0;
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
