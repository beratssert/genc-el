//db table
//  TASK_LOG {
//         Long id PK
//         Long task_id FK
//         String action "CREATED, ASSIGNED, SHOPPING_STARTED, DELIVERED, COMPLETED"
//         Timestamp timestamp
//     }

class TaskLog {
  final String id;
  final String taskId;
  final String action;
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
      action: json['action'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'action': action,
      'timestamp': timestamp,
    };
  }
}
