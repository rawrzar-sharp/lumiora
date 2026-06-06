import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_manager.dart';
import 'main.dart';
import 'app_config.dart';
import 'history.dart';

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

  // State untuk Dropdown dan Input
  String _selectedPaymentMethod = 'QRIS / E-Wallet';
  final List<String> _paymentMethods = [
    'QRIS / E-Wallet',
    'Digital Bank',
    'Digital Payment (Gopay, OVO, Shopee)',
    'Pay at Cashier'
  ];
  final TextEditingController _bankIdController = TextEditingController();
  
  late String _orderId;

  // Variabel Image Picker & Loading State
  File? _imageFile;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();
  
  // 🔥 FIX: Tambahkan variabel loading di sini agar tidak merah
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateRandomOrderId();
  }

  @override
  void dispose() {
    _bankIdController.dispose();
    super.dispose();
  }

  void _generateRandomOrderId() {
    final random = Random();
    int randomNum = 100000 + random.nextInt(900000); 
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

  // 🔥 FIX 1: Fungsi untuk menyimpan profil (Memperbaiki error _ensureCustomer)
  Future<void> _saveUserData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(data));
    } catch (e) {
      debugPrint("Gagal menyimpan data user: $e");
    }
  }

  // 🔥 FIX 2: Fungsi khusus untuk update stamp lokal setelah bayar
  Future<void> _updateLocalStamps(int stampsEarned) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('user_data');
      
      Map<String, dynamic> data = {};
      if (stored != null && stored.isNotEmpty) {
        data = jsonDecode(stored);
      }
      
      int currentStamps = (data['loyalty_stamps'] is int) ? data['loyalty_stamps'] : int.tryParse('${data['loyalty_stamps']}') ?? 0;
      int currentVouchers = (data['vouchers'] is int) ? data['vouchers'] : int.tryParse('${data['vouchers']}') ?? 0;
      
      int newStamps = currentStamps + stampsEarned;
      
      if (newStamps >= 10) {
        currentVouchers += newStamps ~/ 10;
        newStamps = newStamps % 10;
      }
      
      data['loyalty_stamps'] = newStamps;
      data['vouchers'] = currentVouchers;
      
      GlobalState.currentCardStamps = newStamps;
      GlobalState.vouchersCount = currentVouchers;
      
      await prefs.setString('user_data', jsonEncode(data));
    } catch (e) {
      debugPrint("Gagal memperbarui stamps: $e");
    }
  }

  Future<int?> _ensureCustomer() async {
    final name = GlobalState.userName ?? 'Guest';
    final url = Uri.parse('${AppConfig.backendUrl}/api/customers');
    
    try {
      final payload = jsonEncode({'name': name, 'phone': '080000000000'});
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 5));
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        
        var rawId = body['id'] ?? body['insertId'] ?? body['customer_id'];
        if (rawId == null && body['data'] != null) {
          rawId = body['data']['id'] ?? body['data']['insertId'];
        }
        
        if (rawId != null) {
          final id = rawId is int ? rawId : int.tryParse(rawId.toString());
          if (id != null) {
            GlobalState.customerId = id;
            // Memanggil fungsi fix _saveUserData
            await _saveUserData({'name': name, 'id': id, 'vouchers': GlobalState.vouchersCount, 'loyalty_stamps': GlobalState.currentCardStamps});
            return id;
          }
        }
      }
    } catch (e) {
      debugPrint("Customer API error: $e");
    }

    GlobalState.customerId = 1;
    return 1;
  }

// 🔥 FIX 3: Fungsi Pembayaran Gabungan (Satu Kode API)
  Future<void> _processPayment() async {
    // 1. Validasi Digital Bank
    if (_selectedPaymentMethod == 'Digital Bank' && _bankIdController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter a valid 16-digit Bank ID!'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Validasi Upload Gambar
    if (_selectedPaymentMethod != 'Pay at Cashier' && _imageFile == null && _webImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please upload your payment proof image!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- 🟢 UPDATE: Ambil ID langsung dari GlobalState 🟢 ---
      int? finalCustomerId = GlobalState.customerId;

      if (finalCustomerId == null) {
        // Jika karena suatu hal bernilai null, jalankan backup plan memastikan customer
        finalCustomerId = await _ensureCustomer();
      }

      if (finalCustomerId == null) {
        throw Exception("ID Pelanggan tidak ditemukan. Silakan login ulang.");
      }

      // 4. Kirim Data ke API (pastikan customer_id bertipe integer langsung)
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': finalCustomerId,
          'items': CartManager.instance.items,
          'total': widget.totalAmount,
          'order_type': widget.orderType,
          'payment_method': _selectedPaymentMethod,
          'order_number': _orderId,
        }),
      );

      // 5. Sukses
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Tambahkan stamp lokal
        await _updateLocalStamps(widget.stampsEarned);

        // --- 🟢 UPDATE: Ubah dari .clear() menjadi .clearCart() 🟢 ---
        CartManager.instance.clearCart(); 

        if (!mounted) return;
        
        // Pindah otomatis ke History
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
          (route) => false,
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal melakukan pesanan: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            // Order Summary Card
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

            // Dropdown Payment Method
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
                      _imageFile = null;
                      _webImageBytes = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bank Input khusus Digital Bank
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

            // Upload & Scan (Muncul kecuali Pay at Cashier)
            if (_selectedPaymentMethod != 'Pay at Cashier') ...[
              Center(
                child: Column(
                  children: [
                    if (_selectedPaymentMethod == 'QRIS / E-Wallet') ...[
                      const Text("Scan this QR Code to Pay", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
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
            onPressed: _isLoading ? null : _processPayment,
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Confirm & Finish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}