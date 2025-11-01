import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/supabase_dependencies.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../presentation/providers/provider_bindings.dart';
import '../app_initializer.dart';

// Modern Dependency Injection System
// Integrates Riverpod with Supabase for a robust architecture

/// Modern dependency injection manager
/// Works with both GetIt (legacy) and Riverpod (modern) patterns
class ModernDependencyInjection {
  static final ModernDependencyInjection _instance = ModernDependencyInjection._internal();
  factory ModernDependencyInjection() => _instance;
  ModernDependencyInjection._internal();

  bool _initialized = false;

  /// Initialize all dependencies (modern approach)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Supabase configuration
      await SupabaseConfig.initialize();
      
      // 2. Initialize provider bindings (Riverpod)
      await ProviderBindings().initialize();
      
      // 3. Initialize Supabase Auth Service
      SupabaseAuthService();

      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize dependencies: $e');
    }
  }

  /// Get Supabase dependencies
  SupabaseDependencies get dependencies {
    if (!_initialized) {
      throw StateError('Dependencies not initialized. Call initialize() first.');
    }
    return ProviderBindings().dependencies;
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Reset (for testing/logout)
  void reset() {
    ProviderBindings().clear();
    _initialized = false;
  }
}

/// Provider for modern dependency injection
final modernDependencyInjectionProvider = Provider<ModernDependencyInjection>((ref) {
  return ModernDependencyInjection();
});

/// Quick setup function for main.dart
/// Call this before runApp() for modern architecture
Future<void> setupModernDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();
  final di = ModernDependencyInjection();
  await di.initialize();
}

/// Legacy dependency injection setup (deprecated)
/// Use ModernDependencyInjection instead
@Deprecated('Use setupModernDependencies() instead')
Future<void> initializeDependencies() async {
  await setupModernDependencies();
}

/// Legacy helper functions (deprecated)
@Deprecated('Use ModernDependencyInjection instead')
T getService<T>() {
  throw UnsupportedError('Use ModernDependencyInjection instead');
}

@Deprecated('Use ModernDependencyInjection.reset() instead')
Future<void> resetServiceLocator() async {
  ModernDependencyInjection().reset();
}