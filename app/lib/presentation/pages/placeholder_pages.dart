import 'package:flutter/material.dart';
import '../../core/utils/base_view.dart';
import '../../core/widgets/base_widgets.dart';
import '../../core/navigation/app_router.dart';

class RegisterPage extends BaseView {
  const RegisterPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Create Account',
      ),
      body: const BaseEmptyState(
        icon: Icons.person_add,
        title: 'Registration',
        message: 'User registration functionality to be implemented',
      ),
    );
  }
}

class ForgotPasswordPage extends BaseView {
  const ForgotPasswordPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Forgot Password',
      ),
      body: const BaseEmptyState(
        icon: Icons.lock_reset,
        title: 'Password Reset',
        message: 'Password reset functionality to be implemented',
      ),
    );
  }
}

class DashboardPage extends BaseView {
  const DashboardPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return const BaseEmptyState(
      icon: Icons.dashboard,
      title: 'Dashboard',
      message: 'Dashboard content to be implemented',
    );
  }
}

class TutorProfilePage extends BaseView {
  final String tutorId;

  const TutorProfilePage({super.key, required this.tutorId});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Tutor Profile',
      ),
      body: BaseEmptyState(
        icon: Icons.person,
        title: 'Tutor Profile',
        message: 'Profile for tutor ID: $tutorId',
      ),
    );
  }
}

class SessionsListPage extends BaseView {
  const SessionsListPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return const BaseEmptyState(
      icon: Icons.schedule,
      title: 'Sessions',
      message: 'Session management to be implemented',
    );
  }
}

class CoursesListPage extends BaseView {
  const CoursesListPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return const BaseEmptyState(
      icon: Icons.book,
      title: 'Courses',
      message: 'Course catalog to be implemented',
    );
  }
}

class MessagesListPage extends BaseView {
  const MessagesListPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return const BaseEmptyState(
      icon: Icons.message,
      title: 'Messages',
      message: 'Messaging system to be implemented',
    );
  }
}

class ProfilePage extends BaseView {
  const ProfilePage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return const BaseEmptyState(
      icon: Icons.person,
      title: 'Profile',
      message: 'Profile management to be implemented',
    );
  }
}

class SettingsPage extends BaseView {
  const SettingsPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return const BaseEmptyState(
      icon: Icons.settings,
      title: 'Settings',
      message: 'App settings to be implemented',
    );
  }
}

class NotificationsPage extends BaseView {
  const NotificationsPage({super.key});

  @override
  Widget buildView(BuildContext context) {
    return const BaseEmptyState(
      icon: Icons.notifications,
      title: 'Notifications',
      message: 'Notification settings to be implemented',
    );
  }
}