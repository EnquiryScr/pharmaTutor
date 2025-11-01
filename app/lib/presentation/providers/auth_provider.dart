import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Auth Provider using Riverpod with proper dependency injection
final authProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) {
    final dependencies = SupabaseDependencies();
    // Note: AuthViewModel will be updated to use SupabaseDependencies
    return AuthViewModel();
  },
);

/// Auth State for Riverpod
class AuthState {
  final dynamic user;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    dynamic user,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}