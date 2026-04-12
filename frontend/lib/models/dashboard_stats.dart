/// Backend `DashboardStatsResponse` DTO ile birebir uyumlu model.
/// Öğrenci ve kurum yöneticisi için farklı alanlar döner.
class DashboardStats {
  // Öğrenci istatistikleri
  final int? totalCompletedTasks;
  final double? estimatedCurrentMonthBursary;

  // Kurum yöneticisi istatistikleri
  final int? totalStudents;
  final int? totalElderlies;
  final int? totalTasksThisMonth;

  DashboardStats({
    this.totalCompletedTasks,
    this.estimatedCurrentMonthBursary,
    this.totalStudents,
    this.totalElderlies,
    this.totalTasksThisMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCompletedTasks: json['totalCompletedTasks'] as int?,
      estimatedCurrentMonthBursary:
          (json['estimatedCurrentMonthBursary'] as num?)?.toDouble(),
      totalStudents: json['totalStudents'] as int?,
      totalElderlies: json['totalElderlies'] as int?,
      totalTasksThisMonth: json['totalTasksThisMonth'] as int?,
    );
  }
}
