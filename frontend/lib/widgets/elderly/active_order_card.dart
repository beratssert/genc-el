import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';

/// Aktif sipariş varsa detaylarını, yoksa "sipariş yok" boş durumunu gösterir.
class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({super.key, this.activeTask});

  /// null ise aktif sipariş yok demektir.
  final TaskModel? activeTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Aktif Siparişim'),
        const SizedBox(height: 10),
        activeTask != null
            ? _ActiveTaskContent(task: activeTask!)
            : const _EmptyOrderState(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Aktif sipariş varken gösterilecek içerik
// ---------------------------------------------------------------------------
class _ActiveTaskContent extends StatelessWidget {
  const _ActiveTaskContent({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(task.status.colorValue);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          // --- Durum başlığı ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  task.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Öğrenci bilgisi (varsa) ---
                if (task.volunteerName != null) ...[
                  _InfoRow(
                    icon: Icons.school_outlined,
                    label: 'Öğrenci',
                    value: task.volunteerName!,
                  ),
                  const SizedBox(height: 8),
                ],

                // --- Alışveriş listesi ---
                const Text(
                  'Alışveriş Listesi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                ...task.shoppingList.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _ShoppingItemRow(item: item),
                  ),
                ),

                // --- Para bilgisi: sadece para teslim EDİLMİŞ durumlarda göster ---
                if (task.totalAmountGiven != null &&
                    (task.status == TaskStatus.shopping ||
                        task.status == TaskStatus.atHomeFinal ||
                        task.status == TaskStatus.completed)) ...[
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Verilen Para',
                    value: '${task.totalAmountGiven!.toStringAsFixed(0)} ₺',
                  ),
                ],

                // --- Not (varsa) ---
                if (task.note != null && task.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Not',
                    value: task.note!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingItemRow extends StatelessWidget {
  const _ShoppingItemRow({required this.item});

  final ShoppingItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          ),
        ),
        Text(
          '${item.qty} ${item.unit}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Aktif sipariş yokken gösterilecek boş durum
// ---------------------------------------------------------------------------
class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // gray-50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 40,
            color: Color(0xFFD1D5DB), // gray-300
          ),
          SizedBox(height: 10),
          Text(
            'Aktif siparişiniz bulunmuyor',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Yeni bir alışveriş oluşturabilirsiniz.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yeniden kullanılabilir bölüm başlığı
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }
}
