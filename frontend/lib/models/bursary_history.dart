/// Backend `BursaryResponse` DTO ile birebir uyumlu model.
class BursaryHistory {
  final String id;
  final String? studentId;
  final String? studentFirstName;
  final String? studentLastName;
  final int year;
  final int month;
  final int completedTaskCount;
  final double calculatedAmount;
  final bool isPaid;
  final DateTime? paymentDate;
  final String? transactionReference;

  BursaryHistory({
    required this.id,
    this.studentId,
    this.studentFirstName,
    this.studentLastName,
    required this.year,
    required this.month,
    required this.completedTaskCount,
    required this.calculatedAmount,
    required this.isPaid,
    this.paymentDate,
    this.transactionReference,
  });

  String get studentFullName =>
      '${studentFirstName ?? ''} ${studentLastName ?? ''}'.trim();

  factory BursaryHistory.fromJson(Map<String, dynamic> json) {
    return BursaryHistory(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      studentFirstName: json['studentFirstName'],
      studentLastName: json['studentLastName'],
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      completedTaskCount: json['completedTaskCount'] ?? 0,
      calculatedAmount: (json['calculatedAmount'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] ?? false,
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'])
          : null,
      transactionReference: json['transactionReference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'year': year,
      'month': month,
      'completedTaskCount': completedTaskCount,
      'calculatedAmount': calculatedAmount,
      'isPaid': isPaid,
    };
  }
}
