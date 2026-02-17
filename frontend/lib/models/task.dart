//db table

// TASK {
//         Long id PK
//         Long requester_id FK "Elderly"
//         Long volunteer_id FK "Student"
//         String status "PENDING, ASSIGNED, IN_PROGRESS, DELIVERED, COMPLETED, CANCELLED"
//         JSONB shopping_list "List of items to buy"
//         String note "Extra instructions like 'Ring the bell'"
//         Timestamp created_at
//         Timestamp updated_at
//         Double total_amount_given
//         Double change_amount
//         String receipt_image_url
//     }

class Task {
  final String id;
  final String requesterId;
  final String volunteerId;
  final String status;
  final String shoppingList;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalAmountGiven;
  final double changeAmount;
  final String receiptImageUrl;

  Task({
    required this.id,
    required this.requesterId,
    required this.volunteerId,
    required this.status,
    required this.shoppingList,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmountGiven,
    required this.changeAmount,
    required this.receiptImageUrl,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      requesterId: json['requester_id'],
      volunteerId: json['volunteer_id'],
      status: json['status'],
      shoppingList: json['shopping_list'],
      note: json['note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      totalAmountGiven: json['total_amount_given'],
      changeAmount: json['change_amount'],
      receiptImageUrl: json['receipt_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'volunteer_id': volunteerId,
      'status': status,
      'shopping_list': shoppingList,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'total_amount_given': totalAmountGiven,
      'change_amount': changeAmount,
      'receipt_image_url': receiptImageUrl,
    };
  }
}
