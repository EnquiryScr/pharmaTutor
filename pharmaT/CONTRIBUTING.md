# Contributing to pharmaT

Thank you for your interest in contributing to pharmaT! This document provides guidelines and information for contributors.

## 🎯 How to Contribute

### Types of Contributions

We welcome various types of contributions:

- 🐛 **Bug Reports** - Help us identify and fix issues
- ✨ **Feature Requests** - Suggest new features or improvements  
- 📝 **Documentation** - Improve guides, API docs, and code comments
- 💻 **Code Contributions** - Implement features, fix bugs, optimize performance
- 🧪 **Testing** - Add unit tests, widget tests, or integration tests
- 🎨 **UI/UX** - Improve design, accessibility, and user experience

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.22+
- **Dart** 3.4+
- **Git** for version control
- **Android Studio** or **VS Code**
- **Emulator** or **Physical Device** for testing

### Development Setup

1. **Fork the Repository**
   ```bash
   git clone https://github.com/EnquiryScr/pharmaT.git
   cd pharmaT
   ```

2. **Setup Flutter Environment**
   ```bash
   cd app
   flutter doctor
   flutter pub get
   ```

3. **Verify Installation**
   ```bash
   flutter analyze
   flutter test
   flutter run
   ```

## 💻 Development Workflow

### Branch Strategy

We follow a feature branch strategy:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features (`feature/user-authentication`)
- `bugfix/*` - Bug fixes (`bugfix/login-crash`)
- `hotfix/*` - Urgent production fixes (`hotfix/security-patch`)

### Making Changes

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
   - Write clean, readable code
   - Add comments for complex logic

3. **Test Changes**
   ```bash
   flutter analyze
   flutter test
   flutter test --coverage
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add user profile management"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## 📝 Commit Message Guidelines

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Adding/updating tests
- `chore:` - Maintenance tasks

**Examples:**
```bash
feat(auth): add biometric authentication support
fix(ui): resolve profile page crash on Android 13
docs(readme): update installation instructions
test(provider): add user profile provider tests
```

## 🏗️ Code Standards

### Architecture Guidelines

- **Follow Clean Architecture** - Separate concerns across layers
- **Use Repository Pattern** - Abstract data sources
- **Implement Provider Pattern** - For state management
- **Follow MVVM** - Model-View-ViewModel architecture

### Flutter Specific Guidelines

```dart
// ✅ Good: Clear class naming
class UserProfileProvider extends ChangeNotifier {}

// ✅ Good: Proper error handling
Future<Either<Failure, User>> fetchUser(String id) async {
  try {
    final user = await _repository.getUser(id);
    return Right(user);
  } catch (e) {
    return Left(Failure('Failed to fetch user: $e'));
  }
}

// ✅ Good: Comprehensive error types
enum AuthErrorType {
  invalidCredentials,
  networkError,
  serverError,
  unknown;
}

// ❌ Bad: Unclear naming
class UserProvider extends ChangeNotifier {}

// ❌ Bad: Poor error handling
Future<User> getUser(String id) async {
  return await _service.getUser(id); // No error handling
}
```

### Code Quality Checklist

- [ ] **Clean Code** - Readable, maintainable, no duplication
- [ ] **Type Safety** - Strong typing, null safety compliance
- [ ] **Error Handling** - Proper exception handling with Either
- [ ] **Documentation** - Clear comments for complex logic
- [ ] **Testing** - Unit tests for business logic
- [ ] **Performance** - Efficient data structures and algorithms
- [ ] **Accessibility** - WCAG 2.1 AA compliance

## 🧪 Testing Requirements

### Test Categories

1. **Unit Tests** - Test individual functions/methods
2. **Widget Tests** - Test UI components
3. **Integration Tests** - Test complete user workflows
4. **Provider Tests** - Test state management logic

### Test Examples

```dart
// Unit Test Example
void main() {
  group('UserRepositoryImpl', () {
    test('should return user when cache hit', () async {
      // Arrange
      when(mockCache.getUser(any)).thenAnswer((_) async => testUser);
      // Act
      final result = await repository.getUser(userId);
      // Assert
      expect(result.isRight(), true);
      verify(mockCache.getUser(userId)).called(1);
    });
  });
}

// Provider Test Example
void main() {
  testWidgets('should show loading state while fetching', (tester) async {
    // Build widget
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(home: UserProfilePage()),
      ),
    );
    
    // Verify loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/data/repositories/user_repository_test.dart

# Watch mode (re-run on changes)
flutter test --watch
```

## 📱 Platform Guidelines

### Cross-Platform Compatibility

- **Test on Multiple Platforms** - Android, iOS, Web, Desktop
- **Handle Platform Differences** - Use platform-specific code appropriately
- **Responsive Design** - Support various screen sizes
- **Performance Optimization** - Platform-specific optimizations

### Platform-Specific Code

```dart
// Platform-specific implementations
import 'package:flutter/foundation.dart';

class PlatformService {
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isWeb => kIsWeb;
  
  static Future<void> showNativeDialog() {
    if (isIOS) {
      return _showIOSDialog();
    } else if (isAndroid) {
      return _showAndroidDialog();
    } else {
      return _showWebDialog();
    }
  }
}
```

## 🔒 Security Guidelines

### Data Protection

- **Never commit secrets** - Use environment variables
- **Validate inputs** - Sanitize all user inputs
- **Use HTTPS** - For all network communications
- **Implement RLS** - Row-level security in database

### Code Security

```dart
// ✅ Secure: Environment-based configuration
class Config {
  static String get apiKey => 
      Platform.environment['API_KEY'] ?? '';
}

// ❌ Insecure: Hardcoded credentials
class Config {
  static const String apiKey = 'sk-1234567890abcdef'; // Don't do this!
}
```

## 📊 Performance Guidelines

### App Performance

- **Optimize Widgets** - Minimize rebuilds with const constructors
- **Lazy Loading** - Load data on demand
- **Cache Management** - Efficient memory usage
- **Image Optimization** - Proper image handling and caching

### Performance Examples

```dart
// ✅ Good: Optimized widget
class UserAvatar extends StatelessWidget {
  const UserAvatar({Key? key, required this.user}) : super(key: key);
  
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: user.avatarUrl != null
          ? NetworkImage(user.avatarUrl!)
          : null,
      child: user.avatarUrl == null 
          ? Text(user.name[0]) 
          : null,
    );
  }
}

// ✅ Good: Lazy loading
class CourseList extends StatefulWidget {
  @override
  _CourseListState createState() => _CourseListState();
}

class _CourseListState extends State<CourseList> {
  List<Course> _courses = [];
  bool _isLoading = false;
  int _page = 0;
  
  Future<void> _loadMore() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    final newCourses = await _repository.getCourses(page: _page);
    setState(() {
      _courses.addAll(newCourses);
      _page++;
      _isLoading = false;
    });
  }
}
```

## 📝 Documentation Standards

### Code Documentation

```dart
/// Fetches user profile with cache-first strategy
/// 
/// This method优先使用缓存数据提供即时UI更新，
/// 同时在后台获取最新数据并更新缓存。
/// 
/// [userId] - User identifier
/// 
/// Returns [Either<Failure, User>] with success or error
Future<Either<Failure, User>> getProfile(String userId) async {
  // Implementation...
}
```

### API Documentation

```dart
/// POST /api/courses/{id}/enroll
/// 
/// Enroll user in a course
/// 
/// Request Body:
/// ```json
/// {
///   "userId": "uuid",
///   "paymentMethod": "card"
/// }
/// ```
/// 
/// Responses:
/// - 201: Successfully enrolled
/// - 404: Course not found
/// - 409: Already enrolled
Future<Either<Failure, Enrollment>> enrollInCourse(
  String courseId,
  EnrollmentRequest request
) async {
  // Implementation...
}
```

## 🐛 Bug Reporting

### Issue Templates

Use the provided issue templates and include:

1. **Bug Description** - Clear, concise description
2. **Steps to Reproduce** - Detailed reproduction steps
3. **Expected vs Actual** - What should happen vs what happens
4. **Environment** - Flutter version, device, OS version
5. **Screenshots/Logs** - Visual evidence and error logs

### Bug Report Example

```markdown
## Bug Description
App crashes when accessing user profile on Android 13

## Steps to Reproduce
1. Login to app
2. Navigate to Profile tab
3. App crashes immediately

## Expected Behavior
User profile should load and display user information

## Actual Behavior
App crashes with null pointer exception

## Environment
- Flutter: 3.22.0
- Device: Pixel 6 (Android 13)
- App Version: 1.0.0

## Error Log
```
D/FLUTTER(12345): Null check operator used on a null value
D/FLUTTER(12345): #0      UserProfileProvider.loadProfile
```
```

## 🎯 Feature Requests

### Feature Request Template

```markdown
## Feature Description
Implement offline mode for course downloads

## Problem Statement
Students need to access course materials without internet connection

## Proposed Solution
- Add course download functionality
- Cache videos and documents locally
- Sync when connection restored

## Alternative Solutions
- Stream with adaptive quality
- PDF export instead of video

## Additional Context
This feature is critical for students with limited data plans
```

## 📞 Getting Help

### Communication Channels

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General questions and ideas
- **Email** - security@pharmat.app
- **Documentation** - [docs.pharmat.app](https://docs.pharmat.app)

### Response Times

- **Bug Reports** - 24-48 hours
- **Feature Requests** - 3-5 business days
- **General Questions** - 1-2 business days
- **Security Issues** - 24 hours (confidential)

## 🏆 Recognition

### Contributors

We recognize contributors through:

- **Contributors Hall of Fame** in README
- **Release Notes** acknowledgment
- **GitHub Contributors** page
- **Annual Contributor Awards**

### Contribution Levels

- **🥉 Bronze** - 1-10 meaningful contributions
- **🥈 Silver** - 11-50 meaningful contributions  
- **🥇 Gold** - 51+ meaningful contributions
- **💎 Diamond** - Exceptional impact on project

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to pharmaT!** 🎉

Your contributions help make pharmacy education more accessible and effective for students worldwide.
