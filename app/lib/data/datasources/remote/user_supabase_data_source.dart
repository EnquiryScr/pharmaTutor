import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

/// Supabase data source for user-related operations
class UserSupabaseDataSource {
  final SupabaseClient _supabase;

  UserSupabaseDataSource(this._supabase);

  // Get current user's profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get current user profile: $e');
    }
  }

  // Get user profile by ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;
      if (preferences != null) updates['preferences'] = preferences;

      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Upload avatar to Supabase Storage
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      // Upload to avatars bucket
      await _supabase.storage
          .from('avatars')
          .upload(filePath, file);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update profile with new avatar URL
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  // Delete avatar from storage
  Future<void> deleteAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final filePath = uri.pathSegments.skip(5).join('/'); // Skip /storage/v1/object/public/avatars/

      // Delete from storage
      await _supabase.storage
          .from('avatars')
          .remove([filePath]);

      // Update profile to remove avatar URL
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete avatar: $e');
    }
  }

  // Search users by name or email (for tutors, students, etc.)
  Future<List<UserModel>> searchUsers({
    String? query,
    String? role,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('profiles')
          .select();

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.or('full_name.ilike.%$query%,email.ilike.%$query%');
      }

      if (role != null) {
        queryBuilder = queryBuilder.eq('role', role);
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get tutors list with optional filtering
  Future<List<UserModel>> getTutors({
    String? subject,
    double? minRating,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('profiles')
          .select()
          .eq('role', 'tutor');

      if (subject != null) {
        queryBuilder = queryBuilder.contains('subjects', [subject]);
      }

      if (minRating != null) {
        queryBuilder = queryBuilder.gte('rating', minRating);
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tutors: $e');
    }
  }

  // Update tutor rating (called after session feedback)
  Future<void> updateTutorRating({
    required String tutorId,
    required double newRating,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'rating': newRating,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tutorId);
    } catch (e) {
      throw Exception('Failed to update tutor rating: $e');
    }
  }

  // Increment tutor's total sessions count
  Future<void> incrementTutorSessions(String tutorId) async {
    try {
      await _supabase.rpc('increment_total_sessions', params: {
        'tutor_id': tutorId,
      });
    } catch (e) {
      throw Exception('Failed to increment tutor sessions: $e');
    }
  }

  // Get notification settings for a user
  Future<Map<String, dynamic>?> getNotificationSettings(String userId) async {
    try {
      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get notification settings: $e');
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    required String userId,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? smsEnabled,
    Map<String, dynamic>? categories,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (emailEnabled != null) updates['email_enabled'] = emailEnabled;
      if (pushEnabled != null) updates['push_enabled'] = pushEnabled;
      if (smsEnabled != null) updates['sms_enabled'] = smsEnabled;
      if (categories != null) updates['categories'] = categories;

      // Check if settings exist
      final existing = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Insert new settings
        await _supabase
            .from('notification_settings')
            .insert({
              'user_id': userId,
              ...updates,
            });
      } else {
        // Update existing settings
        await _supabase
            .from('notification_settings')
            .update(updates)
            .eq('user_id', userId);
      }
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }

  // Register push notification token
  Future<void> registerPushToken({
    required String userId,
    required String token,
    required String deviceType,
  }) async {
    try {
      // Check if token already exists
      final existing = await _supabase
          .from('push_tokens')
          .select()
          .eq('user_id', userId)
          .eq('token', token)
          .maybeSingle();

      if (existing == null) {
        // Insert new token
        await _supabase
            .from('push_tokens')
            .insert({
              'user_id': userId,
              'token': token,
              'device_type': deviceType,
            });
      } else {
        // Update existing token timestamp
        await _supabase
            .from('push_tokens')
            .update({
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      }
    } catch (e) {
      throw Exception('Failed to register push token: $e');
    }
  }

  // Delete push notification token
  Future<void> deletePushToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _supabase
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', token);
    } catch (e) {
      throw Exception('Failed to delete push token: $e');
    }
  }

  // Real-time subscription to user profile changes
  RealtimeChannel subscribeToUserProfile(
    String userId,
    void Function(UserModel) onUpdate,
  ) {
    return _supabase
        .channel('user_profile_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord != null) {
              onUpdate(UserModel.fromJson(payload.newRecord!));
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
