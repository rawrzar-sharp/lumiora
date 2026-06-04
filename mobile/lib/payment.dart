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

// --- (Global State untuk menyimpan Data) ---
class GlobalState {
  static int totalStamps = 0;       // Untuk Kartu Kecil (Naik terus, tidak reset)
  static int currentCardStamps = 0; // Untuk Kartu Besar (Maksimal 10 lalu reset)
  static int vouchersCount = 1;     // Jumlah Voucher / Kupon Bonus
  static bool showRewardPopup = false; // Trigger untuk menampilkan Popup di Home
  static bool bannerBonusClaimed = false;
  static Function()? onStampUpdated;
}


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
            // 1. Hitung Stamps & Vouchers
            GlobalState.totalStamps += widget.stampsEarned;
            GlobalState.currentCardStamps += widget.stampsEarned;

            if (GlobalState.currentCardStamps >= 10) {
              int earnedVouchers = GlobalState.currentCardStamps ~/ 10;
              GlobalState.vouchersCount += earnedVouchers;
              GlobalState.currentCardStamps = GlobalState.currentCardStamps % 10;
              GlobalState.showRewardPopup = true; // Nyalakan trigger
            }

            // 2. Bersihkan keranjang
            CartManager.instance.clear();

            // 3. 🔥 FIX UTAMA: Jangan pakai popUntil. 
            // Kita hapus semua tumpukan layar dan buat Home Screen baru yang segar,
            // sehingga sistem PASTI membaca perintah memunculkan Pop-up!
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

  void _processPayment() {
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
    
    // Jika lolos validasi, tampilkan sukses
    _showSuccessDialog();
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