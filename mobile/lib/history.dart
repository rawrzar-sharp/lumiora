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
          // Keep the items as structured maps so the UI can render the friendly
          // label PLUS the customer's selected preferences (Ice / Sugar / etc.),
          // add-ons and notes underneath each line. Previously we flattened
          // these into a single string and lost everything but the label.
          final items = rawItems.map((it) {
            if (it is Map) {
              final label = it['label']
                  ?? (it['item_name'] != null
                      ? '${it['quantity']}x ${it['item_name']}'
                      : it['name']?.toString() ?? '');

              // preferences_json is stored as a JSON column in MySQL; mysql2
              // sometimes returns it parsed, sometimes as a string — handle both.
              dynamic prefsRaw = it['preferences_json'];
              if (prefsRaw is String && prefsRaw.isNotEmpty) {
                try { prefsRaw = jsonDecode(prefsRaw); } catch (_) { prefsRaw = null; }
              }
              final Map<String, String> prefs = {};
              if (prefsRaw is Map) {
                prefsRaw.forEach((k, v) {
                  if (v != null && v.toString().isNotEmpty) {
                    prefs[k.toString()] = v.toString();
                  }
                });
              }

              dynamic addonsRaw = it['addons_json'];
              if (addonsRaw is String && addonsRaw.isNotEmpty) {
                try { addonsRaw = jsonDecode(addonsRaw); } catch (_) { addonsRaw = null; }
              }
              final List<String> addons = (addonsRaw is List)
                  ? addonsRaw.map((a) => a.toString()).where((s) => s.isNotEmpty).toList()
                  : <String>[];

              return {
                'label': label.toString(),
                'preferences': prefs,
                'addons': addons,
                'notes': (it['notes'] ?? '').toString(),
              };
            }
            return {
              'label': it.toString(),
              'preferences': <String, String>{},
              'addons': <String>[],
              'notes': '',
            };
          }).toList();
          final totalRaw = (o['total_amount'] ?? o['total']);
          String total = '';
          if (totalRaw != null) {
            // Format as "Rp 65.340" (no decimals, dot thousand separator) so it
            // matches the rest of the app instead of showing the raw DB value
            // "Rp 65340.00" that confuses customers.
            final asNum = num.tryParse(totalRaw.toString()) ?? 0;
            final whole = asNum.round();
            final withDots = whole.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            );
            total = 'Rp $withDots';
          }
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
            // Keep the raw DB status so the UI can distinguish "ready" (waiting
            // for pickup → show Take Your Order CTA) from "delivered" (fully
            // handed over → only Reorder makes sense).
            'raw_status': status,
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
          
          // Items + Price Row. Each item now renders its label PLUS the
          // customer's selected preferences (Ice / Sugar / Bean / etc.),
          // add-ons and any notes — so the On Going card actually tells you
          // what's being made, not just "1x Vanilla Latte".
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(order['items'].length, (index) {
                    final it = order['items'][index];
                    final String label = it is Map ? (it['label']?.toString() ?? '') : it.toString();
                    final Map prefs = (it is Map && it['preferences'] is Map) ? it['preferences'] as Map : const {};
                    final List addons = (it is Map && it['addons'] is List) ? it['addons'] as List : const [];
                    final String notes = (it is Map ? (it['notes']?.toString() ?? '') : '').trim();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (prefs.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                prefs.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' • '),
                                style: TextStyle(
                                  color: textDark.withOpacity(0.65),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (addons.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Add-ons: ${addons.join(', ')}',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Note: $notes',
                                style: TextStyle(
                                  color: textDark.withOpacity(0.6),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
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

          // Action area:
          //  - Completed + raw_status == "ready"   → show "Take Your Order"
          //    pickup card next to Reorder so the customer knows the kitchen
          //    has finished and they should come to the counter.
          //  - Completed + "delivered" / other    → only Reorder.
          //  - Active orders                      → no buttons (the live On
          //    Going pill at the top already tells the story).
          if (!isActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if ((order['raw_status'] ?? '').toString().toLowerCase() == 'ready')
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryGreen, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: primaryGreen, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Take Your Order',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Send the user back to the menu so they can rebuild the order.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuPage()),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reorder', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                ),
              ],
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