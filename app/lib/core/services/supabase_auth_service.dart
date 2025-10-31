import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Supabase Authentication Service
/// Handles all authentication operations using Supabase Auth
class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phone != null) 'phone': phone,
          ...?metadata,
        },
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign in with OAuth provider
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.pharmat://login-callback/',
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('OAuth sign in failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.pharmat://reset-password/',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Update password
  Future<UserResponse> updatePassword({
    required String newPassword,
  }) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password update failed: ${e.toString()}');
    }
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: data),
      );

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Metadata update failed: ${e.toString()}');
    }
  }

  /// Send verification email
  Future<void> resendVerificationEmail() async {
    try {
      if (currentUser?.email == null) {
        throw Exception('No user email found');
      }

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: currentUser!.email!,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Resend verification failed: ${e.toString()}');
    }
  }

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Session refresh failed: ${e.toString()}');
    }
  }

  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  /// Update user profile in database
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _supabase
          .from('profiles')
          .update(data)
          .eq('id', currentUser!.id);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Handle auth exceptions with user-friendly messages
  Exception _handleAuthException(AuthException e) {
    String message;
    
    switch (e.message) {
      case 'Invalid login credentials':
        message = 'Invalid email or password';
        break;
      case 'Email not confirmed':
        message = 'Please verify your email address';
        break;
      case 'User already registered':
        message = 'An account with this email already exists';
        break;
      case 'Password should be at least 6 characters':
        message = 'Password must be at least 6 characters';
        break;
      default:
        message = e.message;
    }

    return Exception(message);
  }

  /// Dispose resources
  void dispose() {
    // Clean up if needed
  }
}
