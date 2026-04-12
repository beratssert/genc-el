import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/task.dart';
import 'package:tdp_frontend/services/api_service.dart';
import 'package:tdp_frontend/shared/api_url.dart';

/// Provider for the [TaskRepository] implementation.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TaskRepositoryImpl(apiService);
});

/// Abstract class defining the task (shopping workflow) repository interface.
abstract class TaskRepository {
  /// Creates a new shopping request (Elderly).
  Future<Task> createTask({
    required List<String> shoppingList,
    String? note,
  });

  /// Lists all pending tasks (Student sees these).
  Future<List<Task>> getPendingTasks();

  /// Lists the current user's tasks (both elderly and student).
  Future<List<Task>> getMyTasks();

  /// Accepts a pending task (Student).
  Future<Task> assignTask(String taskId);

  /// Starts the shopping (Student received money, heading to store).
  Future<Task> startTask(String taskId, double totalAmountGiven);

  /// Delivers the shopping (Student returned with goods).
  Future<Task> deliverTask(
    String taskId,
    double changeAmount, {
    String? receiptImageUrl,
  });

  /// Completes the task (Elderly confirms).
  Future<Task> completeTask(String taskId);

  /// Cancels the task.
  Future<Task> cancelTask(String taskId);
}

/// Concrete implementation connected to the Spring Boot backend.
class TaskRepositoryImpl implements TaskRepository {
  final ApiService _apiService;

  TaskRepositoryImpl(this._apiService);

  @override
  Future<Task> createTask({
    required List<String> shoppingList,
    String? note,
  }) async {
    final response = await _apiService.post(
      ApiUrl.tasks,
      data: {
        'shoppingList': shoppingList,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return Task.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<Task>> getPendingTasks() async {
    final response = await _apiService.get(ApiUrl.pendingTasks);
    if (response is List) {
      return response
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Task>> getMyTasks() async {
    final response = await _apiService.get(ApiUrl.myTasks);
    if (response is List) {
      return response
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Task> assignTask(String taskId) async {
    final response = await _apiService.put(ApiUrl.assignTask(taskId));
    return Task.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Task> startTask(String taskId, double totalAmountGiven) async {
    final response = await _apiService.put(
      ApiUrl.startTask(taskId),
      data: {'totalAmountGiven': totalAmountGiven},
    );
    return Task.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Task> deliverTask(
    String taskId,
    double changeAmount, {
    String? receiptImageUrl,
  }) async {
    final response = await _apiService.put(
      ApiUrl.deliverTask(taskId),
      data: {
        'changeAmount': changeAmount,
        if (receiptImageUrl != null) 'receiptImageUrl': receiptImageUrl,
      },
    );
    return Task.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Task> completeTask(String taskId) async {
    final response = await _apiService.put(ApiUrl.completeTask(taskId));
    return Task.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Task> cancelTask(String taskId) async {
    final response = await _apiService.put(ApiUrl.cancelTask(taskId));
    return Task.fromJson(response as Map<String, dynamic>);
  }
}
