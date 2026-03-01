import 'package:flutter/material.dart';
import '../../core/data/demo_products.dart';
import '../../core/models/product_model.dart';
import '../../widgets/order/order_item_row.dart';

/// Sipariş özet ekranı.
/// - Sepetteki tüm ürünlerin listesini gösterir.
/// - Ürün miktarları buradan da düzenlenebilir.
/// - "Siparişi Onayla" → onay dialog'u → ana sayfaya dön.
class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({
    super.key,
    required this.cart,
    required this.onCartChanged,
  });

  final Map<int, int> cart;
  final VoidCallback onCartChanged;

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<Product> get _cartProducts {
    return demoProducts.where((p) => (widget.cart[p.id] ?? 0) > 0).toList();
  }

  int get _totalItems => widget.cart.values.fold(0, (a, b) => a + b);

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

  Future<void> _showConfirmDialog() async {
    final note = _noteController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmDialog(
        totalItems: _totalItems,
        productCount: _cartProducts.length,
        note: note.isNotEmpty ? note : null,
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: API çağrısı: POST /api/v1/tasks
      // Body: { shopping_list: [...], note: note }
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Siparişiniz oluşturuldu! Öğrenci aranıyor…'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _cartProducts;

    return Scaffold(
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
              _SummaryAppBar(),
              Expanded(
                child: products.isEmpty
                    ? const _EmptyCartState()
                    : _SummaryList(
                        products: products,
                        cart: widget.cart,
                        onIncrement: _increment,
                        onDecrement: _decrement,
                        totalItems: _totalItems,
                        noteController: _noteController,
                      ),
              ),
              if (products.isNotEmpty)
                _ConfirmButton(onTap: _showConfirmDialog),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar
// ---------------------------------------------------------------------------
class _SummaryAppBar extends StatelessWidget {
  const _SummaryAppBar();

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
                'Sipariş Özeti',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Listeni kontrol et',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ürün listesi + toplam bilgisi
// ---------------------------------------------------------------------------
class _SummaryList extends StatelessWidget {
  const _SummaryList({
    required this.products,
    required this.cart,
    required this.onIncrement,
    required this.onDecrement,
    required this.totalItems,
    required this.noteController,
  });

  final List<Product> products;
  final Map<int, int> cart;
  final void Function(int) onIncrement;
  final void Function(int) onDecrement;
  final int totalItems;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      children: [
        _SummaryBanner(itemTypeCount: products.length, totalItems: totalItems),
        const SizedBox(height: 16),

        // Ürün listesi kartı
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ...products.asMap().entries.map((entry) {
                final product = entry.value;
                return Column(
                  children: [
                    OrderItemRow(
                      product: product,
                      quantity: cart[product.id] ?? 0,
                      onIncrement: () => onIncrement(product.id),
                      onDecrement: () => onDecrement(product.id),
                    ),
                    if (entry.key < products.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Not alanı
        _NoteField(controller: noteController),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Özet banner (yeşil, toplam ürün sayısı)
// ---------------------------------------------------------------------------
class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.itemTypeCount, required this.totalItems});

  final int itemTypeCount;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toplam Ürün',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              Text(
                '$totalItems adet / $itemTypeCount çeşit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onayla butonu (alt)
// ---------------------------------------------------------------------------
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Siparişi Onayla'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boş sepet durumu
// ---------------------------------------------------------------------------
class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Color(0xFFD1D5DB),
            ),
            SizedBox(height: 16),
            Text(
              'Sepetiniz boş',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Kategorilerden ürün ekleyin.',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onay diyaloğu
// ---------------------------------------------------------------------------
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.totalItems,
    required this.productCount,
    this.note,
  });

  final int totalItems;
  final int productCount;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Text('🛒', style: TextStyle(fontSize: 24)),
          SizedBox(width: 10),
          Text(
            'Emin misiniz?',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aşağıdaki bilgilerle sipariş oluşturulacak:',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 14),
          _DialogInfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Ürün çeşidi',
            value: '$productCount çeşit',
          ),
          const SizedBox(height: 6),
          _DialogInfoRow(
            icon: Icons.format_list_numbered_rounded,
            label: 'Toplam adet',
            value: '$totalItems adet',
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            _DialogInfoRow(
              icon: Icons.sticky_note_2_outlined,
              label: 'Not',
              value: note!,
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Onayladıktan sonra yakınındaki öğrenciler bilgilendirilecek.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Evet, Onayla'),
        ),
      ],
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({
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
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Not alanı widget'ı
// ---------------------------------------------------------------------------
class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 16,
                color: Color(0xFF16A34A),
              ),
              SizedBox(width: 6),
              Text(
                'Not Ekle (İsteğe bağlı)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'Örn: "Zili çalmayın, kapıyı tıklatın." veya özel istekler…',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFD1D5DB),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF16A34A),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
