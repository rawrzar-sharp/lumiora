import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // <-- FIX: Import ini yang mengatasi garis merah pada Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'cart_manager.dart';

// --- (Global State untuk menyimpan Stamps sementara ke main.dart) ---
class GlobalState {
  static int stamps = 0;
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

  String _selectedPaymentMethod = 'QRIS';
  
  // --- VARIABEL UNTUK IMAGE PICKER ---
  File? _imageFile;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

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
            Text("Order Type: ${widget.orderType}"),
            Text("Method: $_selectedPaymentMethod"),
            const SizedBox(height: 10),
            Text("+ ${widget.stampsEarned} Stamps Added!", style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, minimumSize: const Size(double.infinity, 45)),
            onPressed: () {
              // 1. Simpan stamps ke memory 
              GlobalState.stamps += widget.stampsEarned;
              
              // 2. Bersihkan Cart
              CartManager.instance.clear(); 
              
              // 3. Kembali Langsung ke Main Page (Home)
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("Back to Home", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _processPayment() {
    // Validasi Image Upload jika milih QRIS
    if (_selectedPaymentMethod == 'QRIS' && _imageFile == null && _webImageBytes == null) {
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
            // TOTAL SUMMARY 
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Payable", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text(_formatRp(widget.totalAmount), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("QRIS / E-Wallet"),
                    value: 'QRIS',
                    groupValue: _selectedPaymentMethod,
                    activeColor: primaryGreen,
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text("Pay at Cashier"),
                    value: 'Cashier',
                    groupValue: _selectedPaymentMethod,
                    activeColor: primaryGreen,
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TAMPILAN UPLOAD BUKTI UNTUK QRIS 
            if (_selectedPaymentMethod == 'QRIS') ...[
              Center(
                child: Column(
                  children: [
                    const Text("Scan this QR Code to Pay", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/image_9cb7d4.png',
                        width: 220, height: 220, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 220, height: 220, color: Colors.grey.shade300,
                          child: const Icon(Icons.qr_code, size: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen, 
              minimumSize: const Size(double.infinity, 50),
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