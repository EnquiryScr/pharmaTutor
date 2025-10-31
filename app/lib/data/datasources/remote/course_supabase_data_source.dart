import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/course_model.dart';

/// Supabase data source for course-related operations
class CourseSupabaseDataSource {
  final SupabaseClient _supabase;

  CourseSupabaseDataSource(this._supabase);

  // Create a new course
  Future<CourseModel> createCourse({
    required String title,
    required String description,
    required String tutorId,
    required String subject,
    required String level,
    double? price,
    int? durationHours,
    String? thumbnailUrl,
  }) async {
    try {
      final response = await _supabase
          .from('courses')
          .insert({
            'title': title,
            'description': description,
            'tutor_id': tutorId,
            'subject': subject,
            'level': level,
            'price': price,
            'duration_hours': durationHours,
            'thumbnail_url': thumbnailUrl,
          })
          .select()
          .single();

      return CourseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  // Get course by ID
  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final response = await _supabase
          .from('courses')
          .select('''
            *,
            tutor:profiles!courses_tutor_id_fkey(id, full_name, avatar_url, rating)
          ''')
          .eq('id', courseId)
          .single();

      return CourseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get course: $e');
    }
  }

  // Get all courses with optional filtering
  Future<List<CourseModel>> getCourses({
    String? tutorId,
    String? subject,
    String? level,
    double? maxPrice,
    double? minRating,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('courses')
          .select('''
            *,
            tutor:profiles!courses_tutor_id_fkey(id, full_name, avatar_url, rating)
          ''');

      if (tutorId != null) {
        queryBuilder = queryBuilder.eq('tutor_id', tutorId);
      }

      if (subject != null) {
        queryBuilder = queryBuilder.eq('subject', subject);
      }

      if (level != null) {
        queryBuilder = queryBuilder.eq('level', level);
      }

      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', maxPrice);
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  // Search courses by title or description
  Future<List<CourseModel>> searchCourses({
    required String query,
    String? subject,
    String? level,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('courses')
          .select('''
            *,
            tutor:profiles!courses_tutor_id_fkey(id, full_name, avatar_url, rating)
          ''')
          .or('title.ilike.%$query%,description.ilike.%$query%');

      if (subject != null) {
        queryBuilder = queryBuilder.eq('subject', subject);
      }

      if (level != null) {
        queryBuilder = queryBuilder.eq('level', level);
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search courses: $e');
    }
  }

  // Update course
  Future<CourseModel> updateCourse({
    required String courseId,
    String? title,
    String? description,
    String? subject,
    String? level,
    double? price,
    int? durationHours,
    String? thumbnailUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (subject != null) updates['subject'] = subject;
      if (level != null) updates['level'] = level;
      if (price != null) updates['price'] = price;
      if (durationHours != null) updates['duration_hours'] = durationHours;
      if (thumbnailUrl != null) updates['thumbnail_url'] = thumbnailUrl;

      final response = await _supabase
          .from('courses')
          .update(updates)
          .eq('id', courseId)
          .select()
          .single();

      return CourseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  // Delete course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase
          .from('courses')
          .delete()
          .eq('id', courseId);
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // Get course content (lessons)
  Future<List<Map<String, dynamic>>> getCourseContent(String courseId) async {
    try {
      final response = await _supabase
          .from('course_content')
          .select()
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get course content: $e');
    }
  }

  // Add course content (lesson)
  Future<Map<String, dynamic>> addCourseContent({
    required String courseId,
    required String title,
    required String contentType,
    String? contentUrl,
    String? description,
    int? durationMinutes,
    int? orderIndex,
  }) async {
    try {
      final response = await _supabase
          .from('course_content')
          .insert({
            'course_id': courseId,
            'title': title,
            'content_type': contentType,
            'content_url': contentUrl,
            'description': description,
            'duration_minutes': durationMinutes,
            'order_index': orderIndex,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add course content: $e');
    }
  }

  // Update course content
  Future<Map<String, dynamic>> updateCourseContent({
    required String contentId,
    String? title,
    String? contentType,
    String? contentUrl,
    String? description,
    int? durationMinutes,
    int? orderIndex,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (contentType != null) updates['content_type'] = contentType;
      if (contentUrl != null) updates['content_url'] = contentUrl;
      if (description != null) updates['description'] = description;
      if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
      if (orderIndex != null) updates['order_index'] = orderIndex;

      final response = await _supabase
          .from('course_content')
          .update(updates)
          .eq('id', contentId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update course content: $e');
    }
  }

  // Delete course content
  Future<void> deleteCourseContent(String contentId) async {
    try {
      await _supabase
          .from('course_content')
          .delete()
          .eq('id', contentId);
    } catch (e) {
      throw Exception('Failed to delete course content: $e');
    }
  }

  // Upload course material to storage
  Future<String> uploadCourseMaterial({
    required String courseId,
    required File file,
    required String contentType,
  }) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '$courseId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$courseId/$fileName';

      // Upload to course-materials bucket
      await _supabase.storage
          .from('course-materials')
          .upload(filePath, file);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('course-materials')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload course material: $e');
    }
  }

  // Delete course material from storage
  Future<void> deleteCourseMaterial(String materialUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(materialUrl);
      final filePath = uri.pathSegments.skip(5).join('/');

      // Delete from storage
      await _supabase.storage
          .from('course-materials')
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete course material: $e');
    }
  }

  // Enroll student in course
  Future<Map<String, dynamic>> enrollInCourse({
    required String studentId,
    required String courseId,
  }) async {
    try {
      final response = await _supabase
          .from('enrollments')
          .insert({
            'student_id': studentId,
            'course_id': courseId,
            'progress_percentage': 0,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to enroll in course: $e');
    }
  }

  // Get student's enrollments
  Future<List<Map<String, dynamic>>> getStudentEnrollments(String studentId) async {
    try {
      final response = await _supabase
          .from('enrollments')
          .select('''
            *,
            course:courses(
              id, title, description, subject, level, thumbnail_url,
              tutor:profiles!courses_tutor_id_fkey(id, full_name, avatar_url)
            )
          ''')
          .eq('student_id', studentId)
          .order('enrolled_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get student enrollments: $e');
    }
  }

  // Update course progress
  Future<void> updateCourseProgress({
    required String enrollmentId,
    required String contentId,
    int? timeSpentSeconds,
  }) async {
    try {
      // Mark content as completed
      await _supabase
          .from('course_progress')
          .insert({
            'enrollment_id': enrollmentId,
            'content_id': contentId,
            'time_spent_seconds': timeSpentSeconds,
          });

      // Calculate and update overall progress percentage
      await _supabase.rpc('update_enrollment_progress', params: {
        'p_enrollment_id': enrollmentId,
      });
    } catch (e) {
      throw Exception('Failed to update course progress: $e');
    }
  }

  // Get course progress for an enrollment
  Future<List<Map<String, dynamic>>> getCourseProgress(String enrollmentId) async {
    try {
      final response = await _supabase
          .from('course_progress')
          .select()
          .eq('enrollment_id', enrollmentId)
          .order('completed_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get course progress: $e');
    }
  }

  // Real-time subscription to course updates
  RealtimeChannel subscribeToCourse(
    String courseId,
    void Function(CourseModel) onUpdate,
  ) {
    return _supabase
        .channel('course_$courseId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'courses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: courseId,
          ),
          callback: (payload) {
            if (payload.newRecord != null) {
              onUpdate(CourseModel.fromJson(payload.newRecord!));
            }
          },
        )
        .subscribe();
  }

  // Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
