import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdp_frontend/models/dashboard_stats.dart';
import 'package:tdp_frontend/models/task.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/models/user_page_response.dart';
import 'package:tdp_frontend/repositories/institution_repo.dart';
import 'package:tdp_frontend/repositories/task_repo.dart';
import 'package:tdp_frontend/repositories/user_repo.dart';

/// ─── User Profile ───────────────────────────────────────
/// Giriş yapmış kullanıcının profil bilgilerini çeker.
final currentUserProvider = FutureProvider.autoDispose<User>((ref) async {
  final userRepo = ref.read(userRepoProvider);
  return userRepo.getMyProfile();
});

/// ─── Dashboard Stats ────────────────────────────────────
/// Role göre student veya institution istatistikleri döner.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final institutionRepo = ref.read(institutionRepoProvider);
  return institutionRepo.getDashboardStats();
});

/// ─── Pending Tasks (Student) ────────────────────────────
/// Öğrencilerin görebileceği bekleyen görevler.
final pendingTasksProvider =
    FutureProvider.autoDispose<List<Task>>((ref) async {
  final taskRepo = ref.read(taskRepositoryProvider);
  return taskRepo.getPendingTasks();
});

/// ─── My Tasks ───────────────────────────────────────────
/// Kullanıcının kendi görevleri (yaşlı: oluşturduğu, öğrenci: aldığı).
final myTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final taskRepo = ref.read(taskRepositoryProvider);
  return taskRepo.getMyTasks();
});

/// ─── Institution Users ──────────────────────────────────
/// Role filtresi ile kullanıcıları listeler.
final institutionUsersProvider =
    FutureProvider.autoDispose.family<UserPageResponse, String?>((ref, role) async {
  final institutionRepo = ref.read(institutionRepoProvider);
  return institutionRepo.getUsers(role: role);
});
