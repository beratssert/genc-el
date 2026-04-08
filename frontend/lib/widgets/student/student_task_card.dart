import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';

/// Öğrenciye atanmış aktif görev kartı.
/// Görev yoksa "Yeni görev bekleniyor" boş durumu gösterilir.
class StudentTaskCard extends StatelessWidget {
  const StudentTaskCard({super.key, this.activeTask, this.isAvailable = true});

  /// null → aktif görev yok.
  final TaskModel? activeTask;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Aktif Görevim'),
        const SizedBox(height: 10),
        activeTask != null
            ? _ActiveTaskContent(task: activeTask!)
            : _NoTaskState(isAvailable: isAvailable),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Aktif görev varken
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Durum şeridi
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
                // Sipariş sahibi bilgisi
                _InfoRow(
                  icon: Icons.elderly_outlined,
                  label: 'Sipariş eden',
                  value: task.volunteerName ?? 'İsimsiz',
                ),
                const SizedBox(height: 8),

                // Alışveriş listesi başlığı
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

                // Para (yalnızca teslim sonrası durumlarda)
                if (task.totalAmountGiven != null &&
                    (task.status == TaskStatus.shopping ||
                        task.status == TaskStatus.atHomeFinal ||
                        task.status == TaskStatus.completed)) ...[
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Verilen para',
                    value: '${task.totalAmountGiven!.toStringAsFixed(0)} ₺',
                  ),
                ],

                // Not (varsa)
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

// ---------------------------------------------------------------------------
// Görev yokken
// ---------------------------------------------------------------------------
class _NoTaskState extends StatelessWidget {
  const _NoTaskState({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            isAvailable
                ? Icons.hourglass_top_rounded
                : Icons.pause_circle_outline_rounded,
            size: 48,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 10),
          Text(
            isAvailable ? 'Yeni görev bekleniyor…' : 'Müsaitlik kapalı',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAvailable
                ? 'Yakındaki bir sipariş sizi bilgilendirecek.'
                : 'Aktif olmak için yukarıdaki anahtarı açın.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yardımcı widget'lar
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A5F),
      ),
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
