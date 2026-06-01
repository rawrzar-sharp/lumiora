import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'cart_manager.dart'; 

class TakeoutPage extends StatefulWidget {
  const TakeoutPage({super.key});

  @override
  State<TakeoutPage> createState() => _TakeoutPageState();
}

class _TakeoutPageState extends State<TakeoutPage> {
  // =========================================================================
  // 1. VARIABLES & CONFIGURATION
  // =========================================================================
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  
  final String baseUrl = 'http://localhost:3000'; // <-- FIX: Emulator IP
  String _selectedPaymentMethod = 'QRIS';

  // <-- FIX: Baca item langsung dari CartManager
  List<Map<String, dynamic>> get _cartItems => CartManager.instance.items;

  @override
  void initState() {
    super.initState();
    // Mendengarkan perubahan cart (misal tambah kurang qty)
    CartManager.instance.addListener(_onCartChange);

    // --- TAMBAHAN SEMENTARA UNTUK TESTING ---
    // Jika keranjang kosong saat halaman ini dibuka, otomatis masukkan 1 menu
    // PERBAIKAN: Menambahkan tanda '?' setelah instance
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (CartManager.instance.isEmpty) {
        CartManager.instance.addItem({
          'id': 7, // Menggunakan ID 7 (Iced Sea Salt Latte di Database Anda)
          'name': 'Iced Sea Salt Latte (Dummy Test)',
          'category': 'Beverages',
          'basePrice': 28000.0,
          'image_url': null,
          'selectedSpice': 'Normal',
          'selectedAddons': [],
        });
      }
    });
    // ----------------------------------------
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChange);
    super.dispose();
  }

  void _onCartChange() => setState(() {});

  // =========================================================================
  // 2. NETWORK OPERATIONS (POST ONLY)
  // =========================================================================

  Future<void> _sendOrderToBackend() async {
    const Map<String, String> paymentMap = {
      'Gopay': 'qris',
      'OVO': 'qris',
      'Dana': 'qris',
      'ShopeePay': 'qris',
      'LinkAja': 'qris',
      'QRIS': 'qris',
      'Debit': 'debit',
      'Credit Card': 'cc',
      'Cashier': 'cashier',
    };

    final List<Map<String, dynamic>> orderItemsPayload = _cartItems.map((item) {
      return {
        'menu_item_id': int.tryParse(item['id'].toString()) ?? 1,
        'quantity': item['quantity'] ?? 1,
        'price_at_sale': item['basePrice'] ?? 0, 
        'customizations': {
          'preference': item['selectedSpice'] ?? '',
          'addons': item['selectedAddons'] ?? [],
        }
      };
    }).toList();

    final Map<String, dynamic> checkoutPayload = {
      'order_type': 'takeaway', 
      'payment_method': paymentMap[_selectedPaymentMethod] ?? 'qris', 
      'total_amount': _finalTotal,
      'items': orderItemsPayload,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(checkoutPayload),
      );

      final Map<String, dynamic> result = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && result['success'] == true) {
        CartManager.instance.clear(); // Bersihkan cart jika sukses
        _showSuccessDialog(result['order_number'] ?? 'LUM-XXXX');
      } else {
        _showErrorSnackBar("Backend Rejection: ${result['error'] ?? 'Unknown error'}");
      }
    } catch (e) {
      _showErrorSnackBar("Failed to communicate with runtime database: $e");
    }
  }

  // =========================================================================
  // 3. FINANCIAL CALCULATORS & UTILITIES
  // =========================================================================
  
  int get _subtotal {
    int total = 0;
    for (var item in _cartItems) {
      int itemCost = item['basePrice'] as int;
      final Map<String, int> addonOpts = Map<String, int>.from(item['addonOptions']);
      final List<String> currentAddons = List<String>.from(item['selectedAddons']);
      
      for (var addon in currentAddons) {
        itemCost += addonOpts[addon] ?? 0;
      }
      total += itemCost * (item['quantity'] as int);
    }
    return total;
  }

  int get _discount => _subtotal > 50000 ? 15000 : 0;
  int get _pb1 => (_subtotal * 0.10).round();
  int get _vat => (_subtotal * 0.11).round();
  int get _finalTotal => _subtotal - _discount + _pb1 + _vat;
  
  // <-- FIX: Stamps clamp 0 sampai 10
  int get _stampsEarned => _finalTotal > 0 ? (_finalTotal / 30000).floor().clamp(0, 10) : 0;

  String _formatRp(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // =========================================================================
  // 4. USER INTERACTIVE VIEWS
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "PICKUP CHECKOUT", 
          style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)
        ),
        leading: HoverBounceWrapper(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, color: darkGrey, size: 20),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("PICK UP LOCATION & TIME"),
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildSectionHeader("YOUR BASKET"),
                _buildCartItemList(),
                const SizedBox(height: 24),
                _buildSectionHeader("LOYALTY REWARDS"),
                _buildStampSection(),
                const SizedBox(height: 24),
                _buildSectionHeader("PAYMENT DETAILS"),
                _buildPaymentDetailsCard(),
                const SizedBox(height: 24),
                _buildSectionHeader("CUSTOMER CONTACT"),
                _buildContactField(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildStickyBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      title, 
      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8)
    ),
  );

  Widget _buildInfoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: lightGreenCard.withOpacity(0.4),
          radius: 22,
          child: Icon(Icons.storefront, color: primaryGreen, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text("UNIJI Building, Lobby Floor", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2C3028))),
              SizedBox(height: 4),
              Text("Estimated pickup: Now (10-15 mins setup)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]
          ),
        ),
      ],
    ),
  );

  Widget _buildCartItemList() {
    if (_cartItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: const [
          Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text("Your basket is empty.\nAdd items from the Menu page.",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final List<dynamic> rawAddons = item['selectedAddons'] ?? [];
        final List<String> activeAddons = List<String>.from(rawAddons); 
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        item['img'], 
                        width: 65, height: 65, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: lightGreenCard, width: 90, height: 90,
                          child: const Icon(Icons.fastfood, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(item['category'], style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _formatRp(item['basePrice'] as int), 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildQtyButton(Icons.remove, () {
                          final q = item['quantity'] as int;
                          CartManager.instance.updateQuantity(index, q - 1);
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        _buildQtyButton(Icons.add, () {
                          final q = item['quantity'] as int;
                          CartManager.instance.updateQuantity(index, q + 1);
                        }),
                      ],
                    )
                  ],
                ),
                if ((item['spiceOptions'] as List).isNotEmpty || (item['addonOptions'] as Map).isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6, runSpacing: 4,
                          children: [
                            if (item['selectedSpice'].toString().isNotEmpty)
                              _buildStatusChip(item['selectedSpice'], Icons.tune),
                            ...activeAddons.map((addon) => _buildStatusChip(addon, Icons.add_circle_outline)),
                          ],
                        ),
                      ),
                      HoverBounceWrapper(
                        onTap: () => _showCustomizationSheet(context, item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: lightGreenCard.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.edit_note, size: 14, color: primaryGreen),
                              const SizedBox(width: 2),
                              Text("Modify", style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback action) => HoverBounceWrapper(
    onTap: action,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300), color: Colors.white),
      child: Icon(icon, size: 16, color: darkGrey),
    ),
  );

  Widget _buildStatusChip(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFBF8F1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.black.withOpacity(0.04)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  // <-- FIX: Tampilkan 10 slot stamp secara visual
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

  Widget _buildPaymentDetailsCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        _buildRowItem("Items Basket Subtotal", _formatRp(_subtotal)),
        _buildRowItem("Lumiora Campaign Promo", "- ${_formatRp(_discount)}", valColor: Colors.red),
        _buildRowItem("Government Local Tax (PB1)", _formatRp(_pb1)),
        _buildRowItem("Value Added Tax (VAT 11%)", _formatRp(_vat)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 0.5)),
        _buildRowItem("Aggregate Total Payable", _formatRp(_finalTotal), isBold: true),
      ],
    ),
  );

  Widget _buildRowItem(String label, String value, {bool isBold = false, Color? valColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.normal, fontSize: isBold ? 14 : 12, color: isBold ? Colors.black : Colors.grey.shade600)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: valColor ?? (isBold ? primaryGreen : Colors.black87), fontSize: isBold ? 15 : 12)),
      ],
    ),
  );

  Widget _buildContactField() => const TextField(
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      labelText: "PHONE NUMBER FOR SMS VERIFICATION*",
      labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      suffixIcon: Icon(Icons.phone_iphone, size: 18),
      filled: true, fillColor: Colors.white,
    ),
  );

  Widget _buildStickyBottomPanel() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -4))]
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text("Paying via $_selectedPaymentMethod", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF2C3028))),
                ],
              ),
              TextButton(
                onPressed: _showPaymentMethodSelector,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: Text("Change", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              )
            ],
          ),
          const SizedBox(height: 10),
          HoverBounceWrapper(
            onTap: () {
              if (_cartItems.isEmpty) {
                _showErrorSnackBar("Your basket is empty.");
                return;
              }
              // <-- FIX: Tampilkan dialog QRIS dulu sebelum tembak API
              if (['QRIS', 'Gopay', 'OVO', 'Dana', 'ShopeePay', 'LinkAja'].contains(_selectedPaymentMethod)) {
                _showQrisDialog();
              } else {
                _sendOrderToBackend();
              }
            },
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Text("CONFIRM & PAY ${_formatRp(_finalTotal)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _showCustomizationSheet(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<String> spiceOpts = List<String>.from(item['spiceOptions'] ?? []);
            final Map<String, int> addonOpts = Map<String, int>.from(item['addonOptions'] ?? {});
            final List<String> itemSelectedAddons = List<String>.from(item['selectedAddons'] ?? []);

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F1E1),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text("Customize specifications for your order", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  
                  if (spiceOpts.isNotEmpty) ...[
                    Text(item['category'] == 'Beverages' ? "SUGAR & ICE PREFERENCE" : "SPICINESS CALIBRATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryGreen)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: spiceOpts.map<Widget>((opt) {
                        bool isSel = item['selectedSpice'] == opt;
                        return ChoiceChip(
                          label: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          selected: isSel,
                          selectedColor: primaryGreen,
                          backgroundColor: Colors.white,
                          onSelected: (val) {
                            setModalState(() => item['selectedSpice'] = opt);
                            setState(() {}); // trigger cart re-render
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (addonOpts.isNotEmpty) ...[
                    Text("GOURMET ADD-ONS (INCREMENTAL PRICE)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryGreen)),
                    const SizedBox(height: 8),
                    ...addonOpts.keys.map((addonKey) {
                      bool hasAddon = itemSelectedAddons.contains(addonKey);
                      int extraCost = addonOpts[addonKey] ?? 0;
                      return CheckboxListTile(
                        title: Text(addonKey, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text("+ ${_formatRp(extraCost)}", style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        value: hasAddon,
                        activeColor: primaryGreen,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool? checked) {
                          setModalState(() {
                            if (checked == true) {
                              itemSelectedAddons.add(addonKey);
                            } else {
                              itemSelectedAddons.remove(addonKey);
                            }
                            item['selectedAddons'] = itemSelectedAddons;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 12),
                  HoverBounceWrapper(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity, height: 48,
                      decoration: BoxDecoration(color: darkGrey, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("Apply System Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final methods = ['QRIS', 'Gopay', 'OVO', 'Dana', 'ShopeePay', 'LinkAja', 'Debit', 'Credit Card', 'Cashier'];
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SELECT PAYMENT PLATFORM", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 12),
                ...methods.map((method) => ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined, color: primaryGreen),
                  title: Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  trailing: _selectedPaymentMethod == method ? Icon(Icons.check_circle, color: primaryGreen) : null,
                  onTap: () {
                    setState(() => _selectedPaymentMethod = method);
                    Navigator.pop(context);
                  },
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // <-- FIX: Dialog QRIS Statis
  void _showQrisDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Scan QRIS to Pay", style: TextStyle(fontWeight: FontWeight.w900, color: primaryGreen, fontSize: 16)),
              const SizedBox(height: 12),
              const Text("Use any QRIS-compatible e-wallet", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: primaryGreen, width: 2), borderRadius: BorderRadius.circular(16)),
                child: Image.asset('assets/images/qris_static.png', width: 220, height: 220, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(width: 220, height: 220, color: Colors.grey.shade200, child: const Icon(Icons.qr_code_2, size: 100))),
              ),
              const SizedBox(height: 16),
              Text("Total ${_formatRp(_finalTotal)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              HoverBounceWrapper(
                onTap: () {
                  Navigator.pop(context); // Tutup dialog QRIS
                  _sendOrderToBackend();  // Kirim data ke database
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text("I've Paid – Confirm Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String orderNum) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: primaryGreen),
            const SizedBox(width: 10),
            const Text("Order Confirmed", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Your order has been queued successfully!\n\nOrder No: $orderNum"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back home
            },
            child: Text("Awesome", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}

// --- MICRO-INTERACTION UTILITY ANIMATOR ---
class HoverBounceWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HoverBounceWrapper({Key? key, required this.child, this.onTap}) : super(key: key);

  @override
  State<HoverBounceWrapper> createState() => _HoverBounceWrapperState();
}

class _HoverBounceWrapperState extends State<HoverBounceWrapper> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.96 : (_isHovering ? 1.03 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onTap != null) widget.onTap!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}