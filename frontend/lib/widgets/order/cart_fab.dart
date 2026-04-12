import 'package:flutter/material.dart';

/// Her sayfanın sağ altında duran sepet FAB'ı.
/// Sepet boşsa gösterilmez.
class CartFab extends StatelessWidget {
  const CartFab({super.key, required this.totalItems, required this.onTap});

  final int totalItems;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: const Color(0xFF16A34A),
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.shopping_cart_outlined),
      label: Row(
        children: [
          const Text(
            'Sipariş Özeti',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalItems',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
