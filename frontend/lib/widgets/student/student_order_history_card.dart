import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';

/// Öğrenci geçmiş siparişler listesinde tek bir görev (sipariş) kartı.
/// Mavi tema kullanılarak yaşlı ekranındaki yapıyla birebir aynı işlevsellik sunar.
class StudentOrderHistoryCard extends StatelessWidget {
  const StudentOrderHistoryCard({
    super.key,
    required this.task,
    required this.index,
  });

  final TaskModel task;
  final int index;

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(task.status.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          leading: _OrderIndexBadge(index: index),
          title: _OrderTitle(task: task),
          subtitle: _OrderMeta(task: task, statusColor: statusColor),
          children: [
            const SizedBox(height: 4),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _ShoppingItemList(items: task.shoppingList),
            if (_hasFinancialData) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _FinancialSummary(task: task),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasFinancialData =>
      task.shoppingCost != null ||
      task.totalAmountGiven != null ||
      task.changeAmount != null;
}

// ---------------------------------------------------------------------------
// Sipariş numarası rozeti (Mavi Tema)
// ---------------------------------------------------------------------------
class _OrderIndexBadge extends StatelessWidget {
  const _OrderIndexBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE), // blue-100
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '#$index',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB), // blue-600
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Başlık: tarih + saat
// ---------------------------------------------------------------------------
class _OrderTitle extends StatelessWidget {
  const _OrderTitle({required this.task});

  final TaskModel task;

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 5),
        Text(
          _formatDate(task.createdAt),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(
          Icons.access_time_rounded,
          size: 14,
          color: Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 4),
        Text(
          _formatTime(task.createdAt),
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Alt başlık: Yaşlı adı + durum rozeti
// ---------------------------------------------------------------------------
class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.task, required this.statusColor});

  final TaskModel task;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          // Öğrenci yerine Yaşlı İkonu ve ismi
          const Icon(Icons.elderly_rounded, size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 4),
          Text(
            task.elderlyName ?? 'Bilinmeyen Yaşlı',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.status.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ürün listesi
// ---------------------------------------------------------------------------
class _ShoppingItemList extends StatelessWidget {
  const _ShoppingItemList({required this.items});

  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'Ürün listesi bulunamadı.',
        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALIŞVERİŞ LİSTESİ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 5, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                Text(
                  '${item.qty} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Finansal özet: Alışveriş Tutarı / Teslim Edilen / İade Alınan
// ---------------------------------------------------------------------------
class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FİNANSAL ÖZET',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (task.shoppingCost != null)
              Expanded(
                child: _FinancialCell(
                  label: 'Alışveriş\nTutarı',
                  value: '${task.shoppingCost!.toStringAsFixed(0)} ₺',
                  iconColor: const Color(0xFF6366F1), // indigo
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            if (task.totalAmountGiven != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _FinancialCell(
                  label: 'Teslim\nEdilen',
                  value: '${task.totalAmountGiven!.toStringAsFixed(0)} ₺',
                  iconColor: const Color(0xFF3B82F6), // blue
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
            if (task.changeAmount != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _FinancialCell(
                  label: 'İade\nAlınan',
                  value: '${task.changeAmount!.toStringAsFixed(0)} ₺',
                  iconColor: const Color(0xFF16A34A), // green
                  icon: Icons.currency_lira_rounded,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _FinancialCell extends StatelessWidget {
  const _FinancialCell({
    required this.label,
    required this.value,
    required this.iconColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: iconColor.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
