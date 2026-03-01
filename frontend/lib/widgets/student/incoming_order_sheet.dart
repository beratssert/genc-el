import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';

// ---------------------------------------------------------------------------
// Gelen sipariş için hafif model (gerçek API'den gelecek)
// ---------------------------------------------------------------------------
class IncomingOrder {
  const IncomingOrder({
    required this.id,
    required this.elderlyName,
    required this.distanceKm,
    required this.shoppingList,
    this.note,
    this.estimatedMinutes = 15,
  });

  final int id;
  final String elderlyName;
  final double distanceKm;
  final List<ShoppingItem> shoppingList;
  final String? note;

  /// Tahmini alışveriş süresi (dakika)
  final int estimatedMinutes;
}

// ---------------------------------------------------------------------------
// Tam ekran bildirim sayfası — showGeneralDialog ile açılır
// ---------------------------------------------------------------------------

/// [IncomingOrderSheet]'i tam ekran olarak göster.
/// [onAccepted] veya [onRejected] callback döndükten sonra dialog kapanır.
Future<bool?> showIncomingOrderSheet(
  BuildContext context, {
  required IncomingOrder order,
  VoidCallback? onAccepted,
  VoidCallback? onRejected,
  int countdownSeconds = 600, // 10 dakika
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (ctx, anim, _, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
    pageBuilder: (ctx, a1, a2) => IncomingOrderSheet(
      order: order,
      countdownSeconds: countdownSeconds,
      onAccepted: () {
        onAccepted?.call();
        Navigator.of(ctx).pop(true);
      },
      onRejected: () {
        onRejected?.call();
        Navigator.of(ctx).pop(false);
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class IncomingOrderSheet extends StatefulWidget {
  const IncomingOrderSheet({
    super.key,
    required this.order,
    required this.onAccepted,
    required this.onRejected,
    this.countdownSeconds = 600,
  });

  final IncomingOrder order;
  final VoidCallback onAccepted;
  final VoidCallback onRejected;
  final int countdownSeconds;

  @override
  State<IncomingOrderSheet> createState() => _IncomingOrderSheetState();
}

class _IncomingOrderSheetState extends State<IncomingOrderSheet>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds;

    // Geri sayım
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        widget.onRejected(); // Süre dolunca otomatik reddet
      }
    });

    // Puls animasyonu (ikon için)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _timerLabel {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remaining > 120) return const Color(0xFF2563EB);
    if (_remaining > 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // --- Üst: puls ikon + başlık ---
                _PulseIcon(controller: _pulseController),
                const SizedBox(height: 20),
                const Text(
                  'Yeni Görev!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kabul etmek için $_timerLabel süren var.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _timerColor == const Color(0xFF2563EB)
                        ? Colors.white70
                        : _timerColor,
                  ),
                ),
                const SizedBox(height: 28),

                // --- Bilgi kartı ---
                Expanded(
                  child: _OrderInfoCard(
                    order: widget.order,
                    timerLabel: _timerLabel,
                    timerColor: _timerColor,
                  ),
                ),
                const SizedBox(height: 24),

                // --- Butonlar ---
                _ActionRow(
                  onAccepted: widget.onAccepted,
                  onRejected: widget.onRejected,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsating icon
// ---------------------------------------------------------------------------
class _PulseIcon extends StatelessWidget {
  const _PulseIcon({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context2, child) {
        final scale = 1.0 + controller.value * 0.15;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sipariş detay kartı
// ---------------------------------------------------------------------------
class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
    required this.order,
    required this.timerLabel,
    required this.timerColor,
  });

  final IncomingOrder order;
  final String timerLabel;
  final Color timerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mesafe + süre rozetleri
            Row(
              children: [
                _InfoChip(
                  icon: Icons.place_rounded,
                  label: '${order.distanceKm.toStringAsFixed(1)} km',
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.timer_rounded,
                  label: 'yaklaşık ${order.estimatedMinutes} dk',
                  color: const Color(0xFF16A34A),
                ),
                const Spacer(),
                // Geri sayım
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: timerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: timerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    timerLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: timerColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sipariş sahibi
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.elderly_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sipariş Eden',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    Text(
                      order.elderlyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ürün listesi başlığı
            const Text(
              'ALIŞVERİŞ LİSTESİ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...order.shoppingList.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
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

            // Not (varsa)
            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
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
                        order.note!,
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bilgi rozeti
// ---------------------------------------------------------------------------
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kabul Et / Reddet butonları
// ---------------------------------------------------------------------------
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onAccepted, required this.onRejected});

  final VoidCallback onAccepted;
  final VoidCallback onRejected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Reddet
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRejected,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reddet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Kabul Et
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: onAccepted,
            icon: const Icon(Icons.check_rounded, size: 22),
            label: const Text('Kabul Et'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1D4ED8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
