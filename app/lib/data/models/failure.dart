/// Represents a failure in the data layer
class Failure {
  final String message;
  final Exception? exception;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.exception,
    this.stackTrace,
  });

  @override
  String toString() => 'Failure: $message${exception != null ? ' ($exception)' : ''}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network error occurred'})
      : super(message: message);
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure({String message = 'Server error occurred'})
      : super(message: message);
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache error occurred'})
      : super(message: message);
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({String message = 'Authentication failed'})
      : super(message: message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({String message = 'Validation failed'})
      : super(message: message);
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure({String message = 'Resource not found'})
      : super(message: message);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure({String message = 'Permission denied'})
      : super(message: message);
}
