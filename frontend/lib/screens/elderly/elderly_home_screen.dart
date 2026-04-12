import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../models/task.dart';
import '../../repositories/task_repo.dart';
import '../../services/storage_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/elderly/order_history_screen.dart';
import '../../screens/order/category_screen.dart';
import '../../widgets/elderly/greeting_header.dart';
import '../../widgets/elderly/home_action_buttons.dart';
import '../../widgets/elderly/active_order_card.dart';

/// Yaşlı/Engelli kullanıcısının ana sayfası.
class ElderlyHomeScreen extends ConsumerStatefulWidget {
  const ElderlyHomeScreen({super.key});

  @override
  ConsumerState<ElderlyHomeScreen> createState() => _ElderlyHomeScreenState();
}

class _ElderlyHomeScreenState extends ConsumerState<ElderlyHomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _refreshMyTasks() {
    ref.invalidate(myTasksProvider);
    ref.invalidate(currentUserProvider);
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
    debugPrint('ElderlyHomeScreen: Build triggered');
    final userAsync = ref.watch(currentUserProvider);
    final myTasksAsync = ref.watch(myTasksProvider);

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
                        error: (_, _) =>
                            const GreetingHeader(userName: 'Kullanıcı'),
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshMyTasks,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Yenile',
                      color: const Color(0xFF059669),
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
                  child: myTasksAsync.when(
                    data: (tasks) {
                      final currentActiveTask = tasks.cast<Task?>().firstWhere(
                        (t) =>
                            t!.status != TaskStatus.COMPLETED &&
                            t.status != TaskStatus.CANCELLED,
                        orElse: () => null,
                      );
                      return RefreshIndicator(
                        onRefresh: () async => _refreshMyTasks(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ActiveOrderCard(
                            activeTask: currentActiveTask,
                            onConfirmStart: () => _confirmStartTask(currentActiveTask!.id),
                            onConfirmDelivery: () => _confirmDeliveryTask(currentActiveTask!.id),
                            onCancel: () => _cancelTask(currentActiveTask!.id),
                            onUploadReceipt: () => _pickAndUploadReceipt(currentActiveTask!.id),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Hata: $err')),
                  ),
                ),
                const SizedBox(height: 20),

                // --- 3. Aksiyon Butonları ---
                myTasksAsync.when(
                  data: (tasks) {
                    final currentActiveTask = tasks.cast<Task?>().firstWhere(
                      (t) =>
                          t!.status != TaskStatus.COMPLETED &&
                          t.status != TaskStatus.CANCELLED,
                      orElse: () => null,
                    );
                    return HomeActionButtons(
                      isOrderActive: currentActiveTask != null,
                      onCreateOrder: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CategoryScreen()),
                        );

                        if (result != null) {
                          _refreshMyTasks();
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
                    );
                  },
                  loading: () => HomeActionButtons(
                    isOrderActive: true, // Disable during loading
                    onCreateOrder: () {},
                    onViewHistory: () {},
                  ),
                  error: (_, __) => HomeActionButtons(
                    isOrderActive: false,
                    onCreateOrder: () {},
                    onViewHistory: () {},
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStartTask(String taskId) async {
    final amountController = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verilen Para Miktarı'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ör: 200.0',
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
      await taskRepo.confirmStartTask(taskId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Başlangıç onaylandı, alışveriş süreci başladı.'),
          ),
        );
        _refreshMyTasks();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _pickAndUploadReceipt(String taskId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.uploadReceipt(taskId, image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Fiş başarıyla yüklendi.')),
        );
        _refreshMyTasks();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _confirmDeliveryTask(String taskId) async {
    final amountController = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teslimatı Onayla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Öğrencinin getirdiği para üstü miktarını doğrulayın veya girin:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ör: 25.50',
                labelText: 'Kalan Para Üstü (₺)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(amountController.text) ?? 0.0),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      await taskRepo.confirmEndTask(taskId, changeAmount: amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Teslimat onaylandı!')),
        );
        _refreshMyTasks();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
        _refreshMyTasks();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
}
