import 'package:flutter/material.dart';
import 'cart_manager.dart';
import 'payment.dart';

class TakeoutPage extends StatefulWidget {
  const TakeoutPage({super.key});

  @override
  State<TakeoutPage> createState() => _TakeoutPageState();
}

class _TakeoutPageState extends State<TakeoutPage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> get _cartItems => CartManager.instance.items;

  @override
  void initState() {
    super.initState();
    CartManager.instance.addListener(_onCartChange);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChange);
    _notesController.dispose();
    super.dispose();
  }

  void _onCartChange() => setState(() {});

  // --- 1. KALKULASI TOTAL & PAJAK (Sesuai Request) ---
  int get _subtotal {
    int total = 0;
    for (var item in _cartItems) {
      int itemCost = (item['basePrice'] as int?) ?? 0;
      final Map<String, int> addonOpts = Map<String, int>.from((item['addonOptions'] as Map?) ?? {});
      final List<String> currentAddons = List<String>.from((item['selectedAddons'] as List?) ?? []);

      for (var addon in currentAddons) {
        itemCost += addonOpts[addon] ?? 0;
      }
      total += itemCost * ((item['quantity'] as int?) ?? 1);
    }
    return total;
  }

  int get _discount => _subtotal > 50000 ? 15000 : 0;
  int get _pb1 => (_subtotal * 0.10).round(); // Pajak PB1 10%
  int get _vat => (_subtotal * 0.11).round(); // PPN 11%
  int get _finalTotal => _subtotal - _discount + _pb1 + _vat;
  
  // --- 2. KALKULASI STAMPS ---
  int get _stampsEarned => _finalTotal > 0 ? (_finalTotal / 30000).floor().clamp(0, 10) : 0;

  String _formatRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("YOUR CART", style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 16)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: darkGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
          
                _buildSectionHeader("ORDER ITEMS"),
                _buildCartItemList(),
                const SizedBox(height: 24),

                // Menampilkan Total & Taxes di Cart (Sesuai Request)
                _buildSectionHeader("SUMMARY & TAXES"),
                _buildSummaryCard(),
                const SizedBox(height: 24),
                
                // Menampilkan Stamps di Cart
                _buildSectionHeader("MEMBER REWARDS"),
                _buildStampSection(),
                
                _buildSectionHeader("CUSTOMER INFO & NOTES"),

                _buildContactField(),
                const SizedBox(height: 12),
                _buildNotesField(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildStickyBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(title, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 12)),
  );

  Widget _buildCartItemList() {
    if (_cartItems.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Text("Your cart is empty.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(item['img'] ?? 'assets/images/prod_triple_brew.png', width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        Text(_formatRp((item['basePrice'] as int?) ?? 0), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => CartManager.instance.updateQuantity(index, (item['quantity'] ?? 1) - 1)),
                      Text("${item['quantity'] ?? 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => CartManager.instance.updateQuantity(index, (item['quantity'] ?? 1) + 1)),
                    ],
                  )
                ],
              ),
              const Divider(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showCustomizationSheet(context, item), // Tombol Modify di Cart
                  icon: Icon(Icons.edit, size: 14, color: primaryGreen),
                  label: Text("Modify Item", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        _buildRowItem("Subtotal", _formatRp(_subtotal)),
        _buildRowItem("Promo", "- ${_formatRp(_discount)}", valColor: Colors.red),
        _buildRowItem("Tax (PB1 10%)", _formatRp(_pb1)),
        _buildRowItem("VAT (11%)", _formatRp(_vat)),
        const Divider(),
        _buildRowItem("Total Payable", _formatRp(_finalTotal), isBold: true),
      ],
    ),
  );

  Widget _buildRowItem(String label, String value, {bool isBold = false, Color? valColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valColor ?? (isBold ? primaryGreen : Colors.black87), fontSize: isBold ? 16 : 14)),
      ],
    ),
  );

  Widget _buildStampSection() => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Stamp Accrual Progress", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text("+$_stampsEarned Stamps Pending", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
      const SizedBox(height: 14),
      // BARIS 1: stamps 1-5
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (i) => _buildStampSlot(i)),
      ),
      const SizedBox(height: 8),
      // BARIS 2: stamps 6-10
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (i) => _buildStampSlot(i + 5)),
      ),
    ],
  ),
);

Widget _buildStampSlot(int index) {
  final bool isEarned = index < _stampsEarned;
  return AnimatedScale(
    scale: isEarned ? 1.0 : 0.85,
    duration: const Duration(milliseconds: 300),
    child: Opacity(
      opacity: isEarned ? 1.0 : 0.35,
      child: Image.asset('assets/images/stamp.png', width: 34, height: 34,
          errorBuilder: (_, __, ___) => Icon(Icons.stars, color: primaryGreen, size: 34)),
    ),
  );
}


  Widget _buildContactField() => const TextField(
    keyboardType: TextInputType.phone,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      labelText: "PHONE NUMBER",
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      filled: true, fillColor: Colors.white,
    ),
  );

  Widget _buildNotesField() => TextField(
    controller: _notesController,
    maxLines: 2,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    decoration: const InputDecoration(
      labelText: "NOTES (OPTIONAL)",
      hintText: "e.g., Less ice, separate sugar...",
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      filled: true, fillColor: Colors.white,
    ),
  );

  Widget _buildStickyBottomPanel() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))]),
    child: SafeArea(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: () {
          if (_cartItems.isEmpty) return;
          // Lempar Total dan Stamps ke halaman Payment
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => PaymentPage(orderType: 'Takeout', totalAmount: _finalTotal, stampsEarned: _stampsEarned),
          ));
        },
        child: const Text("Proceed to Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    ),
  );

  void _showCustomizationSheet(BuildContext context, Map<String, dynamic> item) {
    // Logika Modifier sama seperti menu_page
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<String> spiceOpts = List<String>.from(item['spiceOptions'] ?? []);
            final Map<String, int> addonOpts = Map<String, int>.from(item['addonOptions'] ?? {});
            final List<String> itemSelectedAddons = List<String>.from(item['selectedAddons'] ?? []);

            return Container(
              decoration: const BoxDecoration(color: Color(0xFFF4F1E1), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Modify ${item['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  if (spiceOpts.isNotEmpty) ...[
                    Text("PREFERENCES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryGreen)),
                    Wrap(
                      spacing: 8,
                      children: spiceOpts.map((opt) {
                        bool isSel = item['selectedSpice'] == opt;
                        return ChoiceChip(
                          label: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.black)),
                          selected: isSel, selectedColor: primaryGreen,
                          onSelected: (val) { setModalState(() => item['selectedSpice'] = opt); setState(() {}); },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (addonOpts.isNotEmpty) ...[
                    Text("ADD-ONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryGreen)),
                    ...addonOpts.keys.map((addonKey) {
                      bool hasAddon = itemSelectedAddons.contains(addonKey);
                      return CheckboxListTile(
                        title: Text(addonKey), subtitle: Text("+ ${_formatRp(addonOpts[addonKey] ?? 0)}"),
                        value: hasAddon, activeColor: primaryGreen,
                        onChanged: (checked) {
                          setModalState(() {
                            checked == true ? itemSelectedAddons.add(addonKey) : itemSelectedAddons.remove(addonKey);
                            item['selectedAddons'] = itemSelectedAddons;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ],
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: darkGrey, minimumSize: const Size(double.infinity, 48)),
                    child: const Text("Apply Changes", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}