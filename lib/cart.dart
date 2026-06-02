import 'package:flutter/material.dart';
import 'cart_manager.dart';
import 'takeout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);

  @override
  void initState() {
    super.initState();
    CartManager.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  String _formatRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';
  }

  int _calculateItemTotal(Map<String, dynamic> item) {
    int price = (item['basePrice'] as int?) ?? 0;
    final Map<String, int> addonOpts = Map<String, int>.from((item['addonOptions'] as Map?) ?? {});
    final List<String> currentAddons = List<String>.from((item['selectedAddons'] as List?) ?? []);

    for (var addon in currentAddons) {
      price += addonOpts[addon] ?? 0;
    }
    return price * ((item['quantity'] as int?) ?? 1);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartManager.instance.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "REVIEW ORDERS",
          style: TextStyle(
            color: darkGrey,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: darkGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartCard(item, index);
                    },
                  ),
                ),
                _buildStickyBottomPanel(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: primaryGreen.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "Keranjangmu masih kosong nih!",
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Yuk, kembali ke menu untuk memilih Rafdah Delight.",
            style: TextStyle(color: darkGrey.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Lihat Menu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildCartCard(Map<String, dynamic> item, int index) {
    final int itemTotal = _calculateItemTotal(item);
    final List<String> addons = List<String>.from(item['selectedAddons'] ?? []);
    final String spice = item['selectedSpice'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE2B9).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.white24,
              child: item['img'] != null && item['img'].toString().startsWith('assets')
                  ? Image.asset(item['img'], fit: BoxFit.cover)
                  : const Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (spice.isNotEmpty || addons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      [
                        if (spice.isNotEmpty) "Level: $spice",
                        if (addons.isNotEmpty) "Add-ons: ${addons.join(', ')}"
                      ].join(' | '),
                      style: TextStyle(color: darkGrey, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                Text(
                  _formatRp(itemTotal),
                  style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                alignment: Alignment.topRight,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => CartManager.instance.removeAt(index),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQtyBtn(
                    icon: Icons.remove,
                    onPressed: () {
                      int currentQty = item['quantity'] ?? 1;
                      CartManager.instance.updateQuantity(index, currentQty - 1);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "${item['quantity'] ?? 1}",
                      style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  _buildQtyBtn(
                    icon: Icons.add,
                    onPressed: () {
                      int currentQty = item['quantity'] ?? 1;
                      CartManager.instance.updateQuantity(index, currentQty + 1);
                    },
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQtyBtn({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: primaryGreen,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildStickyBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Total Pesanan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _formatRp(CartManager.instance.subtotal),
                  style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TakeoutPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                children: [
                  Text("Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}