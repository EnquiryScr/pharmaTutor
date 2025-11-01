import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/repositories/irepository.dart';
import '../models/session_model.dart';
import '../datasources/remote/session_supabase_data_source.dart';
import '../datasources/local/session_cache_data_source.dart';

/// Session repository implementing offline-first pattern
class SessionRepositoryImpl implements IOfflineFirstRepository<SessionModel> {
  final SessionSupabaseDataSource _remoteDataSource;
  final SessionCacheDataSource _cacheDataSource;
  final Connectivity _connectivity;

  SessionRepositoryImpl({
    required SessionSupabaseDataSource remoteDataSource,
    required SessionCacheDataSource cacheDataSource,
    Connectivity? connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _cacheDataSource = cacheDataSource,
        _connectivity = connectivity ?? Connectivity();

  @override
  String get repositoryName => 'SessionRepository';

  Future<bool> get _isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Future<Either<Failure, SessionModel>> getById(String id) async {
    try {
      final cachedSession = await _cacheDataSource.getSession(id);
      
      if (cachedSession != null) {
        final sessionModel = SessionModel.fromJson(cachedSession);
        
        if (await _isOnline) {
          _updateCacheInBackground(id);
        }
        
        return Right(sessionModel);
      }

      if (await _isOnline) {
        final remoteSession = await _remoteDataSource.getSession(id);
        await _cacheDataSource.cacheSession(remoteSession);
        
        return Right(SessionModel.fromJson(remoteSession));
      } else {
        return Left(Failure(
          message: 'Session not found in cache and device is offline',
          code: 'OFFLINE_NO_CACHE',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get session: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateCacheInBackground(String sessionId) async {
    try {
      final remoteSession = await _remoteDataSource.getSession(sessionId);
      await _cacheDataSource.updateSession(sessionId, remoteSession);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<Either<Failure, SessionModel>> create(SessionModel entity) async {
    try {
      if (await _isOnline) {
        final sessionData = entity.toJson();
        final createdSession = await _remoteDataSource.createSession(sessionData);
        
        await _cacheDataSource.cacheSession(createdSession);
        
        return Right(SessionModel.fromJson(createdSession));
      } else {
        return Left(Failure(
          message: 'Cannot create session while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to create session: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, SessionModel>> update(String id, SessionModel entity) async {
    try {
      final updateData = entity.toJson();
      
      if (await _isOnline) {
        final updatedSession = await _remoteDataSource.updateSession(id, updateData);
        await _cacheDataSource.updateSession(id, updatedSession);
        
        return Right(SessionModel.fromJson(updatedSession));
      } else {
        await _cacheDataSource.updateSession(id, updateData);
        return Right(entity);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to update session: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> delete(String id) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.deleteSession(id);
        await _cacheDataSource.deleteSession(id);
        
        return const Right(true);
      } else {
        return Left(Failure(
          message: 'Cannot delete session while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to delete session: $e',
        exception: e,
      ));
    }
  }

  /// Get tutor's sessions
  Future<Either<Failure, List<SessionModel>>> getTutorSessions(
    String tutorId, {
    String? status,
  }) async {
    try {
      final cachedSessions = await _cacheDataSource.getTutorSessions(tutorId, status: status);
      
      if (cachedSessions.isNotEmpty) {
        final sessionModels = cachedSessions
            .map((data) => SessionModel.fromJson(data))
            .toList();
        
        if (await _isOnline) {
          _updateTutorSessionsInBackground(tutorId, status: status);
        }
        
        return Right(sessionModels);
      }

      if (await _isOnline) {
        final remoteSessions = await _remoteDataSource.getTutorSessions(tutorId, status: status);
        
        for (final session in remoteSessions) {
          await _cacheDataSource.cacheSession(session);
        }
        
        return Right(remoteSessions.map((data) => SessionModel.fromJson(data)).toList());
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get tutor sessions: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateTutorSessionsInBackground(String tutorId, {String? status}) async {
    try {
      final remoteSessions = await _remoteDataSource.getTutorSessions(tutorId, status: status);
      for (final session in remoteSessions) {
        await _cacheDataSource.updateSession(session['session_id'], session);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get student's sessions
  Future<Either<Failure, List<SessionModel>>> getStudentSessions(
    String studentId, {
    String? status,
  }) async {
    try {
      final cachedSessions = await _cacheDataSource.getStudentSessions(studentId, status: status);
      
      if (cachedSessions.isNotEmpty) {
        final sessionModels = cachedSessions
            .map((data) => SessionModel.fromJson(data))
            .toList();
        
        if (await _isOnline) {
          _updateStudentSessionsInBackground(studentId, status: status);
        }
        
        return Right(sessionModels);
      }

      if (await _isOnline) {
        final remoteSessions = await _remoteDataSource.getStudentSessions(studentId, status: status);
        
        for (final session in remoteSessions) {
          await _cacheDataSource.cacheSession(session);
        }
        
        return Right(remoteSessions.map((data) => SessionModel.fromJson(data)).toList());
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get student sessions: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateStudentSessionsInBackground(String studentId, {String? status}) async {
    try {
      final remoteSessions = await _remoteDataSource.getStudentSessions(studentId, status: status);
      for (final session in remoteSessions) {
        await _cacheDataSource.updateSession(session['session_id'], session);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get upcoming sessions
  Future<Either<Failure, List<SessionModel>>> getUpcomingSessions(
    String userId,
    String role,
  ) async {
    try {
      final cachedSessions = await _cacheDataSource.getUpcomingSessions(userId);
      
      if (cachedSessions.isNotEmpty) {
        final sessionModels = cachedSessions
            .map((data) => SessionModel.fromJson(data))
            .toList();
        
        if (await _isOnline) {
          _updateUpcomingSessionsInBackground(userId, role);
        }
        
        return Right(sessionModels);
      }

      if (await _isOnline) {
        final remoteSessions = await _remoteDataSource.getUpcomingSessions(userId: userId);
        
        for (final session in remoteSessions) {
          await _cacheDataSource.cacheSession(session);
        }
        
        return Right(remoteSessions.map((data) => SessionModel.fromJson(data)).toList());
      } else {
        return Right([]);
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get upcoming sessions: $e',
        exception: e,
      ));
    }
  }

  Future<void> _updateUpcomingSessionsInBackground(String userId, String role) async {
    try {
      final remoteSessions = await _remoteDataSource.getUpcomingSessions(userId: userId);
      for (final session in remoteSessions) {
        await _cacheDataSource.updateSession(session['session_id'], session);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Submit session feedback
  Future<Either<Failure, void>> submitFeedback({
    required String sessionId,
    required int rating,
    String? comment,
  }) async {
    try {
      if (await _isOnline) {
        await _remoteDataSource.submitSessionFeedback(
          sessionId: sessionId,
          rating: rating,
          comment: comment,
        );
        
        await _cacheDataSource.insertSessionFeedback({
          'session_id': sessionId,
          'rating': rating,
          'comment': comment,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        return const Right(null);
      } else {
        return Left(Failure(
          message: 'Cannot submit feedback while offline',
          code: 'OFFLINE_OPERATION',
        ));
      }
    } catch (e) {
      return Left(Failure(
        message: 'Failed to submit feedback: $e',
        exception: e,
      ));
    }
  }

  // Offline-first interface implementation
  
  @override
  Future<Either<Failure, SyncResult<SessionModel>>> syncData() async {
    try {
      if (!await _isOnline) {
        return Left(Failure(
          message: 'Cannot sync while offline',
          code: 'OFFLINE',
        ));
      }

      final cachedSessions = await _cacheDataSource.getAllSessions();
      final syncedItems = <SessionModel>[];
      final failedItems = <String>[];

      for (final cached in cachedSessions) {
        try {
          final sessionId = cached['session_id'] as String;
          final remoteSession = await _remoteDataSource.getSession(sessionId);
          
          await _cacheDataSource.updateSession(sessionId, remoteSession);
          syncedItems.add(SessionModel.fromJson(remoteSession));
        } catch (e) {
          failedItems.add(cached['session_id'] as String);
        }
      }

      return Right(SyncResult(
        syncedItems: syncedItems,
        failedItems: failedItems,
        totalSynced: syncedItems.length,
        totalFailed: failedItems.length,
      ));
    } catch (e) {
      return Left(Failure(
        message: 'Sync failed: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<SessionModel>>> getOfflineData() async {
    try {
      final cachedSessions = await _cacheDataSource.getAllSessions();
      final sessionModels = cachedSessions
          .map((data) => SessionModel.fromJson(data))
          .toList();
      
      return Right(sessionModels);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveOfflineData(List<SessionModel> data) async {
    try {
      for (final session in data) {
        await _cacheDataSource.cacheSession(session.toJson());
      }
      
      return const Right(null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to save offline data: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isDataSynced() async {
    try {
      final cachedSessions = await _cacheDataSource.getAllSessions();
      return Right(cachedSessions.isNotEmpty);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check sync status: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<SessionModel>>> getAll({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final offset = page != null && limit != null ? (page - 1) * limit : 0;
      final cachedSessions = await _cacheDataSource.getAllSessions(
        limit: limit,
        offset: offset,
      );
      
      final sessionModels = cachedSessions
          .map((data) => SessionModel.fromJson(data))
          .toList();
      
      return Right(sessionModels);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to get all sessions: $e',
        exception: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<SessionModel>>> search(String query) async {
    // Search not implemented for sessions
    return getAll();
  }

  @override
  Future<Either<Failure, bool>> exists(String id) async {
    try {
      final session = await _cacheDataSource.getSession(id);
      return Right(session != null);
    } catch (e) {
      return Left(Failure(
        message: 'Failed to check if session exists: $e',
        exception: e,
      ));
    }
  }
}
