import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../core/utils/string_extensions.dart';

/// Aktif sipariş varsa detaylarını, yoksa "sipariş yok" boş durumunu gösterir.
class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({
    super.key,
    this.activeTask,
    this.onConfirmStart,
    this.onConfirmDelivery,
    this.onCancel,
    this.onUploadReceipt,
  });

  /// null ise aktif sipariş yok demektir.
  final Task? activeTask;

  /// Eylem geri çağırmaları
  final VoidCallback? onConfirmStart;
  final VoidCallback? onConfirmDelivery;
  final VoidCallback? onCancel;
  final VoidCallback? onUploadReceipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Aktif Siparişim'),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: activeTask != null
              ? _ActiveTaskContent(
                  key: ValueKey(activeTask!.id),
                  task: activeTask!,
                  onConfirmStart: onConfirmStart,
                  onConfirmDelivery: onConfirmDelivery,
                  onCancel: onCancel,
                  onUploadReceipt: onUploadReceipt,
                )
              : const _EmptyOrderState(key: ValueKey('empty')),
        ),
      ],
    );
  }
}

class _ActiveTaskContent extends StatelessWidget {
  const _ActiveTaskContent({
    super.key,
    required this.task,
    this.onConfirmStart,
    this.onConfirmDelivery,
    this.onCancel,
    this.onUploadReceipt,
  });

  final Task task;
  final VoidCallback? onConfirmStart;
  final VoidCallback? onConfirmDelivery;
  final VoidCallback? onCancel;
  final VoidCallback? onUploadReceipt;

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
                const Spacer(),
                Text(
                  '#${task.id.safeSubstring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
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
                // --- Öğrenci ID bilgisi (varsa) ---
                if (task.volunteerId != null) ...[
                  _InfoRow(
                    icon: Icons.school_outlined,
                    label: 'Öğrenci No',
                    value: task.volunteerId!.safeSubstring(0, 8),
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
                const SizedBox(height: 6),
                ...task.shoppingList.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _ShoppingItemRow(item: item),
                  ),
                ),

                // --- Not (varsa) ---
                if (task.note != null && task.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
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

                // --- Para bilgisi ---
                if (task.totalAmountGiven != null) ...[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Verilen Para',
                    value: '${task.totalAmountGiven!.toStringAsFixed(0)} ₺',
                  ),
                ],

                // --- Eylem Butonları ---
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    // 1. Başlangıcı Onayla (ASSIGNED durumunda)
    if (task.status == TaskStatus.ASSIGNED && onConfirmStart != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onConfirmStart,
          icon: const Icon(Icons.thumb_up_alt_outlined, size: 20),
          label: const Text('Başlangıcı Onayla (Öğrenci Geldi)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
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

    // 2. Teslimatı Onayla & Fiş Yükle (DELIVERED durumunda)
    if (task.status == TaskStatus.DELIVERED) {
      return Row(
        children: [
          if (onUploadReceipt != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUploadReceipt,
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Fiş Yükle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          if (onConfirmDelivery != null) ...[
            if (onUploadReceipt != null) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onConfirmDelivery,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Teslimatı Onayla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // 3. İptal Et (Sadece PENDING aşamasında)
    if (task.status == TaskStatus.PENDING && onCancel != null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel_outlined, size: 20),
          label: const Text('Siparişi İptal Et'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ShoppingItemRow extends StatelessWidget {
  const _ShoppingItemRow({required this.item});

  final String item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: Color(0xFF16A34A),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
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
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
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
            size: 48,
            color: Color(0xFFD1D5DB),
          ),
          SizedBox(height: 12),
          Text(
            'Aktif siparişiniz bulunmuyor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Yeni bir alışveriş oluşturarak başlayın.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

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
