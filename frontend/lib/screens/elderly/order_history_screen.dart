import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';
import '../../widgets/elderly/order_history_card.dart';

/// Yaşlı kullanıcısının tamamlanmış/iptal siparişlerini listeleyen sayfa.
///
/// Özellikler:
/// - Üstte toplam sipariş sayısı özet kutusu
/// - Siparişler yeniden eskiye göre (createdAt) sıralanır
/// - Her kart dokunulduğunda ürün listesini açar (ExpansionTile)
/// - Liste boşsa özel boş durum ekranı gösterilir
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key, required this.completedTasks});

  final List<TaskModel> completedTasks;

  /// Siparişleri en yeniden en eskiye sıralar.
  List<TaskModel> get _sortedTasks {
    final sorted = List<TaskModel>.from(completedTasks);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedTasks;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AppBar ---
              _HistoryAppBar(),

              Expanded(
                child: sorted.isEmpty
                    ? const _EmptyHistoryState()
                    : _HistoryList(tasks: sorted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Özel AppBar
// ---------------------------------------------------------------------------
class _HistoryAppBar extends StatelessWidget {
  const _HistoryAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: const Color(0xFF374151),
          ),
          const Text(
            'Geçmiş Siparişler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sipariş listesi: özet kutusu + kartlar
// ---------------------------------------------------------------------------
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.tasks});

  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: tasks.length + 1, // +1 → özet kutusu
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SummaryBanner(totalCount: tasks.length);
        }
        final task = tasks[index - 1];
        return OrderHistoryCard(
          task: task,
          index: tasks.length - (index - 1), // En yeni = en büyük numara
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Toplam sipariş sayısı özet kutusu
// ---------------------------------------------------------------------------
class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A), // green-600
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toplam Sipariş',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              Text(
                '$totalCount sipariş',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Geçmiş yokken boş durum
// ---------------------------------------------------------------------------
class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: Color(0xFFD1D5DB),
            ),
            SizedBox(height: 16),
            Text(
              'Henüz siparişiniz yok',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tamamlanan alışverişler burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
