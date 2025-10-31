import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:pharmaT/data/datasources/local/offline_queue_manager.dart';
import 'package:pharmaT/data/datasources/local/database_helper.dart';

void main() {
  late OfflineQueueManager queueManager;

  setUp(() async {
    queueManager = OfflineQueueManager();
    await queueManager.initialize();
    await queueManager.clearQueue(); // Clear any existing queue items
  });

  tearDown(() async {
    await queueManager.clearQueue();
  });

  group('OfflineQueueManager - Queue Operations', () {
    test('should add operation to queue', () async {
      // Arrange
      final operation = QueuedOperation(
        operationId: 'op-1',
        operationType: 'create',
        entityType: 'message',
        entityId: 'msg-1',
        data: {'text': 'Hello', 'senderId': 'user-1'},
        timestamp: DateTime.now(),
      );

      // Act
      await queueManager.addToQueue(operation);
      final queueSize = await queueManager.getQueueSize();
      final operations = await queueManager.getQueuedOperations();

      // Assert
      expect(queueSize, 1);
      expect(operations.length, 1);
      expect(operations[0].operationId, 'op-1');
      expect(operations[0].operationType, 'create');
      expect(operations[0].entityType, 'message');
    });

    test('should remove operation from queue', () async {
      // Arrange
      final operation = QueuedOperation(
        operationId: 'op-1',
        operationType: 'update',
        entityType: 'session',
        entityId: 'session-1',
        data: {'status': 'completed'},
        timestamp: DateTime.now(),
      );
      await queueManager.addToQueue(operation);

      // Act
      await queueManager.removeFromQueue('op-1');
      final queueSize = await queueManager.getQueueSize();

      // Assert
      expect(queueSize, 0);
    });

    test('should get operations by entity type', () async {
      // Arrange
      final operation1 = QueuedOperation(
        operationId: 'op-1',
        operationType: 'create',
        entityType: 'message',
        entityId: 'msg-1',
        data: {'text': 'Hello'},
        timestamp: DateTime.now(),
      );
      final operation2 = QueuedOperation(
        operationId: 'op-2',
        operationType: 'create',
        entityType: 'session',
        entityId: 'session-1',
        data: {'status': 'scheduled'},
        timestamp: DateTime.now(),
      );
      final operation3 = QueuedOperation(
        operationId: 'op-3',
        operationType: 'create',
        entityType: 'message',
        entityId: 'msg-2',
        data: {'text': 'World'},
        timestamp: DateTime.now(),
      );

      await queueManager.addToQueue(operation1);
      await queueManager.addToQueue(operation2);
      await queueManager.addToQueue(operation3);

      // Act
      final messageOps = await queueManager.getOperationsByEntity('message');
      final sessionOps = await queueManager.getOperationsByEntity('session');

      // Assert
      expect(messageOps.length, 2);
      expect(sessionOps.length, 1);
      expect(messageOps[0].entityType, 'message');
      expect(sessionOps[0].entityType, 'session');
    });

    test('should update retry count', () async {
      // Arrange
      final operation = QueuedOperation(
        operationId: 'op-1',
        operationType: 'update',
        entityType: 'user',
        entityId: 'user-1',
        data: {'name': 'Updated Name'},
        timestamp: DateTime.now(),
        retryCount: 0,
      );
      await queueManager.addToQueue(operation);

      // Act
      await queueManager.updateRetryCount(operation);
      final operations = await queueManager.getQueuedOperations();

      // Assert
      expect(operations[0].retryCount, 1);
      expect(operations[0].lastRetryAt, isNotNull);
    });

    test('should clear entire queue', () async {
      // Arrange
      for (int i = 0; i < 5; i++) {
        final operation = QueuedOperation(
          operationId: 'op-$i',
          operationType: 'create',
          entityType: 'message',
          entityId: 'msg-$i',
          data: {'text': 'Message $i'},
          timestamp: DateTime.now(),
        );
        await queueManager.addToQueue(operation);
      }

      // Act
      await queueManager.clearQueue();
      final queueSize = await queueManager.getQueueSize();

      // Assert
      expect(queueSize, 0);
    });
  });

  group('OfflineQueueManager - Queue Processing', () {
    test('should return empty message when queue is empty', () async {
      // Act
      final result = await queueManager.processQueue();

      // Assert
      expect(result.success, true);
      expect(result.message, contains('empty'));
    });

    test('should detect online/offline status', () async {
      // Act
      final isOnline = await queueManager.isOnline();

      // Assert
      expect(isOnline, isA<bool>());
      // Note: Actual connectivity check depends on device state
    });

    test('should get failed operations', () async {
      // Arrange
      final operation = QueuedOperation(
        operationId: 'op-1',
        operationType: 'update',
        entityType: 'course',
        entityId: 'course-1',
        data: {'title': 'Updated Title'},
        timestamp: DateTime.now(),
        retryCount: 3, // Exceeded max retries
      );
      await queueManager.addToQueue(operation);

      // Act
      final failedOps = await queueManager.getFailedOperations();

      // Assert
      expect(failedOps.length, 1);
      expect(failedOps[0].retryCount, greaterThanOrEqualTo(3));
    });

    test('should clear failed operations', () async {
      // Arrange
      final operation1 = QueuedOperation(
        operationId: 'op-1',
        operationType: 'update',
        entityType: 'course',
        entityId: 'course-1',
        data: {'title': 'Updated Title'},
        timestamp: DateTime.now(),
        retryCount: 3, // Failed
      );
      final operation2 = QueuedOperation(
        operationId: 'op-2',
        operationType: 'create',
        entityType: 'message',
        entityId: 'msg-1',
        data: {'text': 'Hello'},
        timestamp: DateTime.now(),
        retryCount: 0, // Not failed
      );
      await queueManager.addToQueue(operation1);
      await queueManager.addToQueue(operation2);

      // Act
      await queueManager.clearFailedOperations();
      final queueSize = await queueManager.getQueueSize();
      final operations = await queueManager.getQueuedOperations();

      // Assert
      expect(queueSize, 1);
      expect(operations[0].operationId, 'op-2');
    });
  });

  group('OfflineQueueManager - Operation Serialization', () {
    test('should serialize and deserialize operation correctly', () async {
      // Arrange
      final originalOperation = QueuedOperation(
        operationId: 'op-1',
        operationType: 'create',
        entityType: 'notification',
        entityId: 'notif-1',
        data: {
          'userId': 'user-1',
          'title': 'Test Notification',
          'message': 'This is a test',
          'type': 'system',
        },
        timestamp: DateTime.now(),
        retryCount: 2,
        lastRetryAt: DateTime.now(),
      );

      // Act
      await queueManager.addToQueue(originalOperation);
      final operations = await queueManager.getQueuedOperations();
      final retrievedOperation = operations[0];

      // Assert
      expect(retrievedOperation.operationId, originalOperation.operationId);
      expect(retrievedOperation.operationType, originalOperation.operationType);
      expect(retrievedOperation.entityType, originalOperation.entityType);
      expect(retrievedOperation.entityId, originalOperation.entityId);
      expect(retrievedOperation.data['title'], originalOperation.data['title']);
      expect(retrievedOperation.retryCount, originalOperation.retryCount);
    });

    test('should handle complex data structures', () async {
      // Arrange
      final operation = QueuedOperation(
        operationId: 'op-1',
        operationType: 'update',
        entityType: 'session',
        entityId: 'session-1',
        data: {
          'status': 'completed',
          'feedback': {
            'rating': 5,
            'comment': 'Excellent session',
            'tags': ['helpful', 'knowledgeable'],
          },
          'participants': ['user-1', 'user-2'],
        },
        timestamp: DateTime.now(),
      );

      // Act
      await queueManager.addToQueue(operation);
      final operations = await queueManager.getQueuedOperations();
      final retrieved = operations[0];

      // Assert
      expect(retrieved.data['status'], 'completed');
      expect(retrieved.data['feedback']['rating'], 5);
      expect(retrieved.data['feedback']['tags'], isA<List>());
      expect(retrieved.data['participants'].length, 2);
    });
  });
}
