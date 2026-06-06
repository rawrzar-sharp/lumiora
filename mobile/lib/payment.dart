import 'dart:convert';
import 'dart:io';
import 'dart:math'; // <-- ADDED: Untuk membuat Random Order ID
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'cart_manager.dart';
import 'main.dart';
import 'app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PaymentPage extends StatefulWidget {
  final String orderType;
  final int totalAmount; 
  final int stampsEarned; 

  const PaymentPage({
    super.key, 
    required this.orderType, 
    required this.totalAmount, 
    required this.stampsEarned
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color darkGrey = const Color(0xFF4A4D4A);

  // --------------------------------------------------------------------------
  // TASK 7: STATE UNTUK DROPDOWN DAN INPUT REKENING
  // --------------------------------------------------------------------------
  String _selectedPaymentMethod = 'QRIS / E-Wallet';
  final List<String> _paymentMethods = [
    'QRIS / E-Wallet',
    'Digital Bank',
    'Digital Payment (Gopay, OVO, Shopee)',
    'Pay at Cashier'
  ];
  final TextEditingController _bankIdController = TextEditingController();
  
  // --------------------------------------------------------------------------
  // TASK 2: RANDOM ORDER ID
  // --------------------------------------------------------------------------
  late String _orderId;

  // --- VARIABEL UNTUK IMAGE PICKER ---
  File? _imageFile;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();
  int? _currentCheckoutId;

  @override
  void initState() {
    super.initState();
    // Generate Random Order ID saat masuk ke halaman ini
    _generateRandomOrderId();
  }

  @override
  void dispose() {
    _bankIdController.dispose();
    super.dispose();
  }

  void _generateRandomOrderId() {
    final random = Random();
    int randomNum = 100000 + random.nextInt(900000); // 6 digit angka acak
    _orderId = 'ORD-$randomNum';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _webImageBytes = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e"), backgroundColor: Colors.red),
      );
    }
  }

  String _formatRp(int amount) => 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  void _showSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(Icons.check_circle, color: primaryGreen, size: 60),
          const SizedBox(height: 10),
          const Text("Payment Successful!", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Order ID: $_orderId", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Type: ${widget.orderType}"),
          Text("Method: $_selectedPaymentMethod"),
          const SizedBox(height: 10),
          Text("+ ${widget.stampsEarned} Stamps Added!", 
               style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen, 
            minimumSize: const Size(double.infinity, 45)
          ),
            onPressed: () {
            // 1. Hitung Stamps & Vouchers using main GlobalState
            GlobalState.currentCardStamps = (GlobalState.currentCardStamps ?? 0) + widget.stampsEarned;

            if (GlobalState.currentCardStamps >= 10) {
              int earnedVouchers = GlobalState.currentCardStamps ~/ 10;
              GlobalState.vouchersCount = (GlobalState.vouchersCount ?? 0) + earnedVouchers;
              GlobalState.currentCardStamps = GlobalState.currentCardStamps % 10;
              GlobalState.showRewardPopup = true; // trigger popup on home
            }

            // 2. Clear cart
            CartManager.instance.clear();

            // 3. Return to HomeScreen fresh so the reward popup can show
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          },
          child: const Text("Back to Home", style: TextStyle(color: Colors.white)),
        )
      ],
    ),
  );
}

  Future<void> _persistUserData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(data));
    } catch (_) {}
  }

Future<int?> _ensureCustomer() async {
    final name = GlobalState.userName ?? 'Guest';
    final url = Uri.parse('${AppConfig.backendUrl}/api/customers');
    
    try {
      // Added dummy phone in case your backend strictly requires it
      final payload = jsonEncode({'name': name, 'phone': '080000000000'});
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 5));
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        
        // Robust ID extraction covering multiple standard backend response formats
        var rawId = body['id'] ?? body['insertId'] ?? body['customer_id'];
        if (rawId == null && body['data'] != null) {
          rawId = body['data']['id'] ?? body['data']['insertId'];
        }
        
        if (rawId != null) {
          final id = rawId is int ? rawId : int.tryParse(rawId.toString());
          if (id != null) {
            GlobalState.customerId = id;
            await _persistUserData({'name': name, 'id': id, 'vouchers': GlobalState.vouchersCount, 'loyalty_stamps': GlobalState.currentCardStamps});
            return id;
          }
        }
      }
    } catch (e) {
      debugPrint("Customer API error: $e");
    }

    // BULLETPROOF FALLBACK: If API fails, use the seeded Test Customer from init.sql
    debugPrint("Falling back to seeded Guest Customer (ID: 1)");
    GlobalState.customerId = 1;
    return 1;
  }

Future<List<int>> _createOrders(int customerId) async {
    List<int> createdOrderIds = [];

    for (var item in CartManager.instance.items) {
      int basePrice = (item['basePrice'] as int?) ?? 0;
      final Map<String, int> addonOpts = Map<String, int>.from((item['addonOptions'] as Map?) ?? {});
      final List<String> currentAddons = List<String>.from((item['selectedAddons'] as List?) ?? []);

      int unitCost = basePrice;
      for (var addon in currentAddons) { unitCost += addonOpts[addon] ?? 0; }
      int qty = item['quantity'] ?? 1;

      final body = {
        'customer_id': customerId,
        'menu_id': int.tryParse(item['id'].toString()) ?? 0,
        'quantity': qty,
        'order_number': _orderId, // 
        'order_type': widget.orderType.toLowerCase() == 'takeout' ? 'takeaway' : 'dine_in',
        'payment_method': _selectedPaymentMethod == 'Pay at Cashier' ? 'cashier' : 'qris',
        'total': unitCost * qty,
        'ice_level': item['selectedSpice'] ?? 'Normal Ice',
        'sugar_level': 'Normal Sugar'
      };

      try {
        final res = await http.post(
          Uri.parse('${AppConfig.backendUrl}/api/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body)
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 201 || res.statusCode == 200) {
          final b = jsonDecode(res.body);
          // Safely extract the ID based on various backend response formats
          int? newId = b['order_id'] ?? b['id'] ?? (b['data'] != null ? b['data']['insertId'] : null);
          if (newId != null) createdOrderIds.add(newId);
        } else {
          debugPrint("Order rejection from server: ${res.body}");
        }
      } catch (e) {
        debugPrint("Network error creating order: $e");
      }
    }
    return createdOrderIds;
  }

  Future<int?> _createCheckoutForOrder(int orderId) async {
    try {
      final res = await http.post(Uri.parse('${AppConfig.backendUrl}/api/checkouts'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'orders_id': orderId})).timeout(const Duration(seconds: 8));
      if (res.statusCode == 201) {
        final b = jsonDecode(res.body);
        return b['id'] as int?;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _updateCheckoutStatus(int checkoutId, String status) async {
    try {
      final res = await http.put(Uri.parse('${AppConfig.backendUrl}/api/checkouts/$checkoutId'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'payment_status': status})).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  void _processPayment() async {
    // --------------------------------------------------------------------------
    // TASK 7: VALIDASI PAYMENT
    // --------------------------------------------------------------------------
    // 1. Validasi Digital Bank (Wajib 16 Digit)
    if (_selectedPaymentMethod == 'Digital Bank') {
      if (_bankIdController.text.length != 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Please enter a valid 16-digit Bank ID!'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // 2. Validasi Upload Gambar (Wajib untuk semua KECUALI Cashier)
    if (_selectedPaymentMethod != 'Pay at Cashier' && _imageFile == null && _webImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please upload your payment proof image!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Jika lolos validasi, lakukan submit ke backend
    final custId = GlobalState.customerId ?? await _ensureCustomer();
    if (custId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to register customer. Try again later.'), backgroundColor: Colors.red));
      return;
    }

    final createdOrderIds = await _createOrders(custId);
    if (createdOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create order. Please check your connection and try again.'), backgroundColor: Colors.red));
      return;
    }

    // Use the first order ID to attach the checkout payment status
    _currentCheckoutId = await _createCheckoutForOrder(createdOrderIds.first);

    // Show confirmation dialog allowing user to finalize or cancel the payment
    if (_currentCheckoutId != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text('Proceed to confirm payment for Order #${_orderId}?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // cancel
                final ok = await _updateCheckoutStatus(_currentCheckoutId!, 'cancelled');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Order cancelled' : 'Failed to cancel'), backgroundColor: ok ? Colors.green : Colors.red));
                if (ok) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
              },
              child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final paid = await _updateCheckoutStatus(_currentCheckoutId!, 'paid');
                if (!paid) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update payment status'), backgroundColor: Colors.red));
                  return;
                }
                // Show success and apply rewards
                _showSuccessDialog();
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create checkout'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E1),
      appBar: AppBar(
        title: const Text("Payment", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------------
            // TASK 9: SUMMARY DATA SYNCHRONIZATION
            // ------------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Order ID", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(_orderId, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.white30, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Payable", style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text(_formatRp(widget.totalAmount), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ------------------------------------------------------------------
            // TASK 7: DROPDOWN PAYMENT METHOD
            // ------------------------------------------------------------------
            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300)
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedPaymentMethod,
                  icon: Icon(Icons.keyboard_arrow_down, color: primaryGreen),
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method, style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue!;
                      // Reset file jika user mengganti metode
                      _imageFile = null;
                      _webImageBytes = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ------------------------------------------------------------------
            // TASK 7: DINAMIS INPUT (DIGITAL BANK ID ATAU BUKTI GAMBAR)
            // ------------------------------------------------------------------
            
            // Tampilan Khusus Input 16 Digit Bank (Hanya muncul jika pilih Digital Bank)
            if (_selectedPaymentMethod == 'Digital Bank') ...[
              const Text("Bank ID (16 Digits)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _bankIdController,
                keyboardType: TextInputType.number,
                maxLength: 16,
                decoration: InputDecoration(
                  hintText: "Enter 16-digit account number",
                  filled: true,
                  fillColor: Colors.white,
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // TAMPILAN GAMBAR QR & UPLOAD BUKTI (Muncul untuk semua kecuali Cashier)
            if (_selectedPaymentMethod != 'Pay at Cashier') ...[
              Center(
                child: Column(
                  children: [
                    if (_selectedPaymentMethod == 'QRIS / E-Wallet') ...[
                      const Text("Scan this QR Code to Pay", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      // TASK 6: KODE GAMBAR LAMA YANG DIPERTAHANKAN
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/qris_gpn_sirlaw.png',
                          width: 220, height: 220, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 220, height: 220, color: Colors.grey.shade300,
                            child: const Icon(Icons.qr_code, size: 80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text("Upload Payment Proof", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // PREVIEW IMAGE YANG DI-UPLOAD
                    if (!kIsWeb && _imageFile != null)
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imageFile!, height: 120, fit: BoxFit.cover))
                    else if (kIsWeb && _webImageBytes != null)
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_webImageBytes!, height: 120, fit: BoxFit.cover))
                    else
                      Container(
                        height: 100, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text("No image selected", style: TextStyle(color: Colors.grey))),
                      ),
                    
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image, color: primaryGreen),
                      label: Text("Pick Image from Gallery", style: TextStyle(color: primaryGreen)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: primaryGreen)),
                    ),
                  ],
                ),
              ),
            ],
            
            // Pesan khusus jika bayar di kasir
            if (_selectedPaymentMethod == 'Pay at Cashier') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You chose to pay at the cashier. Please show your Order ID to our staff upon arrival.",
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen, 
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: _processPayment,
            child: const Text("Confirm & Finish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}