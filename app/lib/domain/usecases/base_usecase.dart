import 'package:dartz/dartz.dart';
import 'package:flutter_tutoring_app/data/models/failure.dart';

/// Abstract base class for all use cases
abstract class BaseUseCase<T, R> {
  /// Execute the use case with given parameters
  Future<Either<Failure, R>> execute(T params);
}

/// Parameters base class
abstract class BaseParams {
  const BaseParams();
}

/// Generic use case for operations that don't require parameters
abstract class BaseUseCaseNoParams<R> {
  /// Execute the use case without parameters
  Future<Either<Failure, R>> execute();
}