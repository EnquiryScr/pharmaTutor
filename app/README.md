# Flutter MVVM Tutoring Platform Architecture

## Overview

This is a complete Flutter project implementing MVVM (Model-View-ViewModel) architecture with Repository pattern for a tutoring platform. The architecture is designed for scalability, maintainability, and testability.

## Architecture Components

### 1. Directory Structure

```
lib/
├── core/                          # Core utilities and base classes
│   ├── constants/                 # App constants and configuration
│   ├── utils/                     # Utility classes and helpers
│   ├── network/                   # Network layer components
│   ├── widgets/                   # Base UI widgets
│   ├── extensions/                # Dart extensions
│   ├── navigation/                # Navigation configuration
│   └── theme/                     # App theming
├── data/                          # Data layer
│   ├── models/                    # Data models
│   ├── datasources/               # Data sources (local/remote)
│   ├── repositories/              # Repository implementations
│   └── services/                  # Business logic services
├── domain/                        # Domain layer
│   ├── entities/                  # Domain entities
│   ├── repositories/              # Repository interfaces
│   └── usecases/                  # Use cases
├── presentation/                  # Presentation layer
│   ├── pages/                     # UI pages
│   ├── widgets/                   # Custom widgets
│   ├── viewmodels/                # ViewModels
│   └── providers/                 # State management providers
└── main.dart                      # App entry point
```

### 2. Key Architecture Patterns

#### MVVM (Model-View-ViewModel)
- **Model**: Data structures and business entities
- **View**: Flutter widgets and pages
- **ViewModel**: State management and business logic

#### Repository Pattern
- **Interface**: Defines contracts for data access
- **Implementation**: Concrete data source implementations
- **Abstraction**: Hides data source complexity from upper layers

#### Dependency Injection
- **GetIt**: Service locator for dependency management
- **Modular**: Easy testing and module replacement

### 3. Core Components

#### Base Classes

##### BaseViewModel
```dart
abstract class BaseViewModel with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // State management methods
  void setLoading(bool loading);
  void setError(String? error);
  void setSuccess(String? message);
  void clearMessages();
  
  // Async operation wrapper with error handling
  Future<T?> executeAsync<T>(Future<T> Function() operation);
}
```

##### BaseView
```dart
abstract class BaseView<T extends BaseViewModel> extends ConsumerStatefulWidget {
  // Provides lifecycle management and common UI patterns
}
```

##### BaseModel
```dart
abstract class BaseModel extends Equatable {
  // Common model functionality with JSON serialization
}
```

#### Repository Interfaces
```dart
abstract class IRepository<T extends BaseModel> {
  Future<Either<Failure, T>> create(T entity);
  Future<Either<Failure, T>> getById(String id);
  Future<Either<Failure, List<T>>> getAll();
  Future<Either<Failure, T>> update(String id, T entity);
  Future<Either<Failure, bool>> delete(String id);
}
```

### 4. Data Models

#### User Models
- `UserModel`: Core user data
- `TutorModel`: Extended user model for tutors
- `LocationModel`: Geographic data

#### Session Models
- `SessionModel`: Tutoring session data
- `SessionFeedback`: Session rating and comments
- `AvailabilitySlot`: Tutor availability

#### Course Models
- `CourseModel`: Course information
- `CourseContent`: Individual lessons/materials
- `CourseEnrollment`: Student enrollment data

### 5. State Management

#### Provider + Riverpod
- **Provider**: Basic dependency injection
- **StateNotifier**: Complex state management
- **AsyncValue**: Loading/error states

#### ViewModel Features
- Loading states
- Error handling
- Success messages
- Data pagination
- Refresh capabilities

### 6. Navigation

#### GoRouter Integration
```dart
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginPage()),
    GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
  ],
);
```

#### Navigation Helper
```dart
class NavigationHelper {
  static void goToLogin();
  static void goToHome();
  static void showSnackBar(String message);
  static void showDialog(Widget child);
}
```

### 7. Error Handling

#### ApiException Types
- `networkError`: Network connectivity issues
- `timeout`: Request timeout
- `serverError`: Server-side errors
- `cancelled`: Request cancelled
- `unknown`: Unexpected errors

#### Validation System
- `EmailValidator`: Email format validation
- `PasswordValidator`: Password strength validation
- `PhoneValidator`: Phone number validation
- `ComposedValidator`: Multiple validators combination

### 8. UI Components

#### Base Widgets
- `BaseButton`: Consistent button styling
- `BaseCard`: Card component with consistent styling
- `BaseInputField`: Form input with validation
- `BaseLoading`: Loading indicator
- `BaseEmptyState`: Empty state display
- `BaseErrorState`: Error state display

#### Design System
- Consistent spacing (`Spacing` class)
- Standard colors (`Colors` class)
- Typography scale (`FontSizes`, `FontWeights`)
- Border radius (`BorderRadius` class)

### 9. Services

#### Business Logic Services
- `AuthService`: Authentication management
- `UserService`: User profile operations
- `TutorService`: Tutor-related operations
- `SessionService`: Session management
- `CourseService`: Course operations
- `MessageService`: Messaging functionality

### 10. API Integration

#### API Client Structure
```dart
class ApiClient {
  Future<T> get<T>(String endpoint);
  Future<T> post<T>(String endpoint, dynamic data);
  Future<T> put<T>(String endpoint, dynamic data);
  Future<T> delete<T>(String endpoint);
  Future<T> uploadFile<T>(String endpoint, String filePath);
}
```

#### Specific API Clients
- `AuthApiClient`: Authentication endpoints
- `UserApiClient`: User management
- `TutorApiClient`: Tutor operations
- `SessionApiClient`: Session management

### 11. Dependency Injection

#### Service Locator Setup
```dart
final GetIt serviceLocator = GetIt.instance;

Future<void> initializeDependencies() async {
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register API clients
  serviceLocator.registerLazySingleton<Dio>(() => _createDioClient());
  serviceLocator.registerLazySingleton<ApiClient>(() => ApiClient(serviceLocator<Dio>()));

  // Register repositories
  serviceLocator.registerLazySingleton<IAuthRepository>(() => 
    AuthRepositoryImpl(serviceLocator<AuthApiClient>()));

  // Register use cases
  serviceLocator.registerLazySingleton(() => 
    LoginUseCase(serviceLocator<IAuthRepository>()));

  // Register services
  serviceLocator.registerLazySingleton(() => 
    AuthService(serviceLocator<IAuthRepository>()));
}
```

### 12. Testing Strategy

#### Unit Tests
- ViewModel logic testing
- Use case testing
- Repository testing
- Service testing

#### Widget Tests
- UI component testing
- Navigation testing
- Form validation testing

#### Integration Tests
- End-to-end user flows
- API integration testing

## Key Features

### 1. Scalability
- Modular architecture
- Clear separation of concerns
- Easy to add new features

### 2. Maintainability
- Consistent code patterns
- Clear naming conventions
- Comprehensive documentation

### 3. Testability
- Dependency injection
- Mock-friendly design
- Clear interfaces

### 4. User Experience
- Consistent UI/UX
- Loading states
- Error handling
- Navigation flow

### 5. Developer Experience
- Clear project structure
- Helpful error messages
- Code generation support
- IDE integration

## Technology Stack

### Core Flutter
- Flutter SDK
- Dart language

### State Management
- Provider
- Riverpod
- ChangeNotifier

### Networking
- Dio HTTP client
- JSON serialization
- Interceptors

### Local Storage
- SharedPreferences
- Hive (NoSQL database)
- SQLite

### Navigation
- GoRouter
- Deep linking support

### UI/UX
- Material Design 3
- Custom widgets
- Responsive design
- ScreenUtil for scaling

### Development Tools
- Build runner
- JSON annotation
- Mockito for testing

## Best Practices

### 1. Code Organization
- Follow folder structure conventions
- Keep files focused and small
- Use meaningful names

### 2. Error Handling
- Always handle async operations
- Provide user-friendly error messages
- Log errors for debugging

### 3. Performance
- Use lazy loading where appropriate
- Implement pagination for large datasets
- Cache frequently used data

### 4. Security
- Validate all inputs
- Use secure storage for sensitive data
- Implement proper authentication

### 5. Accessibility
- Support screen readers
- Use semantic widgets
- Provide proper navigation order

## Getting Started

1. **Clone the repository**
2. **Install dependencies**: `flutter pub get`
3. **Run the app**: `flutter run`
4. **Run tests**: `flutter test`
5. **Build for production**: `flutter build apk` or `flutter build ios`

## Development Workflow

1. **Create feature branch**
2. **Implement ViewModels and Use Cases**
3. **Create/update data models**
4. **Implement UI components**
5. **Write tests**
6. **Create pull request**
7. **Code review**
8. **Merge to main**

This architecture provides a solid foundation for building a scalable and maintainable Flutter tutoring platform application.