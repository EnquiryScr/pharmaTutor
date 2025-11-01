import 'package:equatable/equatable.dart';

/// Base model class that provides common functionality for all domain models
abstract class BaseModel extends Equatable {
  const BaseModel();

  /// Convert the model to JSON map
  /// Override in subclasses and annotate with @JsonSerializable if needed
  Map<String, dynamic> toJson() {
    throw UnimplementedError('Subclasses must implement toJson()');
  }

  /// Create a model instance from JSON map
  /// This should be implemented by each model class
  /// Override in subclasses and annotate with @JsonSerializable if needed
  static T fromJson<T extends BaseModel>(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must implement fromJson()');
  }

  /// Create a copy of the model with updated properties
  /// This should be implemented by each model class with copyWith method
  T copyWith() {
    throw UnimplementedError('Subclasses must implement copyWith()');
  }

  /// Validate the model data
  /// Return true if valid, false otherwise
  bool isValid() {
    return true; // Override in child classes for specific validation
  }

  /// Get validation errors
  /// Return a map of field names to error messages
  Map<String, String> getValidationErrors() {
    return {}; // Override in child classes for specific validation
  }
}

/// Generic base model for models with ID
abstract class BaseModelWithId extends BaseModel {
  const BaseModelWithId();

  /// Unique identifier for the model
  String get id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is BaseModelWithId && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  List<Object?> get props => [id];
}

/// Generic response wrapper for API responses
class ApiResponse<T extends BaseModel> extends BaseModel {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  /// Create success response
  factory ApiResponse.success({
    T? data,
    String? message,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    String? error,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Create response from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'],
      error: json['error'],
      statusCode: json['statusCode'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
      'message': message,
      'error': error,
      'statusCode': statusCode,
    };
  }

  @override
  List<Object?> get props => [success, data, message, error, statusCode];
}

/// Generic list response wrapper
class ApiListResponse<T extends BaseModel> extends BaseModel {
  final bool success;
  final List<T>? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final int? totalCount;
  final int? page;
  final int? perPage;

  const ApiListResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.totalCount,
    this.page,
    this.perPage,
  });

  /// Create success response
  factory ApiListResponse.success({
    List<T>? data,
    String? message,
    int? totalCount,
    int? page,
    int? perPage,
  }) {
    return ApiListResponse<T>(
      success: true,
      data: data,
      message: message,
      totalCount: totalCount,
      page: page,
      perPage: perPage,
    );
  }

  /// Create error response
  factory ApiListResponse.error({
    String? error,
    String? message,
    int? statusCode,
  }) {
    return ApiListResponse<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Create response from JSON
  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiListResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList()
          : null,
      message: json['message'],
      error: json['error'],
      statusCode: json['statusCode'],
      totalCount: json['totalCount'],
      page: json['page'],
      perPage: json['perPage'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.map((item) => item.toJson()).toList(),
      'message': message,
      'error': error,
      'statusCode': statusCode,
      'totalCount': totalCount,
      'page': page,
      'perPage': perPage,
    };
  }

  @override
  List<Object?> get props => [
        success,
        data,
        message,
        error,
        statusCode,
        totalCount,
        page,
        perPage,
      ];
}

/// Base model for pagination
abstract class PaginatedModel extends BaseModel {
  const PaginatedModel();

  /// Current page number (1-based)
  int get currentPage;

  /// Total number of pages
  int? get totalPages;

  /// Total number of items
  int? get totalItems;

  /// Number of items per page
  int? get itemsPerPage;

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => totalPages != null && currentPage >= totalPages!;

  /// Get next page number (if available)
  int? get nextPage => isLastPage ? null : currentPage + 1;

  /// Get previous page number (if available)
  int? get previousPage => isFirstPage ? null : currentPage - 1;

  /// Check if pagination information is valid
  bool get isValidPagination {
    return currentPage > 0 &&
           (totalPages == null || totalPages! > 0) &&
           (totalItems == null || totalItems! >= 0);
  }
}

/// Base model for audit trail (created/modified timestamps)
abstract class AuditableModel extends BaseModel {
  const AuditableModel();

  /// When the record was created
  DateTime? get createdAt;

  /// When the record was last updated
  DateTime? get updatedAt;

  /// Who created the record
  String? get createdBy;

  /// Who last updated the record
  String? get updatedBy;

  /// Check if the model has been modified since creation
  bool get isModified {
    return createdAt != null &&
           updatedAt != null &&
           createdAt!.isBefore(updatedAt!);
  }

  /// Get the age of the record in days
  int? get ageInDays {
    if (createdAt == null) return null;
    final now = DateTime.now();
    return now.difference(createdAt!).inDays;
  }
}

/// Extension for DateTime utilities
extension DateTimeExtensions on DateTime? {
  /// Check if the datetime is in the past
  bool get isPast {
    if (this == null) return false;
    return DateTime.now().isAfter(this!);
  }

  /// Check if the datetime is in the future
  bool get isFuture {
    if (this == null) return false;
    return DateTime.now().isBefore(this!);
  }

  /// Format the datetime in a readable way
  String get formatted {
    if (this == null) return '';
    return '${this!.day}/${this!.month}/${this!.year} ${this!.hour}:${this!.minute.toString().padLeft(2, '0')}';
  }

  /// Get relative time (e.g., "2 hours ago")
  String get relativeTime {
    if (this == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(this!);
    
    if (difference.inDays > 7) {
      return formatted;
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Extension for List operations
extension ListExtensions<T extends BaseModel> on List<T> {
  /// Find an item by ID (if model has id)
  T? findById(String id) {
    try {
      return firstWhere((item) {
        if (item is BaseModelWithId) {
          return (item as BaseModelWithId).id == id;
        }
        return false;
      });
    } catch (e) {
      return null;
    }
  }

  /// Remove an item by ID (if model has id)
  void removeById(String id) {
    removeWhere((item) {
      if (item is BaseModelWithId) {
        return (item as BaseModelWithId).id == id;
      }
      return false;
    });
  }

  /// Update an item by ID (if model has id)
  void updateById(String id, T newItem) {
    final index = indexWhere((item) {
      if (item is BaseModelWithId) {
        return (item as BaseModelWithId).id == id;
      }
      return false;
    });
    
    if (index != -1) {
      this[index] = newItem;
    }
  }

  /// Sort the list by a key selector
  void sortBy<K>(K Function(T) keySelector, {bool ascending = true}) {
    sort((a, b) {
      final aKey = keySelector(a);
      final bKey = keySelector(b);
      
      if (ascending) {
        return Comparable.compare(aKey, bKey);
      } else {
        return Comparable.compare(bKey, aKey);
      }
    });
  }
}