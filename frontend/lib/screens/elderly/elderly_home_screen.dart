import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/task.dart';
import '../../repositories/task_repo.dart';
import '../../services/storage_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/elderly/order_history_screen.dart';
import '../../screens/order/category_screen.dart';
import '../../widgets/elderly/greeting_header.dart';
import '../../widgets/elderly/home_action_buttons.dart';

/// Yaşlı/Engelli kullanıcısının ana sayfası.
/// Backend'den profil ve görev bilgilerini çeker.
class ElderlyHomeScreen extends ConsumerStatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  ConsumerState<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends ConsumerState<ElderlyHomeScreen> {
  Task? _currentActiveTask;
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final tasks = await taskRepo.getMyTasks();
      if (mounted) {
        setState(() {
          // Aktif görevi bul (tamamlanmamış / iptal edilmemiş)
          _currentActiveTask = tasks.cast<Task?>().firstWhere(
            (t) =>
                t!.status != TaskStatus.COMPLETED &&
                t.status != TaskStatus.CANCELLED,
            orElse: () => null,
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _logout() async {
    final storageService = ref.read(storageServiceProvider);
    await storageService.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(selectedType: 'elderly')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // green-50
              Color(0xFFD1FAE5), // emerald-100
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Karşılama + Logout ---
                Row(
                  children: [
                    Expanded(
                      child: userAsync.when(
                        data: (user) => GreetingHeader(
                          userName: '${user.firstName} ${user.lastName}',
                        ),
                        loading: () =>
                            const GreetingHeader(userName: 'Yükleniyor…'),
                        error: (_, __) =>
                            const GreetingHeader(userName: 'Kullanıcı'),
                      ),
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Çıkış Yap',
                      color: const Color(0xFF6B7280),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // --- 2. Aktif Sipariş ---
                Expanded(
                  child: _isLoadingTasks
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: _buildActiveOrderSection(),
                        ),
                ),
                const SizedBox(height: 20),

                // --- 3. Aksiyon Butonları ---
                HomeActionButtons(
                  isOrderActive: _currentActiveTask != null,
                  onCreateOrder: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoryScreen()),
                    );

                    if (result != null) {
                      // Sipariş oluşturuldu, görevleri yeniden yükle
                      await _loadMyTasks();
                    }
                  },
                  onViewHistory: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrderSection() {
    if (_currentActiveTask == null) {
      return _buildEmptyActiveOrder();
    }

    final task = _currentActiveTask!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durum badge'i
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(task.status.colorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.status.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(task.status.colorValue),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Sipariş #${task.id.substring(0, 8)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alışveriş listesi
          const Text(
            'Alışveriş Listesi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          ...task.shoppingList.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (task.note != null && task.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.note!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Görev tamamlama butonu (DELIVERED durumunda)
          if (task.status == TaskStatus.DELIVERED) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completeTask(task.id),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Teslimatı Onayla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          // İptal butonu (tamamlanmamışsa)
          if (task.status == TaskStatus.PENDING) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelTask(task.id),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text('Siparişi İptal Et'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyActiveOrder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Color(0xFFD1D5DB),
            ),
            SizedBox(height: 12),
            Text(
              'Aktif siparişiniz yok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Yeni bir alışveriş oluşturarak başlayın',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.completeTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Teslimat onaylandı!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        await _loadMyTasks();
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
            content: Text('❌ Sipariş iptal edildi.'),
            backgroundColor: Color(0xFF64748B),
          ),
        );
        await _loadMyTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}
