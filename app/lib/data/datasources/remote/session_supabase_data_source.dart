import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/session_model.dart';

/// Supabase data source for session-related operations
class SessionSupabaseDataSource {
  final SupabaseClient _supabase;

  SessionSupabaseDataSource(this._supabase);

  // Create a new session
  Future<SessionModel> createSession({
    required String tutorId,
    required String studentId,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    String? subject,
    String? meetingLink,
    double? price,
  }) async {
    try {
      final response = await _supabase
          .from('sessions')
          .insert({
            'tutor_id': tutorId,
            'student_id': studentId,
            'start_time': startTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'status': status,
            'subject': subject,
            'meeting_link': meetingLink,
            'price': price,
          })
          .select()
          .single();

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // Get session by ID
  Future<SessionModel?> getSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            tutor:profiles!sessions_tutor_id_fkey(id, full_name, avatar_url, rating),
            student:profiles!sessions_student_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('id', sessionId)
          .single();

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  // Get sessions with filtering
  Future<List<SessionModel>> getSessions({
    String? tutorId,
    String? studentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('sessions')
          .select('''
            *,
            tutor:profiles!sessions_tutor_id_fkey(id, full_name, avatar_url, rating),
            student:profiles!sessions_student_id_fkey(id, full_name, avatar_url)
          ''');

      if (tutorId != null) {
        queryBuilder = queryBuilder.eq('tutor_id', tutorId);
      }

      if (studentId != null) {
        queryBuilder = queryBuilder.eq('student_id', studentId);
      }

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('start_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('start_time', endDate.toIso8601String());
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('start_time', ascending: false);

      return (response as List)
          .map((json) => SessionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sessions: $e');
    }
  }

  // Get upcoming sessions for a user
  Future<List<SessionModel>> getUpcomingSessions({
    String? userId,
    bool? asTutor,
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      var queryBuilder = _supabase
          .from('sessions')
          .select('''
            *,
            tutor:profiles!sessions_tutor_id_fkey(id, full_name, avatar_url, rating),
            student:profiles!sessions_student_id_fkey(id, full_name, avatar_url)
          ''')
          .gte('start_time', now)
          .in_('status', ['scheduled', 'confirmed']);

      if (userId != null && asTutor != null) {
        if (asTutor) {
          queryBuilder = queryBuilder.eq('tutor_id', userId);
        } else {
          queryBuilder = queryBuilder.eq('student_id', userId);
        }
      }

      final response = await queryBuilder
          .limit(limit)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => SessionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming sessions: $e');
    }
  }

  // Get past sessions for a user
  Future<List<SessionModel>> getPastSessions({
    String? userId,
    bool? asTutor,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      var queryBuilder = _supabase
          .from('sessions')
          .select('''
            *,
            tutor:profiles!sessions_tutor_id_fkey(id, full_name, avatar_url, rating),
            student:profiles!sessions_student_id_fkey(id, full_name, avatar_url)
          ''')
          .lt('end_time', now)
          .eq('status', 'completed');

      if (userId != null && asTutor != null) {
        if (asTutor) {
          queryBuilder = queryBuilder.eq('tutor_id', userId);
        } else {
          queryBuilder = queryBuilder.eq('student_id', userId);
        }
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('start_time', ascending: false);

      return (response as List)
          .map((json) => SessionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get past sessions: $e');
    }
  }

  // Update session status
  Future<SessionModel> updateSessionStatus({
    required String sessionId,
    required String status,
    String? meetingLink,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (meetingLink != null) {
        updates['meeting_link'] = meetingLink;
      }

      final response = await _supabase
          .from('sessions')
          .update(updates)
          .eq('id', sessionId)
          .select()
          .single();

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update session status: $e');
    }
  }

  // Update session details
  Future<SessionModel> updateSession({
    required String sessionId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? subject,
    String? meetingLink,
    double? price,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (startTime != null) updates['start_time'] = startTime.toIso8601String();
      if (endTime != null) updates['end_time'] = endTime.toIso8601String();
      if (status != null) updates['status'] = status;
      if (subject != null) updates['subject'] = subject;
      if (meetingLink != null) updates['meeting_link'] = meetingLink;
      if (price != null) updates['price'] = price;

      final response = await _supabase
          .from('sessions')
          .update(updates)
          .eq('id', sessionId)
          .select()
          .single();

      return SessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  // Cancel session
  Future<void> cancelSession(String sessionId) async {
    try {
      await _supabase
          .from('sessions')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to cancel session: $e');
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase
          .from('sessions')
          .delete()
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // Submit session feedback
  Future<Map<String, dynamic>> submitSessionFeedback({
    required String sessionId,
    required String studentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _supabase
          .from('session_feedback')
          .insert({
            'session_id': sessionId,
            'student_id': studentId,
            'rating': rating,
            'comment': comment,
          })
          .select()
          .single();

      // Update tutor's average rating
      final session = await getSession(sessionId);
      if (session != null) {
        await _supabase.rpc('update_tutor_rating', params: {
          'tutor_id': session.tutorId,
        });
      }

      return response;
    } catch (e) {
      throw Exception('Failed to submit session feedback: $e');
    }
  }

  // Get session feedback
  Future<Map<String, dynamic>?> getSessionFeedback(String sessionId) async {
    try {
      final response = await _supabase
          .from('session_feedback')
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get session feedback: $e');
    }
  }

  // Get tutor reviews
  Future<List<Map<String, dynamic>>> getTutorReviews({
    required String tutorId,
    bool? isVerified,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('reviews')
          .select('''
            *,
            student:profiles!reviews_student_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('tutor_id', tutorId);

      if (isVerified != null) {
        queryBuilder = queryBuilder.eq('is_verified', isVerified);
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get tutor reviews: $e');
    }
  }

  // Add tutor review
  Future<Map<String, dynamic>> addTutorReview({
    required String tutorId,
    required String studentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .insert({
            'tutor_id': tutorId,
            'student_id': studentId,
            'rating': rating,
            'comment': comment,
            'is_verified': false, // Will be verified if student has completed sessions
          })
          .select()
          .single();

      // Update tutor's average rating
      await _supabase.rpc('update_tutor_rating', params: {
        'tutor_id': tutorId,
      });

      return response;
    } catch (e) {
      throw Exception('Failed to add tutor review: $e');
    }
  }

  // Real-time subscription to session updates
  RealtimeChannel subscribeToSession(
    String sessionId,
    void Function(SessionModel) onUpdate,
  ) {
    return _supabase
        .channel('session_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) {
            if (payload.newRecord != null) {
              onUpdate(SessionModel.fromJson(payload.newRecord!));
            }
          },
        )
        .subscribe();
  }

  // Subscribe to user's sessions (for real-time updates on upcoming sessions)
  RealtimeChannel subscribeToUserSessions(
    String userId,
    bool asTutor,
    void Function(SessionModel) onInsert,
    void Function(SessionModel) onUpdate,
  ) {
    final channel = _supabase.channel('user_sessions_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sessions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: asTutor ? 'tutor_id' : 'student_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onInsert(SessionModel.fromJson(payload.newRecord!));
        }
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'sessions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: asTutor ? 'tutor_id' : 'student_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onUpdate(SessionModel.fromJson(payload.newRecord!));
        }
      },
    );

    return channel.subscribe();
  }

  // Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
