import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../core/utils/string_extensions.dart';

/// Öğrenciye atanmış aktif görev kartı.
/// Görev yoksa "Yeni görev bekleniyor" boş durumu gösterilir.
class StudentTaskCard extends StatelessWidget {
  const StudentTaskCard({
    super.key,
    this.activeTask,
    this.isAvailable = true,
    this.onStart,
    this.onDeliver,
    this.onCancel,
    this.onReject,
  });

  /// null → aktif görev yok.
  final Task? activeTask;
  final bool isAvailable;

  /// Eylem geri çağırmaları
  final VoidCallback? onStart;
  final VoidCallback? onDeliver;
  final VoidCallback? onCancel;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Aktif Görevim'),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: activeTask != null
              ? _ActiveTaskContent(
                  key: ValueKey(activeTask!.id),
                  task: activeTask!,
                  onStart: onStart,
                  onDeliver: onDeliver,
                  onCancel: onCancel,
                  onReject: onReject,
                )
              : _NoTaskState(key: const ValueKey('empty'), isAvailable: isAvailable),
        ),
      ],
    );
  }
}

class _ActiveTaskContent extends StatelessWidget {
  const _ActiveTaskContent({
    super.key,
    required this.task,
    this.onStart,
    this.onDeliver,
    this.onCancel,
    this.onReject,
  });

  final Task task;
  final VoidCallback? onStart;
  final VoidCallback? onDeliver;
  final VoidCallback? onCancel;
  final VoidCallback? onReject;

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
                const Spacer(),
                Text(
                  '#${task.id.safeSubstring(0, 8)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
                  value: 'Yaşlı #${task.requesterId?.safeSubstring(0, 5) ?? 'ID Yok'}',
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

                // Para
                if (task.totalAmountGiven != null) ...[
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Verilen para',
                    value: '${task.totalAmountGiven!.toStringAsFixed(0)} ₺',
                  ),
                ],

                // Not (varsa)
                if (task.note != null && task.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.note!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Eylem Butonları
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
    final status = task.status;

    // 1. Alışverişe Başla (ASSIGNED durumunda)
    if (status == TaskStatus.ASSIGNED && onStart != null) {
      final isStartConfirmed = task.startConfirmed ?? false;
      return Column(
        children: [
          if (isStartConfirmed)
            _largeButton(
              'Alışverişe Başla',
              Icons.play_arrow_rounded,
              const Color(0xFF8B5CF6),
              onStart!,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 20, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text(
                    'Yaşlının onayı bekleniyor...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (onReject != null) ...[
            const SizedBox(height: 8),
            _outlineButton(
              'Görevi Reddet',
              Icons.close,
              Colors.orange.shade700,
              onReject!,
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            _outlineButton(
              'Görevi İptal Et',
              Icons.cancel_outlined,
              Colors.red.shade400,
              onCancel!,
            ),
          ],
        ],
      );
    }

    // 2. Teslim Et (IN_PROGRESS durumunda)
    if (status == TaskStatus.IN_PROGRESS && onDeliver != null) {
      return Column(
        children: [
          _largeButton(
            'Teslim Et',
            Icons.local_shipping_outlined,
            const Color(0xFF06B6D4),
            onDeliver!,
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            _outlineButton(
              'Görevi İptal Et',
              Icons.cancel_outlined,
              Colors.red.shade400,
              onCancel!,
            ),
          ],
        ],
      );
    }

    // 3. Bekleme Durumu (DELIVERED durumunda)
    if (status == TaskStatus.DELIVERED) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '⌛ Yaşlı kullanıcının onayı bekleniyor...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    // 4. İptal Etme (Diğer durumlar için)
    if (status != TaskStatus.DELIVERED &&
        status != TaskStatus.COMPLETED &&
        onCancel != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _outlineButton(
          'Görevi İptal Et',
          Icons.cancel_outlined,
          Colors.red.shade400,
          onCancel!,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _largeButton(String label, IconData icon, Color color, VoidCallback onTap) {
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

  Widget _outlineButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _NoTaskState extends StatelessWidget {
  const _NoTaskState({super.key, required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
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
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            isAvailable ? 'Yeni görev bekleniyor…' : 'Müsaitlik kapalı',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAvailable
                ? 'Yakındaki bir sipariş sizi bilgilendirecek.'
                : 'Aktif olmak için yukarıdaki anahtarı açın.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemRow extends StatelessWidget {
  const _ShoppingItemRow({required this.item});

  final String item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }
}
