import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../../data/models/course_model.dart';
import '../../data/models/course_content_model.dart';
import '../../data/models/enrollment_model.dart';
import '../../data/models/course_progress_model.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/failure.dart';

/// Course state for Riverpod
class CourseState {
  final List<CourseModel> courses;
  final CourseModel? currentCourse;
  final List<CourseContentModel> courseContent;
  final List<EnrollmentModel> enrollments;
  final List<CourseProgressModel> progress;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;

  const CourseState({
    this.courses = const [],
    this.currentCourse,
    this.courseContent = const [],
    this.enrollments = const [],
    this.progress = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasMore = true,
  });

  CourseState copyWith({
    List<CourseModel>? courses,
    CourseModel? currentCourse,
    List<CourseContentModel>? courseContent,
    List<EnrollmentModel>? enrollments,
    List<CourseProgressModel>? progress,
    bool? isLoading,
    String? errorMessage,
    bool? hasMore,
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      currentCourse: currentCourse ?? this.currentCourse,
      courseContent: courseContent ?? this.courseContent,
      enrollments: enrollments ?? this.enrollments,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Course state notifier for Riverpod
class CourseNotifier extends StateNotifier<CourseState> {
  CourseNotifier() : super(const CourseState());

  SupabaseDependencies get _dependencies => ProviderBindings().dependencies;

  int _currentPage = 0;
  static const int _pageSize = 20;

  /// Load courses with pagination
  Future<void> loadCourses({
    String? search,
    String? tutorId,
    String? subject,
    bool loadMore = false,
  }) async {
    if (state.isLoading) return;
    if (loadMore && !state.hasMore) return;

    if (!loadMore) {
      _currentPage = 0;
      state = state.copyWith(
        courses: [],
        hasMore: true,
        errorMessage: null,
      );
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.searchCourses(
        query: search,
        tutorId: tutorId,
        subject: subject,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (newCourses) {
          if (newCourses.length < _pageSize) {
            state = state.copyWith(
              courses: [...state.courses, ...newCourses],
              hasMore: false,
              isLoading: false,
            );
          } else {
            state = state.copyWith(
              courses: [...state.courses, ...newCourses],
              isLoading: false,
            );
          }
          _currentPage++;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get course details
  Future<void> loadCourseDetails(String courseId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.getCourse(courseId);
      
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (course) => state = state.copyWith(
          currentCourse: course,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get course content/lessons
  Future<void> loadCourseContent(String courseId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.getCourseContent(courseId);
      
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (content) => state = state.copyWith(
          courseContent: content,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Enroll in course
  Future<bool> enrollInCourse(String courseId, String studentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.enrollInCourse(
        courseId,
        studentId,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (enrollment) {
          state = state.copyWith(
            enrollments: [...state.enrollments, enrollment],
            isLoading: false,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Get student enrollments
  Future<void> loadStudentEnrollments(String studentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.getStudentEnrollments(studentId);
      
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (enrollments) => state = state.copyWith(
          enrollments: enrollments,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get course progress
  Future<void> loadCourseProgress(String enrollmentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.getCourseProgress(enrollmentId);
      
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (progress) => state = state.copyWith(
          progress: progress,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update progress (mark content as completed)
  Future<bool> updateProgress(
    String progressId,
    Map<String, dynamic> updates,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.updateProgress(
        progressId,
        updates,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (updatedProgress) {
          // Update in list
          final index = state.progress.indexWhere((p) => p.progressId == progressId);
          final updatedProgressList = [...state.progress];
          if (index != -1) {
            updatedProgressList[index] = updatedProgress;
          }
          state = state.copyWith(
            progress: updatedProgressList,
            isLoading: false,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Create new course (tutor only)
  Future<bool> createCourse(Map<String, dynamic> courseData) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.createCourse(courseData);

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (course) {
          state = state.copyWith(
            courses: [course, ...state.courses],
            isLoading: false,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Update course (tutor only)
  Future<bool> updateCourse(String courseId, Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.updateCourse(courseId, updates);

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (course) {
          // Update in list
          final index = state.courses.indexWhere((c) => c.courseId == courseId);
          final updatedCourses = [...state.courses];
          if (index != -1) {
            updatedCourses[index] = course;
          }
          
          final updatedCurrentCourse = state.currentCourse?.courseId == courseId 
            ? course 
            : state.currentCourse;

          state = state.copyWith(
            courses: updatedCourses,
            currentCourse: updatedCurrentCourse,
            isLoading: false,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Upload course material
  Future<String?> uploadMaterial(
    String courseId,
    List<int> fileBytes,
    String fileName,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _dependencies.courseRepository.uploadCourseMaterial(
        courseId,
        fileBytes,
        fileName,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          return null;
        },
        (url) {
          state = state.copyWith(isLoading: false);
          return url;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Refresh courses (force update from Supabase)
  Future<void> refreshCourses() async {
    _currentPage = 0;
    state = state.copyWith(
      courses: [],
      hasMore: true,
      errorMessage: null,
    );
    await loadCourses();
  }

  /// Clear all data
  void clear() {
    _currentPage = 0;
    state = const CourseState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Course provider for Riverpod
final courseProvider = StateNotifierProvider<CourseNotifier, CourseState>(
  (ref) => CourseNotifier(),
);
