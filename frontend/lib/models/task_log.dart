//db table
//  TASK_LOG {
//         Long id PK
//         Long task_id FK
//         String action "CREATED, ASSIGNED, SHOPPING_STARTED, DELIVERED, COMPLETED"
//         Timestamp timestamp
//     }

enum Action {
  created,
  assigned,
  shoppingStarted,
  delivered,
  completed,
  cancelled;

  static Action fromString(String action) {
    return Action.values.firstWhere((e) => e.name == action);
  }
}

class TaskLog {
  final String id;
  final String taskId;
  final Action action;
  final DateTime timestamp;

  TaskLog({
    required this.id,
    required this.taskId,
    required this.action,
    required this.timestamp,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      id: json['id'],
      taskId: json['task_id'],
      action: Action.fromString(json['action']),
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'action': action.name,
      'timestamp': timestamp,
    };
  }
}
