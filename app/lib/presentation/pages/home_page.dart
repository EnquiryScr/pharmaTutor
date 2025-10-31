import 'package:flutter/material.dart';
import '../../core/utils/base_view.dart';
import '../../core/widgets/base_widgets.dart';
import '../../core/navigation/app_router.dart';
import '../viewmodels/home_viewmodel.dart';

class HomePage extends BaseView<HomeViewModel> {
  const HomePage({super.key});

  @override
  HomeViewModel createViewModel() {
    return serviceLocator<HomeViewModel>();
  }

  @override
  Widget buildView(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final viewModel = ref.watch(serviceLocator<HomeViewModel>());
        
        return Scaffold(
          body: IndexedStack(
            index: viewModel.currentIndex,
            children: [
              const DashboardPage(),
              const TutorsListPage(),
              const SessionsListPage(),
              const CoursesListPage(),
              const MessagesListPage(),
              const ProfilePage(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: viewModel.currentIndex,
            onTap: (index) => viewModel.setIndex(index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.primary,
            unselectedItemColor: Colors.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Tutors',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule_outlined),
                activeIcon: Icon(Icons.schedule),
                label: 'Sessions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Courses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message_outlined),
                activeIcon: Icon(Icons.message),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

// Placeholder pages for each tab
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Dashboard',
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 64,
              color: Colors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your learning overview will be displayed here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorsListPage extends StatelessWidget {
  const TutorsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Tutors',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              NavigationHelper.showSnackBar(
                message: 'Search functionality to be implemented',
              );
            },
          ),
        ],
      ),
      floatingActionButton: BaseFAB(
        onPressed: () {
          NavigationHelper.showSnackBar(
            message: 'Find tutors functionality to be implemented',
          );
        },
        tooltip: 'Find Tutors',
        child: const Icon(Icons.add),
      ),
      body: const BaseEmptyState(
        icon: Icons.people,
        title: 'No Tutors Found',
        message: 'Start exploring our available tutors',
        actionText: 'Browse Tutors',
        onAction: () {
          NavigationHelper.showSnackBar(
            message: 'Tutor browsing to be implemented',
          );
        },
      ),
    );
  }
}

class SessionsListPage extends StatelessWidget {
  const SessionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Sessions',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              NavigationHelper.showSnackBar(
                message: 'Calendar view to be implemented',
              );
            },
          ),
        ],
      ),
      floatingActionButton: BaseFAB(
        onPressed: () {
          NavigationHelper.showSnackBar(
            message: 'Book session functionality to be implemented',
          );
        },
        tooltip: 'Book Session',
        child: const Icon(Icons.add),
      ),
      body: const BaseEmptyState(
        icon: Icons.schedule,
        title: 'No Sessions',
        message: 'Book your first tutoring session',
        actionText: 'Book Session',
        onAction: () {
          NavigationHelper.showSnackBar(
            message: 'Session booking to be implemented',
          );
        },
      ),
    );
  }
}

class CoursesListPage extends StatelessWidget {
  const CoursesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Courses',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              NavigationHelper.showSnackBar(
                message: 'Search courses to be implemented',
              );
            },
          ),
        ],
      ),
      body: const BaseEmptyState(
        icon: Icons.book,
        title: 'No Courses',
        message: 'Explore our course catalog',
        actionText: 'Browse Courses',
        onAction: () {
          NavigationHelper.showSnackBar(
            message: 'Course browsing to be implemented',
          );
        },
      ),
    );
  }
}

class MessagesListPage extends StatelessWidget {
  const MessagesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Messages',
      ),
      body: const BaseEmptyState(
        icon: Icons.message,
        title: 'No Messages',
        message: 'Start a conversation with your tutors',
        actionText: 'New Message',
        onAction: () {
          NavigationHelper.showSnackBar(
            message: 'Messaging to be implemented',
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => NavigationHelper.goToSettings(),
          ),
        ],
      ),
      body: const BaseEmptyState(
        icon: Icons.person,
        title: 'Profile Settings',
        message: 'Manage your profile and preferences',
        actionText: 'Edit Profile',
        onAction: () {
          NavigationHelper.showSnackBar(
            message: 'Profile editing to be implemented',
          );
        },
      ),
    );
  }
}

// Placeholder HomeViewModel
class HomeViewModel {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
  }
}