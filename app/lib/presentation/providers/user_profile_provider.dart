import 'package:flutter/foundation.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../../data/models/user_model.dart';
import 'package:dartz/dartz.dart';
import '../../data/models/failure.dart';

/// Provider for user profile management
/// Uses UserRepositoryImpl with cache-first pattern for instant UI updates
class UserProfileProvider extends ChangeNotifier {
  final SupabaseDependencies _dependencies = SupabaseDependencies();

  UserModel? _currentProfile;
  List<UserModel> _tutors = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  // Getters
  UserModel? get currentProfile => _currentProfile;
  List<UserModel> get tutors => _tutors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSearched => _hasSearched;

  /// Load user profile (cache-first, updates in background)
  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.userRepository.getProfile(userId);
      result.fold(
        (failure) => _setError(failure.message),
        (profile) {
          _currentProfile = profile;
          notifyListeners();
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.userRepository.updateProfile(
        userId,
        updates,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (profile) {
          _currentProfile = profile;
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Upload avatar
  Future<bool> uploadAvatar(String userId, List<int> fileBytes, String fileName) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _dependencies.userRepository.uploadAvatar(
        userId,
        fileBytes,
        fileName,
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (avatarUrl) {
          // Update current profile with new avatar
          if (_currentProfile != null) {
            _currentProfile = UserModel(
              userId: _currentProfile!.userId,
              email: _currentProfile!.email,
              fullName: _currentProfile!.fullName,
              role: _currentProfile!.role,
              avatarUrl: avatarUrl,
              phone: _currentProfile!.phone,
              bio: _currentProfile!.bio,
              subjects: _currentProfile!.subjects,
              rating: _currentProfile!.rating,
              totalStudents: _currentProfile!.totalStudents,
              completedSessions: _currentProfile!.completedSessions,
              hourlyRate: _currentProfile!.hourlyRate,
              isAvailable: _currentProfile!.isAvailable,
              emailVerified: _currentProfile!.emailVerified,
              createdAt: _currentProfile!.createdAt,
              updatedAt: DateTime.now(),
            );
            notifyListeners();
          }
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Search tutors with filters
  Future<void> searchTutors({
    String? query,
    List<String>? subjects,
    double? minRating,
    double? maxHourlyRate,
  }) async {
    _setLoading(true);
    _clearError();
    _hasSearched = true;

    try {
      final result = await _dependencies.userRepository.searchTutors(
        query: query,
        subjects: subjects,
        minRating: minRating,
        maxHourlyRate: maxHourlyRate,
      );

      result.fold(
        (failure) {
          _setError(failure.message);
          _tutors = [];
        },
        (tutors) {
          _tutors = tutors;
        },
      );
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Clear tutor search results
  void clearTutorSearch() {
    _tutors = [];
    _hasSearched = false;
    notifyListeners();
  }

  /// Refresh current profile (force update from Supabase)
  Future<void> refreshProfile(String userId) async {
    await loadProfile(userId);
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

  /// Clear all data (for logout)
  void clear() {
    _currentProfile = null;
    _tutors = [];
    _errorMessage = null;
    _hasSearched = false;
    notifyListeners();
  }
}
