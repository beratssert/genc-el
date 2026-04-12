import 'package:flutter/material.dart';

/// Ana sayfanın alt kısmındaki aksiyon butonları:
/// "Yeni Alışveriş Oluştur" (birincil) ve "Geçmiş Siparişler" (ikincil).
class HomeActionButtons extends StatelessWidget {
  const HomeActionButtons({
    super.key,
    required this.onCreateOrder,
    required this.onViewHistory,
    this.isOrderActive = false,
  });

  final VoidCallback onCreateOrder;
  final VoidCallback onViewHistory;

  /// Aktif sipariş varken "Yeni Oluştur" butonu devre dışı bırakılır.
  final bool isOrderActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Birincil aksiyon: Yeni alışveriş ---
        FilledButton.icon(
          onPressed: isOrderActive ? null : onCreateOrder,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: Text(
            isOrderActive ? 'Aktif Siparişiniz Var' : 'Yeni Alışveriş Oluştur',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            disabledBackgroundColor: const Color(0xFFD1FAE5),
            disabledForegroundColor: const Color(0xFF6B7280),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // --- İkincil aksiyon: Geçmiş siparişler ---
        OutlinedButton.icon(
          onPressed: onViewHistory,
          icon: const Icon(Icons.history_rounded),
          label: const Text('Geçmiş Siparişler'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF16A34A),
            side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
