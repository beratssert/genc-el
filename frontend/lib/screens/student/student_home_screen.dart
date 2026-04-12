import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/task.dart';
import '../../repositories/task_repo.dart';
import '../../services/storage_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../widgets/student/student_greeting_header.dart';
import '../../widgets/student/availability_card.dart';

/// Öğrenci kullanıcısının ana ekranı.
/// Backend'den profil, görev ve dashboard verilerini çeker.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  bool _isAvailable = true;
  List<Task> _pendingTasks = [];
  Task? _activeTask;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final myTasks = await taskRepo.getMyTasks();
      final pending = await taskRepo.getPendingTasks();

      if (mounted) {
        setState(() {
          _pendingTasks = pending;
          _activeTask = myTasks.cast<Task?>().firstWhere(
                (t) =>
                    t!.status != TaskStatus.COMPLETED &&
                    t.status != TaskStatus.CANCELLED,
                orElse: () => null,
              );
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignTask(String taskId) async {
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.assignTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Sipariş kabul edildi!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  Future<void> _startTask(String taskId) async {
    // Para miktarını sormak için dialog göster
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
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(amountController.text);
              Navigator.pop(ctx, val);
            },
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
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
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
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(changeController.text) ?? 0;
              Navigator.pop(ctx, val);
            },
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
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
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
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
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
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFDBEAFE), // blue-100
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- 1. Karşılama + Logout ---
                Row(
                  children: [
                    Expanded(
                      child: userAsync.when(
                        data: (user) => StudentGreetingHeader(
                          studentName: user.firstName,
                          completedCount: statsAsync.when(
                            data: (s) => s.totalCompletedTasks?.toInt() ?? 0,
                            loading: () => 0,
                            error: (_, __) => 0,
                          ),
                        ),
                        loading: () => const StudentGreetingHeader(
                          studentName: 'Yükleniyor…',
                          completedCount: 0,
                        ),
                        error: (_, __) => const StudentGreetingHeader(
                          studentName: 'Öğrenci',
                          completedCount: 0,
                        ),
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
                const SizedBox(height: 24),

                // --- 2. Müsaitlik Toggle ---
                AvailabilityCard(
                  isAvailable: _isAvailable,
                  isTaskActive: _activeTask != null,
                  onToggle: (value) => setState(() => _isAvailable = value),
                ),
                const SizedBox(height: 24),

                // --- 3. İçerik ---
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Aktif görev
                                if (_activeTask != null)
                                  _buildActiveTaskCard(_activeTask!),

                                // Bekleyen görevler
                                if (_activeTask == null &&
                                    _isAvailable &&
                                    _pendingTasks.isNotEmpty) ...[
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      '📋 Bekleyen Siparişler',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A5F),
                                      ),
                                    ),
                                  ),
                                  ..._pendingTasks
                                      .map((t) => _buildPendingTaskCard(t)),
                                ],

                                // Boş durum
                                if (_activeTask == null &&
                                    _pendingTasks.isEmpty)
                                  _buildEmptyState(),
                              ],
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTaskCard(Task task) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durum satırı
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      Color(task.status.colorValue).withValues(alpha: 0.1),
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
              const Icon(Icons.assignment_outlined,
                  size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              const Text(
                'Aktif Görev',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Alışveriş listesi
          ...task.shoppingList.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF374151))),
                  ),
                ],
              ),
            ),
          ),

          if (task.note != null && task.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(task.note!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF92400E))),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Aksiyon butonları — duruma göre
          if (task.status == TaskStatus.ASSIGNED)
            _actionButton(
              'Alışverişe Başla',
              Icons.play_arrow_rounded,
              const Color(0xFF8B5CF6),
              () => _startTask(task.id),
            ),
          if (task.status == TaskStatus.IN_PROGRESS)
            _actionButton(
              'Teslim Et',
              Icons.local_shipping_outlined,
              const Color(0xFF06B6D4),
              () => _deliverTask(task.id),
            ),
          if (task.status != TaskStatus.DELIVERED &&
              task.status != TaskStatus.COMPLETED)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelTask(task.id),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Görevi İptal Et'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Bekliyor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const Spacer(),
              if (task.createdAt != null)
                Text(
                  _formatTime(task.createdAt!),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.shoppingList.join(' • '),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.note != null && task.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '💬 ${task.note}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            _isAvailable
                ? 'Şu anda bekleyen sipariş yok'
                : 'Müsaitlik kapalı',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isAvailable
                ? 'Yeni siparişler geldiğinde burada görünecek'
                : 'Sipariş almak için müsaitliği açın',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}
