import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'cart_manager.dart';
import 'payment.dart';
import 'menu_page.dart';

class TakeoutPage extends StatefulWidget {
  const TakeoutPage({super.key});

  @override
  State<TakeoutPage> createState() => _TakeoutPageState();
}

class _TakeoutPageState extends State<TakeoutPage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);
  final Color lightCream = const Color(0xFFEBE5D9);
  
  // Backend URL for fetching item images
  String get baseUrl => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000'; 
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

  // --- 1. TOTAL & TAX CALCULATION ---
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

  int get _pb1 => (_subtotal * 0.10).round(); // PB1 Tax 10%
  int get _vat => (_subtotal * 0.11).round(); // VAT 11%
  int get _finalTotal => _subtotal + _pb1 + _vat; // Subtotal + Taxes
  
  // --- 2. STAMPS CALCULATION ---
  int get _stampsEarned => _finalTotal > 0 ? (_finalTotal / 30000).floor().clamp(0, 10) : 0;

  String _formatRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("YOUR CART", style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 16)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
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
                
                // -------------------------------------------------------------
                // ADDED: LOCATION & DISTANCE COMPONENT
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lightGreenCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: primaryGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lumiora Coffee - Bekasi Outlet",
                              style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Distance: 1.2 km (Est. 10-15 mins)", // Translated to English
                              style: TextStyle(color: darkGrey, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // -------------------------------------------------------------

                _buildSectionHeader("ORDER ITEMS"),
                _buildCartItemList(),
                
                const SizedBox(height: 16),
                
                // Add Menu Button
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPage()));
                    },
                    icon: Icon(Icons.add, color: primaryGreen),
                    label: Text("Add Menu", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryGreen, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Total & Taxes
                _buildSectionHeader("SUMMARY & TAXES"),
                _buildSummaryCard(),
                
                const SizedBox(height: 24),
                
                // Stamps
                _buildSectionHeader("MEMBER REWARDS"),
                _buildStampSection(),
                
                const SizedBox(height: 24),

                // Customer Info & Notes
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
        
        // Calculate Item Value based on Quantity
        int basePrice = (item['basePrice'] as int?) ?? 0;
        final Map<String, int> addonOpts = Map<String, int>.from((item['addonOptions'] as Map?) ?? {});
        final List<String> currentAddons = List<String>.from((item['selectedAddons'] as List?) ?? []);
        
        int unitCost = basePrice;
        for (var addon in currentAddons) {
          unitCost += addonOpts[addon] ?? 0;
        }
        
        int qty = item['quantity'] ?? 1;
        int totalItemCost = unitCost * qty; // Total price multiplies dynamically

        // Construct Modifiers Text
        List<String> mods = [];
        if (item['selectedSpice'] != null && item['selectedSpice'] != 'Normal') {
          mods.add("Spice Level: ${item['selectedSpice']}");
        }
        if (currentAddons.isNotEmpty) {
          mods.add("Add-ons: ${currentAddons.join(', ')}");
        }
        String modText = mods.join(' | ');

        // -------------------------------------------------------------
        // ADDED: ROBUST IMAGE LOGIC FIX
        // -------------------------------------------------------------
        String rawImg = (item['image_url'] ?? item['img'] ?? '').toString();
        String imageUrl = '';
        bool isAsset = false;

        if (rawImg.isNotEmpty) {
          if (rawImg.startsWith('http')) {
            imageUrl = rawImg;
          } else if (rawImg.startsWith('assets/')) {
            isAsset = true;
            imageUrl = rawImg;
          } else {
            imageUrl = rawImg.startsWith('/') ? '$baseUrl$rawImg' : '$baseUrl/$rawImg';
          }
        }
        // -------------------------------------------------------------

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? (isAsset 
                        ? Image.asset(
                            imageUrl,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                          )
                        : Image.network(
                            imageUrl,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                          ))
                    : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    if (modText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(modText, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ),
                    const SizedBox(height: 4),
                    Text(_formatRp(totalItemCost), style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), 
                    onPressed: () => CartManager.instance.updateQuantity(index, qty - 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: primaryGreen), 
                    onPressed: () => CartManager.instance.updateQuantity(index, qty + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
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
        _buildRowItem("Restaurant Tax (PB1 10%)", _formatRp(_pb1)),
        _buildRowItem("VAT (11%)", _formatRp(_vat)),
        const Divider(height: 24),
        _buildRowItem("Total Payable", _formatRp(_finalTotal), isBold: true),
      ],
    ),
  );

  Widget _buildRowItem(String label, String value, {bool isBold = false, Color? valColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: isBold ? textDark : Colors.grey.shade700)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valColor ?? (isBold ? primaryGreen : textDark), fontSize: isBold ? 16 : 14)),
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
        // Row 1: stamps 1-5
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) => _buildStampSlot(i)),
        ),
        const SizedBox(height: 8),
        // Row 2: stamps 6-10
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

  Widget _buildContactField() => TextField(
    keyboardType: TextInputType.phone,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      labelText: "PHONE NUMBER",
      labelStyle: TextStyle(color: Colors.grey.shade600),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGreen, width: 2), borderRadius: const BorderRadius.all(Radius.circular(12))),
      filled: true, fillColor: Colors.white,
    ),
  );

  Widget _buildNotesField() => TextField(
    controller: _notesController,
    maxLines: 2,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      labelText: "NOTES (OPTIONAL)",
      labelStyle: TextStyle(color: Colors.grey.shade600),
      hintText: "e.g., Less ice, separate sugar...",
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGreen, width: 2), borderRadius: const BorderRadius.all(Radius.circular(12))),
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
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => PaymentPage(orderType: 'Takeout', totalAmount: _finalTotal, stampsEarned: _stampsEarned),
          ));
        },
        child: const Text("Proceed to Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    ),
  );
}