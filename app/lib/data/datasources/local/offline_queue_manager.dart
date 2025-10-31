import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../datasources/local/database_helper.dart';

/// Represents a queued operation to be executed when online
class QueuedOperation {
  final String operationId;
  final String operationType; // 'create', 'update', 'delete'
  final String entityType; // 'user', 'course', 'session', 'message', etc.
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final DateTime? lastRetryAt;

  QueuedOperation({
    required this.operationId,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  Map<String, dynamic> toJson() => {
        'operation_id': operationId,
        'operation_type': operationType,
        'entity_type': entityType,
        'entity_id': entityId,
        'data': jsonEncode(data),
        'timestamp': timestamp.toIso8601String(),
        'retry_count': retryCount,
        'last_retry_at': lastRetryAt?.toIso8601String(),
      };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) => QueuedOperation(
        operationId: json['operation_id'],
        operationType: json['operation_type'],
        entityType: json['entity_type'],
        entityId: json['entity_id'],
        data: jsonDecode(json['data']),
        timestamp: DateTime.parse(json['timestamp']),
        retryCount: json['retry_count'] ?? 0,
        lastRetryAt: json['last_retry_at'] != null 
            ? DateTime.parse(json['last_retry_at']) 
            : null,
      );

  QueuedOperation copyWith({
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return QueuedOperation(
      operationId: operationId,
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

/// Manages offline write operations queue
/// Persists operations to SQLite and syncs when online
class OfflineQueueManager {
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isProcessing = false;
  final int _maxRetries = 3;
  final Duration _retryDelay = const Duration(minutes: 5);

  /// Initialize offline queue table
  Future<void> initialize() async {
    final db = await DatabaseHelper.instance.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_queue (
        operation_id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at TEXT
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_offline_queue_timestamp 
      ON offline_queue(timestamp)
    ''');
  }

  /// Add operation to queue
  Future<void> addToQueue(QueuedOperation operation) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.insert(
      'offline_queue',
      operation.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all queued operations
  Future<List<QueuedOperation>> getQueuedOperations() async {
    final db = await DatabaseHelper.instance.database;
    
    final results = await db.query(
      'offline_queue',
      orderBy: 'timestamp ASC',
    );

    return results.map((json) => QueuedOperation.fromJson(json)).toList();
  }

  /// Get queued operations by entity type
  Future<List<QueuedOperation>> getOperationsByEntity(String entityType) async {
    final db = await DatabaseHelper.instance.database;
    
    final results = await db.query(
      'offline_queue',
      where: 'entity_type = ?',
      whereArgs: [entityType],
      orderBy: 'timestamp ASC',
    );

    return results.map((json) => QueuedOperation.fromJson(json)).toList();
  }

  /// Remove operation from queue
  Future<void> removeFromQueue(String operationId) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.delete(
      'offline_queue',
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
  }

  /// Update operation retry count
  Future<void> updateRetryCount(QueuedOperation operation) async {
    final db = await DatabaseHelper.instance.database;
    
    final updated = operation.copyWith(
      retryCount: operation.retryCount + 1,
      lastRetryAt: DateTime.now(),
    );

    await db.update(
      'offline_queue',
      updated.toJson(),
      where: 'operation_id = ?',
      whereArgs: [operation.operationId],
    );
  }

  /// Check if online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Process queue (execute all pending operations)
  Future<ProcessResult> processQueue() async {
    if (_isProcessing) {
      return ProcessResult(
        success: false,
        message: 'Queue processing already in progress',
      );
    }

    if (!await isOnline()) {
      return ProcessResult(
        success: false,
        message: 'Device is offline',
      );
    }

    _isProcessing = true;

    try {
      final operations = await getQueuedOperations();
      
      if (operations.isEmpty) {
        return ProcessResult(
          success: true,
          message: 'Queue is empty',
        );
      }

      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];

      for (final operation in operations) {
        try {
          // Skip if max retries exceeded
          if (operation.retryCount >= _maxRetries) {
            errors.add(
              'Operation ${operation.operationId} exceeded max retries (${_maxRetries})',
            );
            await removeFromQueue(operation.operationId);
            failureCount++;
            continue;
          }

          // Check if enough time has passed since last retry
          if (operation.lastRetryAt != null) {
            final timeSinceLastRetry = DateTime.now().difference(operation.lastRetryAt!);
            if (timeSinceLastRetry < _retryDelay) {
              continue; // Skip this operation for now
            }
          }

          // Execute operation
          final success = await _executeOperation(operation);

          if (success) {
            await removeFromQueue(operation.operationId);
            successCount++;
          } else {
            await updateRetryCount(operation);
            failureCount++;
            errors.add('Failed to execute operation ${operation.operationId}');
          }
        } catch (e) {
          await updateRetryCount(operation);
          failureCount++;
          errors.add('Error executing operation ${operation.operationId}: $e');
        }
      }

      return ProcessResult(
        success: failureCount == 0,
        message: 'Processed $successCount operations, $failureCount failed',
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Execute a single queued operation
  Future<bool> _executeOperation(QueuedOperation operation) async {
    // This method should be implemented to call the appropriate repository method
    // based on the operation type and entity type
    
    // For now, we'll return true to indicate the operation should be removed from queue
    // In a real implementation, you would call the actual repository methods here
    
    // Example implementation:
    // switch (operation.entityType) {
    //   case 'user':
    //     return await _executeUserOperation(operation);
    //   case 'course':
    //     return await _executeCourseOperation(operation);
    //   case 'session':
    //     return await _executeSessionOperation(operation);
    //   case 'message':
    //     return await _executeMessageOperation(operation);
    //   default:
    //     return false;
    // }
    
    return true; // Placeholder
  }

  /// Clear entire queue
  Future<void> clearQueue() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('offline_queue');
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM offline_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get operations that exceeded max retries
  Future<List<QueuedOperation>> getFailedOperations() async {
    final db = await DatabaseHelper.instance.database;
    
    final results = await db.query(
      'offline_queue',
      where: 'retry_count >= ?',
      whereArgs: [_maxRetries],
    );

    return results.map((json) => QueuedOperation.fromJson(json)).toList();
  }

  /// Remove failed operations (exceeded max retries)
  Future<void> clearFailedOperations() async {
    final db = await DatabaseHelper.instance.database;
    
    await db.delete(
      'offline_queue',
      where: 'retry_count >= ?',
      whereArgs: [_maxRetries],
    );
  }

  /// Start automatic queue processing on connectivity changes
  void startAutoProcessing() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // Device came online, process queue
        processQueue();
      }
    });
  }
}

/// Result of queue processing
class ProcessResult {
  final bool success;
  final String message;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  ProcessResult({
    required this.success,
    required this.message,
    this.successCount = 0,
    this.failureCount = 0,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'ProcessResult(success: $success, message: $message, '
        'successCount: $successCount, failureCount: $failureCount, '
        'errors: ${errors.length})';
  }
}
