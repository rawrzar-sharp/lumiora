import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'menu_page.dart';
import 'profile.dart'; // Make sure this matches your actual profile file
import 'main.dart'; // To route back to Home
import 'app_config.dart';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with WidgetsBindingObserver {
  // --- Colors matching menu_page.dart ---
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color textDark = const Color(0xFF2C3028);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  
  int _bottomNavIndex = 2; // 2 represents the History tab in the unified footer
  int _selectedTabIndex = 0; // 0 for Active, 1 for Completed

  // Runtime-loaded orders
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _loading = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh history when the user comes back to the app from background.
    if (state == AppLifecycleState.resumed) {
      _fetchOrders();
    }
  }

  // --- Footer Navigation Logic (matches Home/Menu/Profile order) ---
  void _onBottomNavTapped(int index) {
    if (index == _bottomNavIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen = const MenuPage();
        break;
      case 2:
        return; // Already on History
      case 3:
        nextScreen = const ProfilePage();
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
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: _fetchOrders,
          ),
        ],
        automaticallyImplyLeading: false, // Prevents back button on main tabs
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _fetchOrders,
        child: Column(
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
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchOrders();
    // Poll every 10s so a status flip in CMS is reflected without manual refresh.
    _refreshTimer = Stream.periodic(const Duration(seconds: 10)).listen((_) {
      if (mounted) _fetchOrders();
    });
  }

  StreamSubscription<dynamic>? _refreshTimer;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() { _loading = _activeOrders.isEmpty && _completedOrders.isEmpty; });
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
          final List rawItems = (o['items'] is List) ? o['items'] as List : [];
          final items = rawItems.map((it) {
            if (it is Map) {
              final label = it['label']
                  ?? (it['item_name'] != null
                      ? '${it['quantity']}x ${it['item_name']}'
                      : it['name']?.toString() ?? '');
              return label.toString();
            }
            return it.toString();
          }).cast<String>().toList();
          final total = (o['total_amount'] ?? o['total']) != null
              ? 'Rp ${(o['total_amount'] ?? o['total']).toString()}'
              : '';
          // Map backend ENUM -> friendly user-facing label per the agreed flow:
          // pending / preparing → Ongoing
          // ready / delivered   → Done
          // cancelled           → Cancelled
          String displayStatus;
          bool active;
          if (status == 'delivered' || status == 'ready') {
            displayStatus = 'Done';
            active = false;
          } else if (status == 'cancelled') {
            displayStatus = 'Cancelled';
            active = false;
          } else {
            displayStatus = 'On Going';
            active = true;
          }
          final entry = {
            'id': o['id']?.toString() ?? '',
            'order_number': o['order_number']?.toString() ?? '',
            'date': date,
            'time': time,
            'items': items,
            'total': total,
            'status': displayStatus,
          };
          if (active) {
            nowActive.add(entry);
          } else {
            nowCompleted.add(entry);
          }
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
      return ListView(
        key: ValueKey<String>('${isActive}_empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Text(
              isActive ? "No active orders right now." : "No completed orders yet.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: ValueKey<bool>(isActive), // For AnimatedSwitcher to detect change
      physics: const AlwaysScrollableScrollPhysics(),
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
            (order['order_number'] != null && order['order_number'].toString().isNotEmpty)
                ? order['order_number'].toString()
                : "#${order['id']}",
            style: TextStyle(
              color: textDark,
              fontSize: 22,
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

  // --- Bottom Navigation Bar (unified 4-tab layout matching HomeScreen) ---
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
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}