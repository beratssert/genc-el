//DB table
// BURSARY_HISTORY {
//         Long id PK
//         Long student_id FK
//         Integer year
//         Integer month
//         Integer completed_task_count
//         Double calculated_amount
//         Boolean is_paid
//     }

class BursaryHistory {
  final String id;
  final String studentId;
  final int year;
  final int month;
  final int completedTaskCount;
  final double calculatedAmount;
  final bool isPaid;

  BursaryHistory({
    required this.id,
    required this.studentId,
    required this.year,
    required this.month,
    required this.completedTaskCount,
    required this.calculatedAmount,
    required this.isPaid,
  });

  factory BursaryHistory.fromJson(Map<String, dynamic> json) {
    return BursaryHistory(
      id: json['id'],
      studentId: json['student_id'],
      year: json['year'],
      month: json['month'],
      completedTaskCount: json['completed_task_count'],
      calculatedAmount: json['calculated_amount'],
      isPaid: json['is_paid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'year': year,
      'month': month,
      'completed_task_count': completedTaskCount,
      'calculated_amount': calculatedAmount,
      'is_paid': isPaid,
    };
  }
}
