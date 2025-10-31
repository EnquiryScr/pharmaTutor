import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/register_page.dart';
import '../presentation/pages/forgot_password_page.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/tutors/tutors_list_page.dart';
import '../presentation/pages/tutors/tutor_profile_page.dart';
import '../presentation/pages/sessions/sessions_list_page.dart';
import '../presentation/pages/courses/courses_list_page.dart';
import '../presentation/pages/messages/messages_list_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/notifications/notifications_page.dart';

// Router configuration
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // Splash Screen
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),

    // Authentication Routes
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordPage(),
    ),

    // Main Routes
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
      routes: [
        // Dashboard
        GoRoute(
          path: 'dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),

        // Tutors
        GoRoute(
          path: 'tutors',
          name: 'tutors',
          builder: (context, state) => const TutorsListPage(),
          routes: [
            GoRoute(
              path: ':tutorId',
              name: 'tutorProfile',
              builder: (context, state) {
                final tutorId = state.pathParameters['tutorId']!;
                return TutorProfilePage(tutorId: tutorId);
              },
            ),
          ],
        ),

        // Sessions
        GoRoute(
          path: 'sessions',
          name: 'sessions',
          builder: (context, state) => const SessionsListPage(),
        ),

        // Courses
        GoRoute(
          path: 'courses',
          name: 'courses',
          builder: (context, state) => const CoursesListPage(),
        ),

        // Messages
        GoRoute(
          path: 'messages',
          name: 'messages',
          builder: (context, state) => const MessagesListPage(),
        ),

        // Profile
        GoRoute(
          path: 'profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'notifications',
              name: 'notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => _errorBuilder(context, state),
  redirect: (context, state) => _redirect(context, state),
);

// Error builder for unknown routes
Widget _errorBuilder(BuildContext context, GoRouterState state) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Error'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The page "${state.uri.path}" does not exist.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  );
}

// Authentication redirect logic
String? _redirect(BuildContext context, GoRouterState state) {
  final loggedIn = _isLoggedIn();
  final loggingIn = state.uri.path == AppRoutes.login ||
      state.uri.path == AppRoutes.register ||
      state.uri.path == AppRoutes.forgotPassword;

  // If not logged in and not trying to log in, redirect to login
  if (!loggedIn && !loggingIn) {
    return AppRoutes.login;
  }

  // If logged in and trying to access auth pages, redirect to home
  if (loggedIn && loggingIn) {
    return AppRoutes.home;
  }

  return null;
}

// Check if user is logged in (implement your auth check logic)
bool _isLoggedIn() {
  // TODO: Implement actual auth check
  // This should check for valid auth token in storage
  return false;
}

/// Navigation helper class for easy navigation throughout the app
class NavigationHelper {
  static BuildContext? _context;

  static void initialize(BuildContext context) {
    _context = context;
  }

  /// Navigate to login page
  static void goToLogin() {
    _context?.go(AppRoutes.login);
  }

  /// Navigate to register page
  static void goToRegister() {
    _context?.go(AppRoutes.register);
  }

  /// Navigate to forgot password page
  static void goToForgotPassword() {
    _context?.go(AppRoutes.forgotPassword);
  }

  /// Navigate to home page
  static void goToHome() {
    _context?.go(AppRoutes.home);
  }

  /// Navigate to dashboard
  static void goToDashboard() {
    _context?.go('${AppRoutes.home}/dashboard');
  }

  /// Navigate to tutors list
  static void goToTutors() {
    _context?.go('${AppRoutes.home}/tutors');
  }

  /// Navigate to tutor profile
  static void goToTutorProfile(String tutorId) {
    _context?.go('${AppRoutes.home}/tutors/$tutorId');
  }

  /// Navigate to sessions list
  static void goToSessions() {
    _context?.go('${AppRoutes.home}/sessions');
  }

  /// Navigate to courses list
  static void goToCourses() {
    _context?.go('${AppRoutes.home}/courses');
  }

  /// Navigate to messages list
  static void goToMessages() {
    _context?.go('${AppRoutes.home}/messages');
  }

  /// Navigate to profile page
  static void goToProfile() {
    _context?.go('${AppRoutes.home}/profile');
  }

  /// Navigate to settings page
  static void goToSettings() {
    _context?.go('${AppRoutes.home}/profile/settings');
  }

  /// Navigate to notifications page
  static void goToNotifications() {
    _context?.go('${AppRoutes.home}/profile/notifications');
  }

  /// Navigate back to previous page
  static void goBack() {
    if (_context?.canPop() == true) {
      _context?.pop();
    } else {
      goToHome();
    }
  }

  /// Push new route (for modal pages)
  static void push(String route) {
    _context?.push(route);
  }

  /// Push replacement route
  static void pushReplacement(String route) {
    _context?.pushReplacement(route);
  }

  /// Show dialog
  static Future<T?> showDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: _context!,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  /// Show bottom sheet
  static Future<T?> showBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: _context!,
      isScrollControlled: isScrollControlled,
      builder: (context) => child,
    );
  }

  /// Show snackbar
  static void showSnackBar({
    required String message,
    SnackBarAction? action,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(String message) {
    showSnackBar(
      message: message,
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show loading indicator
  static void showLoading({String? message}) {
    showDialog(
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  /// Hide loading indicator
  static void hideLoading() {
    if (_context?.mounted == true) {
      Navigator.of(_context!).pop();
    }
  }
}

/// Route names for easy reference
class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String home = 'home';
  static const String dashboard = 'dashboard';
  static const String tutors = 'tutors';
  static const String tutorProfile = 'tutorProfile';
  static const String sessions = 'sessions';
  static const String courses = 'courses';
  static const String messages = 'messages';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
}

/// Navigation routes utility class
class AppRoutesHelper {
  /// Check if current route is authentication page
  static bool isAuthRoute(String route) {
    return route == AppRoutes.login ||
           route == AppRoutes.register ||
           route == AppRoutes.forgotPassword;
  }

  /// Check if current route is home route
  static bool isHomeRoute(String route) {
    return route.startsWith(AppRoutes.home);
  }

  /// Get route title for AppBar
  static String getRouteTitle(String route) {
    if (route.contains('/tutors/')) return 'Tutor Profile';
    if (route.contains('/profile/settings')) return 'Settings';
    if (route.contains('/profile/notifications')) return 'Notifications';
    
    switch (route) {
      case AppRoutes.home:
      case '${AppRoutes.home}/dashboard':
        return 'Dashboard';
      case '${AppRoutes.home}/tutors':
        return 'Tutors';
      case '${AppRoutes.home}/sessions':
        return 'Sessions';
      case '${AppRoutes.home}/courses':
        return 'Courses';
      case '${AppRoutes.home}/messages':
        return 'Messages';
      case '${AppRoutes.home}/profile':
        return 'Profile';
      case AppRoutes.login:
        return 'Login';
      case AppRoutes.register:
        return 'Register';
      case AppRoutes.forgotPassword:
        return 'Forgot Password';
      default:
        return 'TutorFlow';
    }
  }

  /// Get route icon for bottom navigation
  static IconData? getRouteIcon(String route) {
    switch (route) {
      case '${AppRoutes.home}/dashboard':
        return Icons.dashboard;
      case '${AppRoutes.home}/tutors':
        return Icons.people;
      case '${AppRoutes.home}/sessions':
        return Icons.schedule;
      case '${AppRoutes.home}/courses':
        return Icons.book;
      case '${AppRoutes.home}/messages':
        return Icons.message;
      case '${AppRoutes.home}/profile':
        return Icons.person;
      default:
        return null;
    }
  }
}