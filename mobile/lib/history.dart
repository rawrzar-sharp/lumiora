import 'package:flutter/material.dart';
import 'menu_page.dart';
import 'cart.dart'; // Make sure this matches your actual cart file
import 'profile.dart'; // Make sure this matches your actual profile file
import 'main.dart'; // To route back to Home
import 'app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // --- Colors matching menu_page.dart ---
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color textDark = const Color(0xFF2C3028);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  
  int _bottomNavIndex = 3; // 3 represents the History tab
  int _selectedTabIndex = 0; // 0 for Active, 1 for Completed

  // Runtime-loaded orders
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _loading = true;

  // --- Footer Navigation Logic ---
  void _onBottomNavTapped(int index) {
    if (index == _bottomNavIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen(); // Ensure this matches your home class
        break;
      case 1:
        nextScreen = const MenuPage();
        break;
      case 2:
        nextScreen = const CartPage(); // Ensure this matches your cart class
        break;
      case 3:
        return; // Already here
      case 4:
        nextScreen = const ProfilePage(); // Ensure this matches your profile class
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'History',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false, // Prevents back button on main tabs
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Row(
            children: [
              Expanded(child: _buildTab("Active", 0)),
              Expanded(child: _buildTab("Completed", 1)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tab Content Area
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTabIndex == 0
                        ? _buildOrderList(_activeOrders, isActive: true)
                        : _buildOrderList(_completedOrders, isActive: false),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; });
    try {
      final customerId = GlobalState.customerId;
      if (customerId == null) {
        // no customer known -- show empty lists
        setState(() {
          _activeOrders = [];
          _completedOrders = [];
          _loading = false;
        });
        return;
      }

      final url = Uri.parse('${AppConfig.backendUrl}/api/orders/customer/$customerId');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List data = body['data'] ?? [];
        final nowActive = <Map<String,dynamic>>[];
        final nowCompleted = <Map<String,dynamic>>[];
        for (var o in data) {
          final status = (o['order_status'] ?? 'pending').toString().toLowerCase();
          final created = o['created_at']?.toString() ?? '';
          final date = created.split(' ').first;
          final time = created.split(' ').length > 1 ? created.split(' ')[1] : '';
          final items = List<String>.from(o['items'] ?? []);
          final total = o['total'] != null ? 'Rp ${o['total']}' : '';
          final entry = {
            'id': o['id']?.toString() ?? '',
            'date': date,
            'time': time,
            'items': items,
            'total': total,
            'status': status == 'success' ? 'Completed' : (status == 'cancelled' ? 'Cancelled' : 'Ongoing')
          };
          if (status == 'success') nowCompleted.add(entry);
          else nowActive.add(entry);
        }

        setState(() {
          _activeOrders = nowActive;
          _completedOrders = nowCompleted;
          _loading = false;
        });
      } else {
        setState(() { _loading = false; });
      }
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  // --- Custom Tab Builder ---
  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryGreen : Colors.grey.shade300,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? primaryGreen : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
              fontFamily: 'Poppins', // Or whichever font you are using
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  // --- Order List Builder ---
  Widget _buildOrderList(List<Map<String, dynamic>> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isActive ? "No active orders right now." : "No completed orders yet.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey<bool>(isActive), // For AnimatedSwitcher to detect change
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isActive: isActive);
      },
    );
  }

  // --- Individual Order Card ---
  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGreenCard.withOpacity(0.4), // Slightly faded like the image
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status Pill + Date/Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? primaryGreen : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "${order['date']} | ${order['time']}",
                style: TextStyle(
                  color: textDark.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Order ID
          Text(
            "Order Number",
            style: TextStyle(color: textDark.withOpacity(0.6), fontSize: 12),
          ),
          Text(
            "#${order['id']}",
            style: TextStyle(
              color: textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Items and Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Items List
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    order['items'].length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        order['items'][index],
                        style: TextStyle(color: textDark, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
              // Total Price
              Text(
                order['total'],
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action Button (Track / Reorder)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add Track or Reorder logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text(
                isActive ? 'Track' : 'Reorder',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}