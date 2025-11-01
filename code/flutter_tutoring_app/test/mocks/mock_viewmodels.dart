import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/presentation/viewmodels/auth_viewmodel.dart';
import '../../lib/presentation/viewmodels/chat_viewmodel.dart';
import '../../lib/presentation/viewmodels/payment_viewmodel.dart';
import '../../lib/presentation/viewmodels/assignment_viewmodel.dart';
import '../../lib/presentation/viewmodels/profile_viewmodel.dart';
import '../../lib/presentation/viewmodels/dashboard_viewmodel.dart';
import '../../lib/presentation/viewmodels/scheduling_viewmodel.dart';
import '../../lib/presentation/viewmodels/theme_viewmodel.dart';
import '../../lib/presentation/viewmodels/article_viewmodel.dart';
import '../../lib/presentation/viewmodels/query_viewmodel.dart';
import '../../lib/presentation/viewmodels/base_viewmodel.dart';

/// Generate mock classes for all ViewModels
@GenerateMocks([
  AuthViewModel,
  ChatViewModel,
  PaymentViewModel,
  AssignmentViewModel,
  ProfileViewModel,
  DashboardViewModel,
  SchedulingViewModel,
  ThemeViewModel,
  ArticleViewModel,
  QueryViewModel,
  BaseViewModel,
])
import 'mock_viewmodels.mocks.dart';

/// Mock implementations for ViewModels
class MockAuthViewModel extends Mock implements AuthViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  String? get currentUserEmail => 'test@example.com';

  @override
  String? get currentUserId => 'user-123';

  @override
  String? get currentUserRole => 'student';

  @override
  bool get isAuthenticated => true;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> login(String email, String password) async {
    // Mock successful login
  }

  @override
  Future<void> register(String email, String password, Map<String, dynamic> userData) async {
    // Mock successful registration
  }

  @override
  Future<void> logout() async {
    // Mock successful logout
  }

  @override
  Future<void> resetPassword(String email) async {
    // Mock password reset
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> userData) async {
    // Mock profile update
  }

  @override
  Future<void> checkAuthStatus() async {
    // Mock auth status check
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockChatViewModel extends Mock implements ChatViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  List<Map<String, dynamic>> get messages => [
    {'id': 'msg-1', 'content': 'Hello', 'senderId': 'user-123'},
  ];

  @override
  String? get currentRoomId => 'room-123';

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> sendMessage(String content, {String? type, String? roomId}) async {
    // Mock message sending
  }

  @override
  Future<void> loadMessages(String roomId, {int? limit, String? lastMessageId}) async {
    // Mock message loading
  }

  @override
  Future<void> createRoom(Map<String, dynamic> roomData) async {
    // Mock room creation
  }

  @override
  Future<void> joinRoom(String roomId) async {
    // Mock room joining
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    // Mock room leaving
  }

  @override
  Future<void> uploadFile(dynamic file, String roomId) async {
    // Mock file upload
  }

  @override
  void clearMessages() {
    // Mock message clearing
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockPaymentViewModel extends Mock implements PaymentViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  double get totalSpent => 299.97;

  @override
  List<Map<String, dynamic>> get paymentHistory => [
    {'id': 'txn-1', 'amount': 99.99, 'status': 'completed'},
  ];

  @override
  String? get activeSubscriptionId => 'sub-123';

  @override
  bool get isProcessing => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> processPayment(double amount, String currency, Map<String, dynamic> metadata) async {
    // Mock payment processing
  }

  @override
  Future<void> loadPaymentHistory() async {
    // Mock payment history loading
  }

  @override
  Future<void> createSubscription(String priceId) async {
    // Mock subscription creation
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    // Mock subscription cancellation
  }

  @override
  Future<void> savePaymentMethod(Map<String, dynamic> paymentMethodData) async {
    // Mock payment method saving
  }

  @override
  Future<void> processRefund(String paymentIntentId, {double? amount}) async {
    // Mock refund processing
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockAssignmentViewModel extends Mock implements AssignmentViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  List<Map<String, dynamic>> get assignments => [
    {'id': 'assignment-1', 'title': 'Math Assignment', 'status': 'active'},
  ];

  @override
  List<Map<String, dynamic>> get submissions => [
    {'id': 'submission-1', 'assignmentId': 'assignment-1', 'status': 'submitted'},
  ];

  @override
  Map<String, dynamic>? get currentAssignment => {
    'id': 'assignment-123',
    'title': 'Current Assignment',
    'status': 'active',
  };

  @override
  Map<String, dynamic>? get currentSubmission => {
    'id': 'submission-123',
    'status': 'in_progress',
  };

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> createAssignment(Map<String, dynamic> assignmentData) async {
    // Mock assignment creation
  }

  @override
  Future<void> loadAssignments({Map<String, dynamic>? filters}) async {
    // Mock assignments loading
  }

  @override
  Future<void> loadAssignment(String assignmentId) async {
    // Mock assignment loading
  }

  @override
  Future<void> updateAssignment(String assignmentId, Map<String, dynamic> updateData) async {
    // Mock assignment update
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    // Mock assignment deletion
  }

  @override
  Future<void> startSubmission(String assignmentId) async {
    // Mock submission starting
  }

  @override
  Future<void> submitAssignment(String assignmentId, Map<String, dynamic> answers) async {
    // Mock assignment submission
  }

  @override
  Future<void> loadSubmissions(String assignmentId) async {
    // Mock submissions loading
  }

  @override
  Future<void> gradeSubmission(String submissionId, Map<String, dynamic> grades) async {
    // Mock submission grading
  }

  @override
  Future<void> loadSubmissionAnalytics(String assignmentId) async {
    // Mock analytics loading
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockProfileViewModel extends Mock implements ProfileViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  Map<String, dynamic>? get userProfile => {
    'id': 'user-123',
    'email': 'test@example.com',
    'firstName': 'John',
    'lastName': 'Doe',
    'role': 'student',
  };

  @override
  bool get isEditing => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadProfile() async {
    // Mock profile loading
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    // Mock profile update
  }

  @override
  Future<void> uploadProfilePicture(dynamic imageFile) async {
    // Mock profile picture upload
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    // Mock password change
  }

  @override
  void toggleEditMode() {
    // Mock edit mode toggle
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockDashboardViewModel extends Mock implements DashboardViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  Map<String, dynamic>? get dashboardData => {
    'totalSessions': 15,
    'completedAssignments': 8,
    'upcomingSessions': 3,
    'averageScore': 85.5,
  };

  @override
  List<Map<String, dynamic>> get recentActivity => [
    {'id': 'activity-1', 'type': 'session_completed', 'description': 'Math session completed'},
  ];

  @override
  List<Map<String, dynamic>> get upcomingTasks => [
    {'id': 'task-1', 'title': 'Assignment due', 'dueDate': '2024-01-08'},
  ];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadDashboardData() async {
    // Mock dashboard data loading
  }

  @override
  Future<void> refreshDashboard() async {
    // Mock dashboard refresh
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockSchedulingViewModel extends Mock implements SchedulingViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  List<Map<String, dynamic>> get availableSlots => [
    {'id': 'slot-1', 'startTime': '2024-01-08T10:00:00Z', 'duration': 60},
  ];

  @override
  List<Map<String, dynamic>> get scheduledSessions => [
    {'id': 'session-1', 'title': 'Math Session', 'scheduledTime': '2024-01-08T10:00:00Z'},
  ];

  @override
  Map<String, dynamic>? get selectedSlot => {
    'id': 'slot-1',
    'startTime': '2024-01-08T10:00:00Z',
    'duration': 60,
  };

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadAvailableSlots(DateTime date, {String? tutorId}) async {
    // Mock available slots loading
  }

  @override
  Future<void> bookSession(String slotId, Map<String, dynamic> sessionData) async {
    // Mock session booking
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    // Mock session cancellation
  }

  @override
  Future<void> loadScheduledSessions({DateTime? startDate, DateTime? endDate}) async {
    // Mock scheduled sessions loading
  }

  @override
  void selectSlot(Map<String, dynamic> slot) {
    // Mock slot selection
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockThemeViewModel extends Mock implements ThemeViewModel {
  @override
  bool get isDarkMode => false;

  @override
  String get currentTheme => 'light';

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  void toggleTheme() {
    // Mock theme toggle
  }

  @override
  void setTheme(String theme) {
    // Mock theme setting
  }

  @override
  Future<void> loadThemePreference() async {
    // Mock theme preference loading
  }

  @override
  Future<void> saveThemePreference(String theme) async {
    // Mock theme preference saving
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockArticleViewModel extends Mock implements ArticleViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  List<Map<String, dynamic>> get articles => [
    {'id': 'article-1', 'title': 'Test Article', 'content': 'Test content'},
  ];

  @override
  Map<String, dynamic>? get currentArticle => {
    'id': 'article-1',
    'title': 'Test Article',
    'content': 'Test content',
    'author': 'Test Author',
  };

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadArticles({Map<String, dynamic>? filters}) async {
    // Mock articles loading
  }

  @override
  Future<void> loadArticle(String articleId) async {
    // Mock article loading
  }

  @override
  Future<void> searchArticles(String query) async {
    // Mock article search
  }

  @override
  Future<void> createArticle(Map<String, dynamic> articleData) async {
    // Mock article creation
  }

  @override
  Future<void> updateArticle(String articleId, Map<String, dynamic> updateData) async {
    // Mock article update
  }

  @override
  Future<void> deleteArticle(String articleId) async {
    // Mock article deletion
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

class MockQueryViewModel extends Mock implements QueryViewModel {
  @override
  ViewState get state => ViewState.loaded;

  @override
  List<Map<String, dynamic>> get queries => [
    {'id': 'query-1', 'title': 'Test Query', 'status': 'open'},
  ];

  @override
  Map<String, dynamic>? get currentQuery => {
    'id': 'query-1',
    'title': 'Test Query',
    'description': 'Test description',
    'status': 'open',
  };

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> createQuery(Map<String, dynamic> queryData) async {
    // Mock query creation
  }

  @override
  Future<void> loadQueries({Map<String, dynamic>? filters}) async {
    // Mock queries loading
  }

  @override
  Future<void> loadQuery(String queryId) async {
    // Mock query loading
  }

  @override
  Future<void> updateQuery(String queryId, Map<String, dynamic> updateData) async {
    // Mock query update
  }

  @override
  Future<void> respondToQuery(String queryId, String response) async {
    // Mock query response
  }

  @override
  Future<void> closeQuery(String queryId, String resolution) async {
    // Mock query closing
  }

  @override
  void clearError() {
    // Mock error clearing
  }
}

/// Factory methods for creating mock ViewModels
class MockViewModelFactory {
  static MockAuthViewModel createAuthViewModel() {
    return MockAuthViewModel();
  }

  static MockChatViewModel createChatViewModel() {
    return MockChatViewModel();
  }

  static MockPaymentViewModel createPaymentViewModel() {
    return MockPaymentViewModel();
  }

  static MockAssignmentViewModel createAssignmentViewModel() {
    return MockAssignmentViewModel();
  }

  static MockProfileViewModel createProfileViewModel() {
    return MockProfileViewModel();
  }

  static MockDashboardViewModel createDashboardViewModel() {
    return MockDashboardViewModel();
  }

  static MockSchedulingViewModel createSchedulingViewModel() {
    return MockSchedulingViewModel();
  }

  static MockThemeViewModel createThemeViewModel() {
    return MockThemeViewModel();
  }

  static MockArticleViewModel createArticleViewModel() {
    return MockArticleViewModel();
  }

  static MockQueryViewModel createQueryViewModel() {
    return MockQueryViewModel();
  }
}

/// Helper methods for ViewModel testing
class MockViewModelHelpers {
  static void setupAuthViewModelSuccess(MockAuthViewModel viewModel) {
    when(viewModel.state).thenReturn(ViewState.loaded);
    when(viewModel.isAuthenticated).thenReturn(true);
    when(viewModel.currentUserId).thenReturn('user-123');
    when(viewModel.currentUserRole).thenReturn('student');
    when(viewModel.currentUserEmail).thenReturn('test@example.com');
    when(viewModel.isLoading).thenReturn(false);
    when(viewModel.error).thenReturn(null);
  }

  static void setupAuthViewModelFailure(MockAuthViewModel viewModel) {
    when(viewModel.state).thenReturn(ViewState.error);
    when(viewModel.isAuthenticated).thenReturn(false);
    when(viewModel.currentUserId).thenReturn(null);
    when(viewModel.currentUserRole).thenReturn(null);
    when(viewModel.currentUserEmail).thenReturn(null);
    when(viewModel.isLoading).thenReturn(false);
    when(viewModel.error).thenReturn('Authentication failed');
  }

  static void setupChatViewModelSuccess(MockChatViewModel viewModel) {
    when(viewModel.state).thenReturn(ViewState.loaded);
    when(viewModel.messages).thenReturn([
      {'id': 'msg-1', 'content': 'Hello', 'senderId': 'user-123'},
    ]);
    when(viewModel.currentRoomId).thenReturn('room-123');
    when(viewModel.isLoading).thenReturn(false);
    when(viewModel.error).thenReturn(null);
  }

  static void setupPaymentViewModelSuccess(MockPaymentViewModel viewModel) {
    when(viewModel.state).thenReturn(ViewState.loaded);
    when(viewModel.totalSpent).thenReturn(299.97);
    when(viewModel.paymentHistory).thenReturn([
      {'id': 'txn-1', 'amount': 99.99, 'status': 'completed'},
    ]);
    when(viewModel.activeSubscriptionId).thenReturn('sub-123');
    when(viewModel.isProcessing).thenReturn(false);
    when(viewModel.isLoading).thenReturn(false);
    when(viewModel.error).thenReturn(null);
  }

  static void setupAssignmentViewModelSuccess(MockAssignmentViewModel viewModel) {
    when(viewModel.state).thenReturn(ViewState.loaded);
    when(viewModel.assignments).thenReturn([
      {'id': 'assignment-1', 'title': 'Math Assignment', 'status': 'active'},
    ]);
    when(viewModel.submissions).thenReturn([
      {'id': 'submission-1', 'assignmentId': 'assignment-1', 'status': 'submitted'},
    ]);
    when(viewModel.currentAssignment).thenReturn({
      'id': 'assignment-123',
      'title': 'Current Assignment',
      'status': 'active',
    });
    when(viewModel.currentSubmission).thenReturn({
      'id': 'submission-123',
      'status': 'in_progress',
    });
    when(viewModel.isLoading).thenReturn(false);
    when(viewModel.error).thenReturn(null);
  }

  static void setupViewModelLoadingState(MockBaseViewModel viewModel) {
    when(viewModel.state).thenReturn(ViewState.loading);
    when(viewModel.isLoading).thenReturn(true);
    when(viewModel.error).thenReturn(null);
  }

  static void setupViewModelErrorState(MockBaseViewModel viewModel, String error) {
    when(viewModel.state).thenReturn(ViewState.error);
    when(viewModel.isLoading).thenReturn(false);
    when(viewModel.error).thenReturn(error);
  }

  static void setupViewModelEmptyState(MockBaseViewModel viewModel) {
    when(viewModel.state).thenReturn(ViewState.empty);
    when(viewModel.isLoading).thenReturn(false);
    when(viewModel.error).thenReturn(null);
  }
}