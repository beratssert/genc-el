/// Backend `Task.TaskStatus` enum ile birebir uyumlu.
/// Backend değerleri: PENDING, ASSIGNED, IN_PROGRESS, DELIVERED, COMPLETED, CANCELLED
enum TaskStatus {
  PENDING,
  ASSIGNED,
  IN_PROGRESS,
  DELIVERED,
  COMPLETED,
  CANCELLED;

  static TaskStatus fromString(String status) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => TaskStatus.PENDING,
    );
  }

  String get label {
    switch (this) {
      case TaskStatus.PENDING:
        return 'Öğrenci Aranıyor…';
      case TaskStatus.ASSIGNED:
        return 'Öğrenci Yolda';
      case TaskStatus.IN_PROGRESS:
        return 'Alışveriş Yapılıyor';
      case TaskStatus.DELIVERED:
        return 'Teslimat Yapılıyor';
      case TaskStatus.COMPLETED:
        return 'Tamamlandı';
      case TaskStatus.CANCELLED:
        return 'İptal Edildi';
    }
  }

  int get colorValue {
    switch (this) {
      case TaskStatus.PENDING:
        return 0xFFF59E0B; // amber-500
      case TaskStatus.ASSIGNED:
        return 0xFF3B82F6; // blue-500
      case TaskStatus.IN_PROGRESS:
        return 0xFF8B5CF6; // violet-500
      case TaskStatus.DELIVERED:
        return 0xFF06B6D4; // cyan-500
      case TaskStatus.COMPLETED:
        return 0xFF16A34A; // green-600
      case TaskStatus.CANCELLED:
        return 0xFFEF4444; // red-500
    }
  }
}

/// Backend `TaskResponse` DTO ile birebir uyumlu model.
class Task {
  final String id;
  final String? requesterId;
  final String? volunteerId;
  final TaskStatus status;
  final List<String> shoppingList;
  final String? note;
  final double? totalAmountGiven;
  final double? changeAmount;
  final String? receiptImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    this.requesterId,
    this.volunteerId,
    required this.status,
    required this.shoppingList,
    this.note,
    this.totalAmountGiven,
    this.changeAmount,
    this.receiptImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Backend JSON camelCase formatına uygun parser.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      requesterId: json['requesterId']?.toString(),
      volunteerId: json['volunteerId']?.toString(),
      status: TaskStatus.fromString(json['status'] ?? 'PENDING'),
      shoppingList: json['shoppingList'] != null
          ? List<String>.from(json['shoppingList'])
          : [],
      note: json['note'],
      totalAmountGiven: (json['totalAmountGiven'] as num?)?.toDouble(),
      changeAmount: (json['changeAmount'] as num?)?.toDouble(),
      receiptImageUrl: json['receiptImageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'volunteerId': volunteerId,
      'status': status.name,
      'shoppingList': shoppingList,
      'note': note,
      'totalAmountGiven': totalAmountGiven,
      'changeAmount': changeAmount,
      'receiptImageUrl': receiptImageUrl,
    };
  }
}
