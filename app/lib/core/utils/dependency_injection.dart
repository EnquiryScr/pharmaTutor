import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data Sources
import '../data/datasources/local/local_data_source.dart';
import '../data/datasources/remote/api_client.dart';
import '../data/datasources/remote/auth_api_client.dart';
import '../data/datasources/remote/user_api_client.dart';
import '../data/datasources/remote/tutor_api_client.dart';
import '../data/datasources/remote/session_api_client.dart';
import '../data/datasources/remote/course_api_client.dart';
import '../data/datasources/remote/message_api_client.dart';
import '../data/datasources/remote/payment_api_client.dart';
import '../data/datasources/remote/notification_api_client.dart';

// Repositories
import '../domain/repositories/i_domain_repositories.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/repositories/tutor_repository_impl.dart';
import '../data/repositories/subject_repository_impl.dart';
import '../data/repositories/course_repository_impl.dart';
import '../data/repositories/session_repository_impl.dart';
import '../data/repositories/message_repository_impl.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';

// Use Cases
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../domain/usecases/auth/get_current_user_usecase.dart';
import '../domain/usecases/user/get_user_profile_usecase.dart';
import '../domain/usecases/user/update_user_profile_usecase.dart';
import '../domain/usecases/tutor/get_tutors_usecase.dart';
import '../domain/usecases/tutor/get_tutor_details_usecase.dart';
import '../domain/usecases/tutor/book_session_usecase.dart';
import '../domain/usecases/session/get_sessions_usecase.dart';
import '../domain/usecases/session/book_session_usecase.dart';
import '../domain/usecases/session/cancel_session_usecase.dart';
import '../domain/usecases/course/get_courses_usecase.dart';
import '../domain/usecases/course/enroll_course_usecase.dart';
import '../domain/usecases/message/send_message_usecase.dart';
import '../domain/usecases/message/get_conversations_usecase.dart';

// Services
import '../data/services/auth_service.dart';
import '../data/services/user_service.dart';
import '../data/services/tutor_service.dart';
import '../data/services/session_service.dart';
import '../data/services/course_service.dart';
import '../data/services/message_service.dart';
import '../data/services/payment_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/file_service.dart';
import '../data/services/analytics_service.dart';

// ViewModels/Providers
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/user_provider.dart';
import '../presentation/providers/tutor_provider.dart';
import '../presentation/providers/session_provider.dart';
import '../presentation/providers/course_provider.dart';
import '../presentation/providers/message_provider.dart';
import '../presentation/providers/notification_provider.dart';
import '../presentation/providers/payment_provider.dart';

final GetIt serviceLocator = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Initialize GetIt
  await serviceLocator.reset();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

  // Initialize Dio
  serviceLocator.registerLazySingleton<Dio>(() => _createDioClient());

  // Initialize API Clients
  _registerApiClients();

  // Initialize Local Data Sources
  serviceLocator.registerLazySingleton<LocalDataSource>(() => 
    LocalDataSource(sharedPreferences));

  // Initialize Repositories
  _registerRepositories();

  // Initialize Use Cases
  _registerUseCases();

  // Initialize Services
  _registerServices();

  // Initialize Providers/ViewModels
  _registerProviders();
}

Dio _createDioClient() {
  final dio = Dio();
  
  // Base configuration
  dio.options = BaseOptions(
    baseUrl: 'https://api.tutorflow.com/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  // Add interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add authentication token if available
        final token = serviceLocator<SharedPreferences>().getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Handle response
        handler.next(response);
      },
      onError: (error, handler) {
        // Handle errors
        handler.next(error);
      },
    ),
  );

  // Add logging interceptor in debug mode
  // dio.interceptors.add(PrettyDioLogger());

  return dio;
}

void _registerApiClients() {
  // Base API Client
  serviceLocator.registerLazySingleton<ApiClient>(() => 
    ApiClient(serviceLocator<Dio>()));

  // Specific API Clients
  serviceLocator.registerLazySingleton<AuthApiClient>(() => 
    AuthApiClient(serviceLocator<Dio>()));

  serviceLocator.registerLazySingleton<UserApiClient>(() => 
    UserApiClient(serviceLocator<Dio>()));

  serviceLocator.registerLazySingleton<TutorApiClient>(() => 
    TutorApiClient(serviceLocator<Dio>()));

  serviceLocator.registerLazySingleton<SessionApiClient>(() => 
    SessionApiClient(serviceLocator<Dio>()));

  serviceLocator.registerLazySingleton<CourseApiClient>(() => 
    CourseApiClient(serviceLocator<Dio>()));

  serviceLocator.registerLazySingleton<MessageApiClient>(() => 
    MessageApiClient(serviceLocator<Dio>()));

  serviceLocator.registerLazySingleton<PaymentApiClient>(() => 
    PaymentApiClient(serviceLocator<Dio>()));

  serviceLocator.registerLazySingleton<NotificationApiClient>(() => 
    NotificationApiClient(serviceLocator<Dio>()));
}

void _registerRepositories() {
  // Authentication Repository
  serviceLocator.registerLazySingleton<IAuthRepository>(() => 
    AuthRepositoryImpl(
      serviceLocator<AuthApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // User Repository
  serviceLocator.registerLazySingleton<IUserRepository>(() => 
    UserRepositoryImpl(
      serviceLocator<UserApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // Tutor Repository
  serviceLocator.registerLazySingleton<ITutorRepository>(() => 
    TutorRepositoryImpl(
      serviceLocator<TutorApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // Subject Repository
  serviceLocator.registerLazySingleton<ISubjectRepository>(() => 
    SubjectRepositoryImpl(
      serviceLocator<ApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // Course Repository
  serviceLocator.registerLazySingleton<ICourseRepository>(() => 
    CourseRepositoryImpl(
      serviceLocator<CourseApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // Session Repository
  serviceLocator.registerLazySingleton<ISessionRepository>(() => 
    SessionRepositoryImpl(
      serviceLocator<SessionApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // Message Repository
  serviceLocator.registerLazySingleton<IMessageRepository>(() => 
    MessageRepositoryImpl(
      serviceLocator<MessageApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // Payment Repository
  serviceLocator.registerLazySingleton<IPaymentRepository>(() => 
    PaymentRepositoryImpl(
      serviceLocator<PaymentApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // Notification Repository
  serviceLocator.registerLazySingleton<INotificationRepository>(() => 
    NotificationRepositoryImpl(
      serviceLocator<NotificationApiClient>(),
      serviceLocator<LocalDataSource>(),
    ));

  // File Repository
  serviceLocator.registerLazySingleton<IFileRepository>(() => 
    // FileRepositoryImpl would be implemented here
    throw UnimplementedError('FileRepository not implemented yet'));
}

void _registerUseCases() {
  // Authentication Use Cases
  serviceLocator.registerLazySingleton(() => 
    LoginUseCase(serviceLocator<IAuthRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    RegisterUseCase(serviceLocator<IAuthRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    LogoutUseCase(serviceLocator<IAuthRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    GetCurrentUserUseCase(serviceLocator<IAuthRepository>()));

  // User Use Cases
  serviceLocator.registerLazySingleton(() => 
    GetUserProfileUseCase(serviceLocator<IUserRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    UpdateUserProfileUseCase(serviceLocator<IUserRepository>()));

  // Tutor Use Cases
  serviceLocator.registerLazySingleton(() => 
    GetTutorsUseCase(serviceLocator<ITutorRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    GetTutorDetailsUseCase(serviceLocator<ITutorRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    BookSessionUseCase(serviceLocator<ITutorRepository>()));

  // Session Use Cases
  serviceLocator.registerLazySingleton(() => 
    GetSessionsUseCase(serviceLocator<ISessionRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    CancelSessionUseCase(serviceLocator<ISessionRepository>()));

  // Course Use Cases
  serviceLocator.registerLazySingleton(() => 
    GetCoursesUseCase(serviceLocator<ICourseRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    EnrollCourseUseCase(serviceLocator<ICourseRepository>()));

  // Message Use Cases
  serviceLocator.registerLazySingleton(() => 
    SendMessageUseCase(serviceLocator<IMessageRepository>()));
  
  serviceLocator.registerLazySingleton(() => 
    GetConversationsUseCase(serviceLocator<IMessageRepository>()));
}

void _registerServices() {
  serviceLocator.registerLazySingleton(() => 
    AuthService(
      serviceLocator<IAuthRepository>(),
      serviceLocator<SharedPreferences>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    UserService(
      serviceLocator<IUserRepository>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    TutorService(
      serviceLocator<ITutorRepository>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    SessionService(
      serviceLocator<ISessionRepository>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    CourseService(
      serviceLocator<ICourseRepository>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    MessageService(
      serviceLocator<IMessageRepository>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    PaymentService(
      serviceLocator<IPaymentRepository>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    NotificationService(
      serviceLocator<INotificationRepository>(),
    ));

  serviceLocator.registerLazySingleton(() => 
    FileService());

  serviceLocator.registerLazySingleton(() => 
    AnalyticsService());
}

void _registerProviders() {
  // Authentication Provider
  serviceLocator.registerFactory(() => 
    AuthProvider(
      loginUseCase: serviceLocator<LoginUseCase>(),
      registerUseCase: serviceLocator<RegisterUseCase>(),
      logoutUseCase: serviceLocator<LogoutUseCase>(),
      getCurrentUserUseCase: serviceLocator<GetCurrentUserUseCase>(),
      authService: serviceLocator<AuthService>(),
    ));

  // User Provider
  serviceLocator.registerFactory(() => 
    UserProvider(
      getUserProfileUseCase: serviceLocator<GetUserProfileUseCase>(),
      updateUserProfileUseCase: serviceLocator<UpdateUserProfileUseCase>(),
      userService: serviceLocator<UserService>(),
    ));

  // Tutor Provider
  serviceLocator.registerFactory(() => 
    TutorProvider(
      getTutorsUseCase: serviceLocator<GetTutorsUseCase>(),
      getTutorDetailsUseCase: serviceLocator<GetTutorDetailsUseCase>(),
      tutorService: serviceLocator<TutorService>(),
    ));

  // Session Provider
  serviceLocator.registerFactory(() => 
    SessionProvider(
      getSessionsUseCase: serviceLocator<GetSessionsUseCase>(),
      cancelSessionUseCase: serviceLocator<CancelSessionUseCase>(),
      sessionService: serviceLocator<SessionService>(),
    ));

  // Course Provider
  serviceLocator.registerFactory(() => 
    CourseProvider(
      getCoursesUseCase: serviceLocator<GetCoursesUseCase>(),
      enrollCourseUseCase: serviceLocator<EnrollCourseUseCase>(),
      courseService: serviceLocator<CourseService>(),
    ));

  // Message Provider
  serviceLocator.registerFactory(() => 
    MessageProvider(
      sendMessageUseCase: serviceLocator<SendMessageUseCase>(),
      getConversationsUseCase: serviceLocator<GetConversationsUseCase>(),
      messageService: serviceLocator<MessageService>(),
    ));

  // Notification Provider
  serviceLocator.registerFactory(() => 
    NotificationProvider(
      notificationService: serviceLocator<NotificationService>(),
    ));

  // Payment Provider
  serviceLocator.registerFactory(() => 
    PaymentProvider(
      paymentService: serviceLocator<PaymentService>(),
    ));
}

/// Helper function to get a service instance
T getService<T>() {
  return serviceLocator<T>();
}

/// Helper function to reset service locator (useful for testing)
Future<void> resetServiceLocator() async {
  await serviceLocator.reset();
}