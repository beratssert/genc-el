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

  /// Lists nearby pending tasks (Student sees these).
  Future<List<Task>> getNearbyTasks({
    double? latitude,
    double? longitude,
    double? radiusKm,
  });

  /// Gets the active task for a student.
  Future<Task?> getMyActiveTask();

  /// Lists the current user's tasks (both elderly and student).
  Future<List<Task>> getMyTasks();

  /// Accepts a pending task (Student).
  Future<Task> assignTask(String taskId);

  /// Rejects an assigned task (Student).
  Future<Task> rejectTask(String taskId);

  /// Confirms shopping start (Elderly).
  Future<Task> confirmStartTask(String taskId, double totalAmountGiven);

  /// Starts the shopping (Student received money, heading to store).
  Future<Task> startTask(String taskId, double totalAmountGiven);

  /// Confirms delivery (Elderly).
  Future<Task> confirmEndTask(String taskId, {double? changeAmount});

  /// Delivers the shopping (Student returned with goods).
  Future<Task> deliverTask(
    String taskId,
    double changeAmount, {
    String? note,
  });

  /// Completes the task (Elderly confirms final step).
  Future<Task> completeTask(String taskId);

  /// Cancels the task.
  Future<Task> cancelTask(String taskId);

  /// Uploads a receipt image (Elderly).
  Future<Task> uploadReceipt(String taskId, String imagePath);
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
  Future<List<Task>> getNearbyTasks({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final response = await _apiService.get(
      ApiUrl.nearbyTasks,
      queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
      },
    );
    if (response is List) {
      return response
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Task?> getMyActiveTask() async {
    final response = await _apiService.get(ApiUrl.myActiveTask);
    if (response == null) return null;
    return Task.fromJson(response as Map<String, dynamic>);
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
  Future<Task> rejectTask(String taskId) async {
    final response = await _apiService.put(ApiUrl.rejectTask(taskId));
    return Task.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Task> confirmStartTask(String taskId, double totalAmountGiven) async {
    final response = await _apiService.put(
      ApiUrl.confirmStartTask(taskId),
      data: {'totalAmountGiven': totalAmountGiven},
    );
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
  Future<Task> confirmEndTask(String taskId, {double? changeAmount}) async {
    final response = await _apiService.put(
      ApiUrl.confirmEndTask(taskId),
      data: changeAmount != null ? {'changeAmount': changeAmount} : null,
    );
    return Task.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Task> deliverTask(
    String taskId,
    double changeAmount, {
    String? note,
  }) async {
    final response = await _apiService.put(
      ApiUrl.deliverTask(taskId),
      data: {
        'changeAmount': changeAmount,
        if (note != null) 'note': note,
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

  @override
  Future<Task> uploadReceipt(String taskId, String imagePath) async {
    final response = await _apiService.uploadFile(
      ApiUrl.uploadReceipt(taskId),
      imagePath,
      key: 'receiptFile',
    );
    return Task.fromJson(response as Map<String, dynamic>);
  }
}
