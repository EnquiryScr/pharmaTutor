import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/repositories/irepository.dart';
import '../models/course_model.dart';
import '../datasources/remote/course_supabase_data_source.dart';
import '../datasources/local/course_cache_data_source.dart';

/// Course repository implementing offline-first pattern with Supabase and SQLite cache
class CourseRepositoryImpl implements IOfflineFirstRepository<CourseModel> {
  final CourseSupabaseDataSource _remoteDataSource;
  final CourseCacheDataSource _cacheDataSource;
  final Connectivity _connectivity;

  CourseRepositoryImpl({
    required CourseSupabaseDataSource remoteDataSource,
    required CourseCacheDataSource cacheDataSource,
    Connectivity? connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _cacheDataSource = cacheDataSource,
        _connectivity = connectivity ?? Connectivity();

  @override
  String get repositoryName => 'CourseRepository';

  /// Check if device has internet connection
  Future<bool> get _isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get course by ID with cache-first approach
  @override
  Future<Either<Failure, CourseModel>> getById(String id) async {
    try {
      // Try to get from cache first
      final cachedCourse = await _cacheDataSource.getCourse(id);
      
      if (cachedCourse != null) {
        final courseModel = CourseModel.fromJson(cachedCourse);
        
        // Update from remote in background if online
        if (await _isOnline) {
          _updateCacheInBackground(id);
        }
        
        return Right(courseModel);
      }

      // If not in cache, fetch from remote
      if (await _isOnline) {
        final remoteCourse = await _remoteDataSource.getCourse(id);
        
        // Cache the result
        await _cacheDataSource.insertCourse(remoteCourse);
        
        return Right(CourseModel.fromJson(remoteCourse));
      } else {
        return Left(Failure(
          message: 'Course not found in cache and device is offline',
          code: 'OFFLINE_NO_CACHE',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get course: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateCacheInBackground(String courseId) async {
    try {
      final remoteCourse = await _remoteDataSource.getCourse(courseId);
      await _cacheDataSource.updateCourse(courseId, remoteCourse);
    } catch (e) {
      // Silent fail
    }
  }

  /// Create new course
  @override
  Future<Either<Failure, CourseModel>> create(CourseModel entity) async {
    try {
      if (await _isOnline) {
        final courseData = entity.toJson();
        final createdCourse = await _remoteDataSource.createCourse(courseData);
        
        // Cache the new course
        await _cacheDataSource.insertCourse(createdCourse);
        
        return Right(CourseModel.fromJson(createdCourse));
      } else {
        return Left(Failure(
          message: 'Cannot create course while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to create course: $e',
        exception: e,
      ));
    }
  }

  /// Update course
  @override
  Future<Either<Failure, CourseModel>> update(String id, CourseModel entity) async {
    try {
      final updateData = entity.toJson();
      
      if (await _isOnline) {
        final updatedCourse = await _remoteDataSource.updateCourse(id, updateData);
        
        // Update cache
        await _cacheDataSource.updateCourse(id, updatedCourse);
        
        return Right(CourseModel.fromJson(updatedCourse));
      } else {
        // Update cache only when offline
        await _cacheDataSource.updateCourse(id, updateData);
        
        // TODO: Queue for sync when online
        
        return Right(entity);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to update course: $e',
        exception: e,
      ));
    }
  }

  /// Delete course
  @override
  Future<Either<Failure, bool>> delete(String id) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.deleteCourse(id);
        
        // Remove from cache
        await _cacheDataSource.deleteCourse(id);
        
        return const Right(true);
      } else {
        return Left(Failure(
          message: 'Cannot delete course while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to delete course: $e',
        exception: e,
      ));
    }
  }

  /// Search courses
  @override
  Future<Either<Failure, List<CourseModel>>> search(String query) async {
    try {
      // Try cache first
      final cachedCourses = await _cacheDataSource.searchCourses(query);
      
      if (cachedCourses.isNotEmpty) {
        final courseModels = cachedCourses
            .map((data) => CourseModel.fromJson(data))
            .toList();
        
        // Update from remote in background if online
        if (await _isOnline) {
          _updateSearchCacheInBackground(query);
        }
        
        return Right(courseModels);
      }

      // Fetch from remote if cache is empty
      if (await _isOnline) {
        final remoteCourses = await _remoteDataSource.searchCourses(query);
        
        // Cache the results
        for (final course in remoteCourses) {
          await _cacheDataSource.insertCourse(course);
        }
        
        return Right(remoteCourses.map((data) => CourseModel.fromJson(data)).toList());
      } else {
        return Left(Failure(
          message: 'No courses found in cache and device is offline',
          code: 'OFFLINE_NO_CACHE',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to search courses: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateSearchCacheInBackground(String query) async {
    try {
      final remoteCourses = await _remoteDataSource.searchCourses(query);
      for (final course in remoteCourses) {
        await _cacheDataSource.updateCourse(course['course_id'], course);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get courses by tutor
  Future<Either<Failure, List<CourseModel>>> getCoursesByTutor(String tutorId) async {
    try {
      final cachedCourses = await _cacheDataSource.getCoursesByTutor(tutorId);
      
      if (cachedCourses.isNotEmpty) {
        final courseModels = cachedCourses
            .map((data) => CourseModel.fromJson(data))
            .toList();
        
        if (await _isOnline) {
          _updateTutorCoursesInBackground(tutorId);
        }
        
        return Right(courseModels);
      }

      if (await _isOnline) {
        final remoteCourses = await _remoteDataSource.getCoursesByTutor(tutorId);
        
        for (final course in remoteCourses) {
          await _cacheDataSource.insertCourse(course);
        }
        
        return Right(remoteCourses.map((data) => CourseModel.fromJson(data)).toList());
      } else {
        return Right([]); // Return empty list if offline and no cache
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get tutor courses: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateTutorCoursesInBackground(String tutorId) async {
    try {
      final remoteCourses = await _remoteDataSource.getCoursesByTutor(tutorId);
      for (final course in remoteCourses) {
        await _cacheDataSource.updateCourse(course['course_id'], course);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get enrolled courses for a student
  Future<Either<Failure, List<CourseModel>>> getEnrolledCourses(String studentId) async {
    try {
      final cachedCourses = await _cacheDataSource.getEnrolledCourses(studentId);
      
      if (cachedCourses.isNotEmpty) {
        final courseModels = cachedCourses
            .map((data) => CourseModel.fromJson(data))
            .toList();
        
        if (await _isOnline) {
          _updateEnrolledCoursesInBackground(studentId);
        }
        
        return Right(courseModels);
      }

      if (await _isOnline) {
        final remoteCourses = await _remoteDataSource.getEnrolledCourses(studentId);
        
        for (final course in remoteCourses) {
          await _cacheDataSource.insertCourse(course);
        }
        
        return Right(remoteCourses.map((data) => CourseModel.fromJson(data)).toList());
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get enrolled courses: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateEnrolledCoursesInBackground(String studentId) async {
    try {
      final remoteCourses = await _remoteDataSource.getEnrolledCourses(studentId);
      for (final course in remoteCourses) {
        await _cacheDataSource.updateCourse(course['course_id'], course);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Enroll student in course
  Future<Either<Failure, Map<String, dynamic>>> enrollStudent({
    required String studentId,
    required String courseId,
  }) async {
    try {
      if (await _isOnline) {
        final enrollment = await _remoteDataSource.enrollStudent(
          studentId: studentId,
          courseId: courseId,
        );
        
        // Cache the enrollment
        await _cacheDataSource.insertEnrollment(enrollment);
        
        return Right(enrollment);
      } else {
        return Left(Failure(
          message: 'Cannot enroll while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to enroll student: $e',
        exception: e,
      ));
    }
  }

  /// Update course progress
  Future<Either<Failure, void>> updateProgress({
    required String enrollmentId,
    required String contentId,
    required int progressPercentage,
    bool completed = false,
  }) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.updateCourseProgress(
          enrollmentId: enrollmentId,
          contentId: contentId,
          progressPercentage: progressPercentage,
          completed: completed,
        );
        
        // Update cache
        await _cacheDataSource.insertCourseProgress({
          'enrollment_id': enrollmentId,
          'content_id': contentId,
          'progress_percentage': progressPercentage,
          'completed': completed,
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        return const Right(null);
      } else {
        // Update cache only
        await _cacheDataSource.insertCourseProgress({
          'enrollment_id': enrollmentId,
          'content_id': contentId,
          'progress_percentage': progressPercentage,
          'completed': completed,
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        // TODO: Queue for sync when online
        
        return const Right(null);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to update progress: $e',
        exception: e,
      ));
    }
  }

  // Offline-first interface implementation
  
  @override
  Future<Either<Failure, SyncResult<CourseModel>>> syncData() async {
    try {
      if (!await _isOnline) {
        return Left(Failure(
          message: 'Cannot sync while offline',
          code: 'OFFLINE',
        ));
      }

      final cachedCourses = await _cacheDataSource.getAllCourses();
      final syncedItems = <CourseModel>[];
      final failedItems = <String>[];

      for (final cached in cachedCourses) {
        try {
          final courseId = cached['course_id'] as String;
          final remoteCourse = await _remoteDataSource.getCourse(courseId);
          
          await _cacheDataSource.updateCourse(courseId, remoteCourse);
          syncedItems.add(CourseModel.fromJson(remoteCourse));
        } catch (e) {
          failedItems.add(cached['course_id'] as String);
        }
      }

      return Right(SyncResult(
        syncedItems: syncedItems,
        failedItems: failedItems,
        totalSynced: syncedItems.length,
        totalFailed: failedItems.length,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'Sync failed: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<CourseModel>>> getOfflineData() async {
    try {
      final cachedCourses = await _cacheDataSource.getAllCourses();
      final courseModels = cachedCourses
          .map((data) => CourseModel.fromJson(data))
          .toList();
      
      return Right(courseModels);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveOfflineData(List<CourseModel> data) async {
    try {
      for (final course in data) {
        await _cacheDataSource.insertCourse(course.toJson());
      }
      
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to save offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isDataSynced() async {
    try {
      final cachedCourses = await _cacheDataSource.getAllCourses();
      return Right(cachedCourses.isNotEmpty);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check sync status: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<CourseModel>>> getAll({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final offset = page != null && limit != null ? (page - 1) * limit : 0;
      final cachedCourses = await _cacheDataSource.getAllCourses(
        limit: limit,
        offset: offset,
      );
      
      final courseModels = cachedCourses
          .map((data) => CourseModel.fromJson(data))
          .toList();
      
      return Right(courseModels);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get all courses: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> exists(String id) async {
    try {
      final course = await _cacheDataSource.getCourse(id);
      return Right(course != null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check if course exists: $e',
        exception: e,
      ));
    }
  }
}
