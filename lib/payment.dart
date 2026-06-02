import 'dart:convert';
import 'package:flutter/material.dart';
import 'cart_manager.dart';

class PaymentPage extends StatefulWidget {
  final String orderType; // 'Takeout' atau 'Dine In' dll

  const PaymentPage({super.key, required this.orderType});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // Warna tema sesuai dengan main.dart & takeout.dart
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);
  final Color baseCream = const Color(0xFFEBE5D9);

  String _selectedPaymentMethod = 'QRIS'; // Default checkout ala Shopee
  bool _hasUploadedProof = false; // Status upload bukti bayar

  // Ambil data item belanja langsung dari CartManager
  List<Map<String, dynamic>> get _cartItems => CartManager.instance.items;

  // --- KALKULASI TOTAL HARGA ---
  double get _subtotal {
    return _cartItems.fold(0, (sum, item) {
      double price = double.tryParse(item['price'].toString()) ?? 0;
      int qty = item['quantity'] ?? 1;
      return sum + (price * qty);
    });
  }

  // Pajak atau biaya layanan (opsional, diset 0 jika ingin murni total)
  double get _serviceFee => 2000;
  double get _totalPayment => _subtotal + _serviceFee;

  // --- ISSUE #4: STAMPS CALCULATION ---
  // Aturan: Setiap kelipatan Rp 10.000 mendapatkan 1 Stamp
  int get _calculatedStamps {
    return (_totalPayment / 10000).floor();
  }

  // --- SIMULASI UPLOAD BUKTI BAYAR ---
  void _pickProofImage() {
    setState(() {
      _hasUploadedProof = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment proof successfully uploaded!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // --- ISSUE #9: POPUP RECEIPT (DIALOG SETRUK DIGITAL) ---
  void _showReceiptPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib menekan tombol tutup
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Icon(Icons.check_circle, color: primaryGreen, size: 50),
              const SizedBox(height: 8),
              const Text(
                "Payment Receipt",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                // Info Status & Tipe
                _buildReceiptRow("Status", "SUCCESS", valueColor: Colors.green, isBold: true),
                _buildReceiptRow("Order Type", widget.orderType),
                _buildReceiptRow("Payment Method", _selectedPaymentMethod),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 1, color: Colors.grey),
                ),
                
                // Daftar Item (Tanpa Gambar Produk)
                const Text(
                  "Items Ordered:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ..._cartItems.map((item) {
                  int itemQty = item['quantity'] ?? 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      "${item['name']} (x$itemQty)",
                      style: TextStyle(fontSize: 13, color: darkGrey),
                    ),
                  );
                }).toList(),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 1, color: Colors.grey),
                ),

                // Rincian Harga & Stamps
                _buildReceiptRow("Total Price", "Rp ${_totalPayment.toStringAsFixed(0)}", isBold: true),
                _buildReceiptRow(
                  "Stamps Received", 
                  "+$_calculatedStamps Stamps", 
                  valueColor: Colors.orange.shade700, 
                  isBold: true
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                // Bersihkan Keranjang setelah sukses bayar
                // Pastikan fungsi clear() ada di CartManager Anda jika ingin digunakan
                Navigator.pop(context); // Tutup Dialog
                Navigator.pop(context); // Kembali dari Halaman Payment
              },
              child: const Text("Finish & Back", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baseCream,
      appBar: AppBar(
        title: const Text("Checkout / Payment", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- RINGKASAN PESANAN ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Chip(
                          label: Text(widget.orderType),
                          backgroundColor: lightGreenCard,
                          labelStyle: TextStyle(color: textDark, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Subtotal Products (${_cartItems.length} Item)", style: TextStyle(color: darkGrey)),
                        Text("Rp ${_subtotal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Service Fee/System Fee", style: TextStyle(color: darkGrey)),
                        Text("Rp ${_serviceFee.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          "Rp ${_totalPayment.toStringAsFixed(0)}", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryGreen)
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- PILIHAN METODE PEMBAYARAN ---
              const Text("Choose Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text("QRIS / GoPay / OVO / Dana"),
                      subtitle: const Text("Scan QR Code GPN Mandiri"),
                      value: 'QRIS',
                      groupValue: _selectedPaymentMethod,
                      activeColor: primaryGreen,
                      onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text("Pay at the Cashier (Cash)"),
                      subtitle: const Text("Directly complete the payment at the counter"),
                      value: 'Cashier',
                      groupValue: _selectedPaymentMethod,
                      activeColor: primaryGreen,
                      onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- STATIS QR CODE GPN & UPLOAD BUKTI ---
              if (_selectedPaymentMethod == 'QRIS') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text(
                        "Please scan the QRIS code for Sir Law below:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 12),
                      
                      // --- MENAMPILKAN GAMBAR QRIS GPN (UPDATED PATH) ---
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/qris_gpn_sirlaw.png', // <-- PATH SUDAH DIUPDATE DI SINI
                          width: 240,
                          height: 240,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 240,
                              height: 240,
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Text(
                                  "QRIS image not found.\nPlease ensure the path in pubspec.yaml is correct:\nassets/images/qris_gpn_sirlaw.png",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      const Text(
                        "Already transferred? You must upload the payment proof:",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),

                      // Tombol Unggah Bukti
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasUploadedProof ? Colors.grey : Colors.amber.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _pickProofImage,
                        icon: Icon(_hasUploadedProof ? Icons.check : Icons.cloud_upload),
                        label: Text(_hasUploadedProof ? "Proof Uploaded" : "Upload Proof Image"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- ESTIMASI PEROLEHAN STAMPS ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You will receive +$_calculatedStamps Stamps from this transaction!",
                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- BUTTON KONFIRMASI BAYAR ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Validasi: Jika memilih QRIS tapi belum upload bukti transfer
                    if (_selectedPaymentMethod == 'QRIS' && !_hasUploadedProof) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("⚠️ You must upload the payment proof first!"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    // Jika valid, munculkan Popup Receipt
                    _showReceiptPopup();
                  },
                  child: const Text(
                    "Confirm Payment",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}