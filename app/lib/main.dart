import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils/dependency_injection.dart';
import 'core/utils/supabase_dependencies.dart';
import 'core/navigation/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (MUST be first for backend integration)
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: SupabaseConfig.isDebugMode,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: SupabaseConfig.enableAutoRefreshToken,
    ),
  );

  // Initialize SQLite cache and Supabase data sources
  await SupabaseDependencies().initialize();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize dependency injection (legacy - can be phased out)
  await initializeDependencies();

  // Initialize Flutter ScreenUtil for responsive design
  await ScreenUtil.ensureInitialized();

  // Run the app
  runApp(
    const ProviderScope(
      child: TutorFlowApp(),
    ),
  );
}

class TutorFlowApp extends ConsumerWidget {
  const TutorFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: router,
          localizationsDelegates: const [
            // Add your localization delegates here
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
            // Add more locales as needed
          ],
        );
      },
    );
  }
}