import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/task.dart';
import '../../repositories/task_repo.dart';
import '../../services/storage_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../widgets/student/student_greeting_header.dart';
import '../../widgets/student/availability_card.dart';
import '../../widgets/student/student_task_card.dart';
import '../../widgets/student/student_action_buttons.dart';
import '../../screens/student/student_order_history_screen.dart';

/// Öğrenci kullanıcısının ana ekranı.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  bool _isAvailable = true;
  final Set<String> _ignoredTaskIds =
      {}; // Backend'i etkilemeden sadece UI'dan gizlemek için

  @override
  void initState() {
    super.initState();
  }

  Future<void> _assignTask(String taskId) async {
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.assignTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sipariş kabul edildi!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _rejectTask(String taskId) async {
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.rejectTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Görev reddedildi.'),
            backgroundColor: Color(0xFF64748B),
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _cancelTask(String taskId) async {
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.cancelTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Görev iptal edildi.'),
            backgroundColor: Color(0xFF64748B),
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _startTask(String taskId) async {
    final amountController = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alınan Para Miktarı'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ör: 500.0',
            labelText: 'Tutar (₺)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(amountController.text)),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (amount == null) return;

    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.startTask(taskId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛒 Alışverişe başlandı!'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _deliverTask(String taskId) async {
    final changeController = TextEditingController();
    final change = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Para Üstü'),
        content: TextField(
          controller: changeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ör: 25.50',
            labelText: 'Para Üstü (₺)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(changeController.text) ?? 0),
            child: const Text('Teslim Et'),
          ),
        ],
      ),
    );
    if (change == null) return;

    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.deliverTask(taskId, change);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📦 Teslimat yapıldı!'),
            backgroundColor: Color(0xFF06B6D4),
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _refreshData() {
    ref.invalidate(pendingTasksProvider);
    ref.invalidate(myTasksProvider);
    ref.invalidate(dashboardStatsProvider);
  }

  Future<void> _logout() async {
    final storageService = ref.read(storageServiceProvider);
    await storageService.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(selectedType: 'student')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('StudentHomeScreen: Build triggered');
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final myTasksAsync = ref.watch(myTasksProvider);
    final pendingTasksAsync = ref.watch(pendingTasksProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- 1. Karşılama + Yenile + Logout ---
                Row(
                  children: [
                    Expanded(
                      child: userAsync.when(
                        data: (user) => StudentGreetingHeader(
                          studentName: user.firstName,
                          completedCount: statsAsync.when(
                            data: (s) => s.totalCompletedTasks?.toInt() ?? 0,
                            loading: () => 0,
                            error: (_, _) => 0,
                          ),
                        ),
                        loading: () => const StudentGreetingHeader(
                          studentName: 'Yükleniyor…',
                          completedCount: 0,
                        ),
                        error: (_, _) => const StudentGreetingHeader(
                          studentName: 'Öğrenci',
                          completedCount: 0,
                        ),
                      ),
                    ),
                    // IconButton(
                    //   onPressed: _refreshData,
                    //   icon: const Icon(Icons.refresh_rounded),
                    //   tooltip: 'Yenile',
                    //   color: const Color(0xFF2563EB),
                    // ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Çıkış Yap',
                      color: const Color(0xFF6B7280),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 2. Müsaitlik Toggle ---
                myTasksAsync.when(
                  data: (tasks) {
                    final activeTask = tasks.cast<Task?>().firstWhere(
                      (t) =>
                          t!.status != TaskStatus.COMPLETED &&
                          t.status != TaskStatus.CANCELLED,
                      orElse: () => null,
                    );
                    return AvailabilityCard(
                      isAvailable: _isAvailable,
                      isTaskActive: activeTask != null,
                      onToggle: (value) => setState(() => _isAvailable = value),
                    );
                  },
                  loading: () => AvailabilityCard(
                    isAvailable: _isAvailable,
                    isTaskActive: false,
                    onToggle: (v) {},
                  ),
                  error: (_, _) => AvailabilityCard(
                    isAvailable: _isAvailable,
                    isTaskActive: false,
                    onToggle: (v) {},
                  ),
                ),
                const SizedBox(height: 24),

                // --- 3. İçerik ---
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _refreshData(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Aktif görev
                          myTasksAsync.when(
                            data: (tasks) {
                              final activeTask = tasks.cast<Task?>().firstWhere(
                                (t) =>
                                    t!.status != TaskStatus.COMPLETED &&
                                    t.status != TaskStatus.CANCELLED,
                                orElse: () => null,
                              );
                              return StudentTaskCard(
                                activeTask: activeTask,
                                isAvailable: _isAvailable,
                                onStart: () => _startTask(activeTask!.id),
                                onDeliver: () => _deliverTask(activeTask!.id),
                                onReject: () => _rejectTask(activeTask!.id),
                                onCancel: () {
                                  // ASSIGNED durumundaysa görev henüz başlanmamış,
                                  // bu durumda "İptal Et" aslında "Reddet" işlemi yapmalı
                                  if (activeTask!.status ==
                                      TaskStatus.ASSIGNED) {
                                    _rejectTask(activeTask.id);
                                  } else {
                                    _cancelTask(activeTask.id);
                                  }
                                },
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, _) =>
                                Center(child: Text('Hata: $err')),
                          ),

                          // Bekleyen görevler
                          pendingTasksAsync.when(
                            data: (pendingTasks) {
                              // Sadece aktif görev yokken ve müsaitken göster
                              final hasActiveTask = myTasksAsync.maybeWhen(
                                data: (tasks) => tasks.any(
                                  (t) =>
                                      t.status != TaskStatus.COMPLETED &&
                                      t.status != TaskStatus.CANCELLED,
                                ),
                                orElse: () => false,
                              );

                              if (!hasActiveTask &&
                                  _isAvailable &&
                                  pendingTasks.isNotEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        0,
                                        24,
                                        0,
                                        12,
                                      ),
                                      child: Text(
                                        '📋 Bekleyen Siparişler',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A5F),
                                        ),
                                      ),
                                    ),
                                    ...pendingTasks
                                        .where(
                                          (t) =>
                                              !_ignoredTaskIds.contains(t.id),
                                        )
                                        .map((t) => _buildPendingTaskCard(t)),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- 4. Aksiyon Butonları ---
                myTasksAsync.when(
                  data: (tasks) {
                    final completedTasks = tasks
                        .where(
                          (t) =>
                              t.status == TaskStatus.COMPLETED ||
                              t.status == TaskStatus.CANCELLED,
                        )
                        .toList();
                    return StudentActionButtons(
                      onViewHistory: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentOrderHistoryScreen(
                              completedTasks: completedTasks,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTaskCard(Task task) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Yeni Sipariş',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
              const Spacer(),
              if (task.createdAt != null)
                Text(
                  _formatTime(task.createdAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.shoppingList.join(' • '),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Task'ı tamamen iptal etmek (backend'de de CANCELLED yapmak) yerine
                    // sadece bu öğrenci için arayüzden gizliyoruz (Reddediyoruz).
                    setState(() {
                      _ignoredTaskIds.add(task.id);
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Görev reddedildi (gizlendi).'),
                          backgroundColor: Color(0xFF64748B),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reddet'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(
                      color: Colors.red.shade400.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _assignTask(task.id),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Kabul Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gn önce';
  }
}
