import 'package:flutter/material.dart';
import 'package:tdp_frontend/core/models/task_model.dart';
import '../../core/data/demo_products.dart';
import '../../core/models/product_model.dart';
import '../../widgets/order/product_card.dart';
import '../../widgets/order/cart_fab.dart';
import 'order_summary_screen.dart';

/// Seçilen kategoriye ait 3×3 ürün grid ekranı.
/// Cart güncelleri parent'a (CategoryScreen) callback ile iletilir.
class ProductScreen extends StatefulWidget {
  const ProductScreen({
    super.key,
    required this.category,
    required this.cart,
    required this.onCartChanged,
  });

  final Category category;

  /// CategoryScreen'den gelen ortak sepet referansı.
  final Map<int, int> cart;
  final VoidCallback onCartChanged;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final List<Product> _products;

  int get _totalItems => widget.cart.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _products = productsForCategory(widget.category.id);
  }

  void _increment(int productId) {
    setState(() {
      widget.cart[productId] = (widget.cart[productId] ?? 0) + 1;
    });
    widget.onCartChanged();
  }

  void _decrement(int productId) {
    final current = widget.cart[productId] ?? 0;
    if (current <= 1) {
      setState(() => widget.cart.remove(productId));
    } else {
      setState(() => widget.cart[productId] = current - 1);
    }
    widget.onCartChanged();
  }

  void _openSummary() async {
    final result = await Navigator.of(context).push<TaskModel>(
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          cart: widget.cart,
          onCartChanged: () {
            setState(() {});
            widget.onCartChanged();
          },
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CartFab(
        totalItems: _totalItems,
        onTap: _openSummary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF4), Color(0xFFD1FAE5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _ProductAppBar(category: widget.category),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ProductCard(
                        product: product,
                        quantity: widget.cart[product.id] ?? 0,
                        accentColor: widget.category.color,
                        onIncrement: () => _increment(product.id),
                        onDecrement: () => _decrement(product.id),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductAppBar extends StatelessWidget {
  const _ProductAppBar({required this.category});

  final Category category;

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
          Text(category.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Text(
                'Ürün seçin',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
