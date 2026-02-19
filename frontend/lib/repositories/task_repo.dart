import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [TaskRepository] implementation.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl();
});

/// Abstract class defining the task (shopping workflow) repository interface.
abstract class TaskRepository {
  /// Creates a new shopping request (Elderly).
  Future<void> createTask(Map<String, dynamic> taskData);

  /// Lists nearby pending tasks based on location (Student).
  Future<List<Map<String, dynamic>>> getNearbyTasks({
    required double lat,
    required double lon,
    double radius = 5.0,
  });

  /// Gets the currently active task assigned to the student.
  Future<Map<String, dynamic>?> getMyActiveTask();

  /// Accepts a pending task (Student).
  Future<void> acceptTask(String taskId);

  /// Starts the shopping process after arriving at the elderly's home (Student).
  Future<void> startShopping(String taskId, double receivedAmount);

  /// Completes the shopping and marks as returning home (Student).
  Future<void> completeShopping(String taskId);

  /// Uploads a receipt image for the task (Student).
  Future<void> uploadReceipt(String taskId, File receiptFile);

  /// Completes the delivery and marks the task as completed (Student).
  Future<void> completeTask(String taskId, double changeAmount, String? note);

  /// Confirms that the student has arrived and started (Elderly).
  Future<void> confirmStart(String taskId);

  /// Confirms the delivery and finalizes the task (Elderly).
  Future<void> confirmEnd(String taskId);
}

/// Concrete implementation of [TaskRepository] with placeholder logic.
class TaskRepositoryImpl implements TaskRepository {
  @override
  Future<void> createTask(Map<String, dynamic> taskData) async {
    throw UnimplementedError('createTask() has not been implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyTasks({
    required double lat,
    required double lon,
    double radius = 5.0,
  }) async {
    throw UnimplementedError('getNearbyTasks() has not been implemented');
  }

  @override
  Future<Map<String, dynamic>?> getMyActiveTask() async {
    throw UnimplementedError('getMyActiveTask() has not been implemented');
  }

  @override
  Future<void> acceptTask(String taskId) async {
    throw UnimplementedError('acceptTask() has not been implemented');
  }

  @override
  Future<void> startShopping(String taskId, double receivedAmount) async {
    throw UnimplementedError('startShopping() has not been implemented');
  }

  @override
  Future<void> completeShopping(String taskId) async {
    throw UnimplementedError('completeShopping() has not been implemented');
  }

  @override
  Future<void> uploadReceipt(String taskId, File receiptFile) async {
    throw UnimplementedError('uploadReceipt() has not been implemented');
  }

  @override
  Future<void> completeTask(
    String taskId,
    double changeAmount,
    String? note,
  ) async {
    throw UnimplementedError('completeTask() has not been implemented');
  }

  @override
  Future<void> confirmStart(String taskId) async {
    throw UnimplementedError('confirmStart() has not been implemented');
  }

  @override
  Future<void> confirmEnd(String taskId) async {
    throw UnimplementedError('confirmEnd() has not been implemented');
  }
}
