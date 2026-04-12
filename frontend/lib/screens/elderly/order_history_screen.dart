import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../repositories/task_repo.dart';

/// Yaşlı/Engelli kullanıcısının sipariş geçmişi ekranı.
/// Backend'den tüm görevleri çekip 3 tab'a ayırır: Aktif, Tamamlanan, İptal.
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() =>
      _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _allTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final tasks = await taskRepo.getMyTasks();
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _allTasks.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(2000);
            final bDate = b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate); // yeniden eskiye
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading order history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Task> get _completedTasks =>
      _allTasks.where((t) => t.status == TaskStatus.COMPLETED).toList();

  List<Task> get _cancelledTasks =>
      _allTasks.where((t) => t.status == TaskStatus.CANCELLED).toList();

  List<Task> get _activeTasks => _allTasks
      .where((t) =>
          t.status != TaskStatus.COMPLETED && t.status != TaskStatus.CANCELLED)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF4), Color(0xFFD1FAE5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Header ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: const Color(0xFF374151),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sipariş Geçmişi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Tüm siparişlerinizi görüntüleyin',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_allTasks.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Tab Bar ────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline, size: 16),
                          const SizedBox(width: 4),
                          Text('Aktif (${_activeTasks.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16),
                          const SizedBox(width: 4),
                          Text('Biten (${_completedTasks.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cancel_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text('İptal (${_cancelledTasks.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Tab Content ────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTaskList(_activeTasks, 'Aktif sipariş yok'),
                          _buildTaskList(
                            _completedTasks,
                            'Tamamlanan sipariş yok',
                          ),
                          _buildTaskList(
                            _cancelledTasks,
                            'İptal edilen sipariş yok',
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String emptyMessage) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _OrderHistoryCard(task: tasks[index]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Sipariş kartı — genişleyebilir detay
// ─────────────────────────────────────────────────────────
class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(task.status.colorValue).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(task.status),
              size: 20,
              color: Color(task.status.colorValue),
            ),
          ),
          title: Text(
            'Sipariş #${task.id.length >= 8 ? task.id.substring(0, 8) : task.id}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      Color(task.status.colorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(task.status.colorValue),
                  ),
                ),
              ),
              const Spacer(),
              if (task.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDate(task.createdAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
            ],
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // Alışveriş listesi
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Alışveriş Listesi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...task.shoppingList.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      task.status == TaskStatus.COMPLETED
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 14,
                      color: task.status == TaskStatus.COMPLETED
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD1D5DB),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF4B5563),
                          decoration: task.status == TaskStatus.COMPLETED
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Not
            if (task.note != null && task.note!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.note!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Fiyat bilgileri (tamamlanmış görevlerde)
            if (task.status == TaskStatus.COMPLETED &&
                (task.totalAmountGiven != null ||
                    task.changeAmount != null)) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    if (task.totalAmountGiven != null)
                      _PriceRow(
                        label: 'Verilen',
                        value:
                            '₺${task.totalAmountGiven!.toStringAsFixed(2)}',
                      ),
                    if (task.changeAmount != null)
                      _PriceRow(
                        label: 'Para üstü',
                        value:
                            '₺${task.changeAmount!.toStringAsFixed(2)}',
                      ),
                    if (task.totalAmountGiven != null &&
                        task.changeAmount != null) ...[
                      const Divider(
                        height: 12,
                        color: Color(0xFFBBF7D0),
                      ),
                      _PriceRow(
                        label: 'Toplam harcama',
                        value:
                            '₺${(task.totalAmountGiven! - task.changeAmount!).toStringAsFixed(2)}',
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.PENDING:
        return Icons.hourglass_bottom_rounded;
      case TaskStatus.ASSIGNED:
        return Icons.directions_walk_rounded;
      case TaskStatus.IN_PROGRESS:
        return Icons.shopping_cart_rounded;
      case TaskStatus.DELIVERED:
        return Icons.local_shipping_rounded;
      case TaskStatus.COMPLETED:
        return Icons.check_circle_rounded;
      case TaskStatus.CANCELLED:
        return Icons.cancel_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';

    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────
// Fiyat satırı
// ─────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: const Color(0xFF374151),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}
