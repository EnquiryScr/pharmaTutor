import 'package:flutter/foundation.dart';

/// Supabase configuration
class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vprbkzgwrjkkgxfihoyj.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZwcmJremd3cmpra2d4Zmlob3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4OTY5NTYsImV4cCI6MjA3NzQ3Mjk1Nn0.zv3iSE8FWrIM8BHlgmvgOsYNQnl3bxdyq2k99r29sX4',
  );

  // Enable debug mode for development
  static bool get isDebugMode => kDebugMode;

  // Supabase client options
  static const bool enableLogging = true;
  static const bool enableAutoRefreshToken = true;
  static const Duration authCallbackUrlHostTimeout = Duration(seconds: 30);
}
