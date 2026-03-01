import 'package:flutter/material.dart';
import '../../core/models/product_model.dart';

/// Ürün sayfasındaki tek bir ürün kartı.
/// + / - butonlarıyla miktar artırılıp azaltılabilir.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.accentColor,
  });

  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isInCart = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInCart ? accentColor : const Color(0xFFE5E7EB),
          width: isInCart ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isInCart ? accentColor : Colors.black).withValues(
              alpha: 0.07,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ürün adı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isInCart ? accentColor : const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.unit,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 10),

          // Sayaç
          _QuantityCounter(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _QuantityCounter extends StatelessWidget {
  const _QuantityCounter({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.accentColor,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      // Sepette yoksa tek bir "+" butonu göster
      return SizedBox(
        width: 36,
        height: 36,
        child: FilledButton(
          onPressed: onIncrement,
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Icon(Icons.add, size: 20),
        ),
      );
    }

    // Sepette varsa -  N  + göster
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CounterButton(
            icon: Icons.remove,
            onTap: onDecrement,
            color: accentColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add,
            onTap: onIncrement,
            color: accentColor,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
