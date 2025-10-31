import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../data/models/user_model.dart';

/// Supabase-based Authentication Provider
/// Manages authentication state and provides auth methods
class SupabaseAuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  SupabaseAuthProvider(this._authService) {
    _initializeAuthListener();
    _loadCurrentUser();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize auth state listener
  void _initializeAuthListener() {
    _authService.authStateChanges.listen((authState) {
      final event = authState.event;
      
      if (event == AuthChangeEvent.signedIn) {
        _loadCurrentUser();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        _loadCurrentUser();
      }
    });
  }

  /// Load current user profile
  Future<void> _loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _currentUser = UserModel.fromJson(profile);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (response.user != null) {
        await _loadCurrentUser();
        _setLoading(false);
        return true;
      }

      _setError('Sign up failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadCurrentUser();
        _setLoading(false);
        return true;
      }

      _setError('Sign in failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with OAuth provider
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.signInWithOAuth(provider);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _currentUser = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update password
  Future<bool> updatePassword({required String newPassword}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updatePassword(newPassword: newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(data);
      await _loadCurrentUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    await _loadCurrentUser();
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resendVerificationEmail();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
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

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
