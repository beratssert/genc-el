import 'package:flutter/material.dart';
import 'package:tdp_frontend/core/models/task_model.dart';
import '../../core/data/demo_products.dart';
import '../../core/models/product_model.dart';
import '../../widgets/order/category_card.dart';
import '../../widgets/order/cart_fab.dart';
import 'product_screen.dart';
import 'order_summary_screen.dart';

/// Sipariş oluşturma akışının ilk adımı: 3×3 kategori seçim ekranı.
///
/// Sepet durumu (cart) burada tutulur ve alt ekranlara geçilir.
/// - ProductScreen'e aynı referans geçilir, değişiklikler anında yansır.
/// - FAB her zaman görünür; sepet özetine anında geçiş sağlar.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  /// productId → miktar
  final Map<int, int> _cart = {};

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);

  /// Bu kategoride sepete eklenmiş ürün var mı?
  bool _categoryHasItems(int categoryId) {
    final catProducts = productsForCategory(categoryId);
    return catProducts.any((p) => (_cart[p.id] ?? 0) > 0);
  }

  void _openProduct(Category category) async {
    final result = await Navigator.of(context).push<TaskModel>(
      MaterialPageRoute(
        builder: (_) => ProductScreen(
          category: category,
          cart: _cart,
          onCartChanged: () => setState(() {}),
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _openSummary() async {
    final result = await Navigator.of(context).push<TaskModel>(
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          cart: _cart,
          onCartChanged: () => setState(() {}),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryAppBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                    itemCount: demoCategories.length,
                    itemBuilder: (context, index) {
                      final cat = demoCategories[index];
                      return CategoryCard(
                        category: cat,
                        hasItems: _categoryHasItems(cat.id),
                        onTap: () => _openProduct(cat),
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

class _CategoryAppBar extends StatelessWidget {
  const _CategoryAppBar();

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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Seç',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Ne almak istersiniz?',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
