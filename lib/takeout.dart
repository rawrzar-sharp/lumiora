import 'package:flutter/material.dart';

class TakeoutPage extends StatelessWidget {
  // Brand Colors matching your main.dart
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);

  const TakeoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("CHECKOUT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("PICK UP"),
            _infoCard(),
            const SizedBox(height: 20),
            _sectionHeader("ORDER SUMMARY"),
            _itemRow("Lemon Tea", "Rp 10.000"),
            _itemRow("Croissant", "Rp 15.000"),
            const SizedBox(height: 20),
            _stampSection(),
            const SizedBox(height: 20),
            _paymentDetails(),
            const SizedBox(height: 30),
            _paymentMethodSelector(),
            const SizedBox(height: 20),
            _contactField(),
            const SizedBox(height: 40),
            _payButton(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Pick up time", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("UNIJI Building, Lobby Floor", style: TextStyle(fontSize: 12)),
        ]),
        TextButton(onPressed: () {}, child: const Text("Select Time")),
      ],
    ),
  );

  Widget _itemRow(String name, String price) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
    child: Row(
      children: [
        Container(width: 40, height: 40, color: lightGreenCard),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text("Description", style: TextStyle(fontSize: 10)),
        ]),
        const Spacer(),
        Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _stampSection() => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text("Stamp Collection", style: TextStyle(fontWeight: FontWeight.bold)),
      Text("Will get 2 Stamps", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _paymentDetails() => Column(
    children: [
      _row("Total Discount", "-Rp 15.000"),
      _row("PB1 10.00%", "Rp 12.000"),
      _row("VAT 11%", "Rp 10.000"),
      const Divider(thickness: 1),
      _row("Total :", "Rp 120.000", isBold: true),
    ],
  );

  Widget _row(String label, String value, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    ),
  );

  Widget _paymentMethodSelector() => ListTile(
    title: const Text("Payment Methods"),
    subtitle: const Text("Select Payment Method", style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {},
  );

  Widget _contactField() => const TextField(
    decoration: InputDecoration(
      labelText: "CONTACTS*",
      border: OutlineInputBorder(),
      suffixIcon: Icon(Icons.phone),
    ),
  );

  Widget _payButton(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
      onPressed: () {},
      child: const Text("PAY Rp 120.000", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );
}