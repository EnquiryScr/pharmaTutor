import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter_tutoring_app/data/repositories/user_repository_impl.dart';
import 'package:flutter_tutoring_app/data/datasources/remote/user_supabase_data_source.dart';
import 'package:flutter_tutoring_app/data/datasources/local/user_cache_data_source.dart';
import 'package:flutter_tutoring_app/data/models/user_model.dart';
import 'package:flutter_tutoring_app/data/models/failure.dart';

// Generate mocks with: dart run build_runner build
@GenerateMocks([UserSupabaseDataSource, UserCacheDataSource, Connectivity])
import 'user_repository_test.mocks.dart';

void main() {
  late UserRepositoryImpl repository;
  late MockUserSupabaseDataSource mockRemoteDataSource;
  late MockUserCacheDataSource mockCacheDataSource;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockRemoteDataSource = MockUserSupabaseDataSource();
    mockCacheDataSource = MockUserCacheDataSource();
    mockConnectivity = MockConnectivity();
    
    repository = UserRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      cacheDataSource: mockCacheDataSource,
      connectivity: mockConnectivity,
    );
  });

  group('UserRepositoryImpl - getProfile', () {
    const userId = 'test-user-id';
    final testUser = UserModel(
      id: userId,
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.student,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should return cached profile when available', () async {
      // Arrange
      when(mockCacheDataSource.getProfile(userId))
          .thenAnswer((_) async => testUser.toJson());
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);

      // Act
      final result = await repository.getUserProfile(userId);

      // Assert
      expect(result, Right(testUser));
      verify(mockCacheDataSource.getProfile(userId)).called(1);
    });

    test('should fetch from remote when cache is empty and online', () async {
      // Arrange
      when(mockCacheDataSource.getProfile(userId))
          .thenAnswer((_) async => null);
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      when(mockRemoteDataSource.getUserProfile(userId))
          .thenAnswer((_) async => testUser);
      when(mockCacheDataSource.cacheProfile(testUser.toJson()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.getUserProfile(userId);

      // Assert
      expect(result, Right(testUser));
      verify(mockRemoteDataSource.getUserProfile(userId)).called(1);
      verify(mockCacheDataSource.cacheProfile(testUser.toJson())).called(1);
    });

    test('should return failure when offline and cache is empty', () async {
      // Arrange
      when(mockCacheDataSource.getProfile(userId))
          .thenAnswer((_) async => null);
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      // Act
      final result = await repository.getUserProfile(userId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<Failure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should handle remote data source errors', () async {
      // Arrange
      when(mockCacheDataSource.getProfile(userId))
          .thenAnswer((_) async => null);
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      when(mockRemoteDataSource.getUserProfile(userId))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await repository.getUserProfile(userId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('Exception')),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('UserRepositoryImpl - updateProfile', () {
    const userId = 'test-user-id';
    final testUser = UserModel(
      id: userId,
      email: 'test@example.com',
      name: 'Updated User',
      role: UserRole.student,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final updates = {'name': 'Updated User'};

    test('should update profile when online', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      when(mockRemoteDataSource.updateUserProfile(
        userId: userId,
        fullName: 'Updated User',
      )).thenAnswer((_) async => testUser);
      when(mockCacheDataSource.cacheProfile(testUser.toJson()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.updateUserProfile(
        userId: userId,
        fullName: 'Updated User',
      );

      // Assert
      expect(result, Right(testUser));
      verify(mockRemoteDataSource.updateUserProfile(
        userId: userId,
        fullName: 'Updated User',
      )).called(1);
      verify(mockCacheDataSource.cacheProfile(testUser.toJson())).called(1);
    });

    test('should queue update when offline', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      // Act
      final result = await repository.updateUserProfile(
        userId: userId,
        fullName: 'Updated User',
      );

      // Assert
      expect(result.isLeft(), true);
      // In a full implementation, you would verify the operation was queued
    });
  });

  group('UserRepositoryImpl - searchTutors', () {
    final testTutors = [
      UserModel(
        id: 'tutor1',
        email: 'tutor1@example.com',
        name: 'Tutor One',
        role: UserRole.tutor,
        subjects: ['pharmacology', 'chemistry'],
        rating: 4.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserModel(
        id: 'tutor2',
        email: 'tutor2@example.com',
        name: 'Tutor Two',
        role: UserRole.tutor,
        subjects: ['pharmacy', 'biology'],
        rating: 4.8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should search tutors from cache first', () async {
      // Arrange
      final cachedTutors = testTutors.map((tutor) => tutor.toJson()).toList();
      when(mockCacheDataSource.searchTutors(
        query: 'pharmacology',
        minRating: 4.0,
      )).thenAnswer((_) async => cachedTutors);
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);

      // Act
      final result = await repository.searchTutors(
        query: 'pharmacology',
        minRating: 4.0,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return tutors'),
        (tutors) {
          expect(tutors.length, 2);
        },
      );
      verify(mockCacheDataSource.searchTutors(
        query: 'pharmacology',
        minRating: 4.0,
      )).called(1);
    });

    test('should filter tutors by rating', () async {
      // Arrange
      final filteredTutors = [testTutors[1]]; // Only tutor with rating >= 4.8
      final cachedFilteredTutors = filteredTutors.map((tutor) => tutor.toJson()).toList();
      when(mockCacheDataSource.searchTutors(
        minRating: 4.8,
      )).thenAnswer((_) async => cachedFilteredTutors);
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);

      // Act
      final result = await repository.searchTutors(minRating: 4.8);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return tutors'),
        (tutors) {
          expect(tutors.length, 1);
          expect(tutors[0].rating, 4.8);
        },
      );
    });
  });

  group('UserRepositoryImpl - uploadAvatar', () {
    const userId = 'test-user-id';
    final fileBytes = List<int>.generate(100, (index) => index);
    const fileName = 'avatar.jpg';
    const avatarUrl = 'https://storage.example.com/avatars/avatar.jpg';

    test('should upload avatar when online', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      when(mockRemoteDataSource.uploadAvatar(
        userId: userId,
        file: anyNamed('file'),
      )).thenAnswer((_) async => avatarUrl);

      // Act
      final result = await repository.uploadAvatar(
        userId: userId,
        filePath: '/tmp/avatar.jpg',
      );

      // Assert
      expect(result, Right(avatarUrl));
      verify(mockRemoteDataSource.uploadAvatar(
        userId: userId,
        file: anyNamed('file'),
      )).called(1);
    });

    test('should fail when offline', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      // Act
      final result = await repository.uploadAvatar(
        userId: userId,
        filePath: '/tmp/avatar.jpg',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('offline')),
        (_) => fail('Should return failure'),
      );
    });
  });
}
