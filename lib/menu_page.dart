import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cart_manager.dart';
import 'takeout.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final String baseUrl = 'http://10.0.2.2:3000';
  List<Map<String, dynamic>> _menu = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    CartManager.instance.addListener(_onCartChange);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChange);
    super.dispose();
  }

  void _onCartChange() => setState(() {});

  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/menu'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List list = data['menu'] ?? [];
        setState(() {
          _menu = list.map<Map<String, dynamic>>((item) {
            // Parse customization JSON
            List<String> prefs = [];
            Map<String, int> addons = {};
            if (item['customization_options'] != null) {
              try {
                final raw = item['customization_options'];
                final parsed = raw is String ? json.decode(raw) : raw;
                if (parsed['preferences'] != null) {
                  prefs = List<String>.from(parsed['preferences']);
                }
                if (parsed['addons'] != null) {
                  (parsed['addons'] as Map).forEach((k, v) {
                    addons[k.toString()] = int.parse(v.toString());
                  });
                }
              } catch (_) {}
            }
            return {
              'id': item['id'].toString(),
              'name': item['name'] ?? '',
              'category': _catName(item['category_id']),
              'basePrice': double.parse(item['base_price'].toString()).round(),
              'img': item['image_url'] ?? 'assets/images/prod_triple_brew.png',
              'selectedSpice': prefs.isNotEmpty ? prefs[0] : '',
              'spiceOptions': prefs,
              'selectedAddons': <String>[],
              'addonOptions': addons,
            };
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Menu fetch error: $e');
      setState(() => _loading = false);
    }
  }

  String _catName(dynamic cid) {
    switch (int.tryParse(cid.toString()) ?? 0) {
      case 1: return 'Brunch';
      case 2: return 'Pastry';
      case 3: return 'Coffee';
      case 4: return 'Non-Coffee';
      case 5: return 'Trio Deals';
      default: return 'Other';
    }
  }

  String _formatRp(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1E1),
      appBar: AppBar(
        title: const Text('MENU', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_basket),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TakeoutPage()),
                ),
              ),
              if (CartManager.instance.count > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${CartManager.instance.count}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _menu.length,
              itemBuilder: (c, i) {
                final item = _menu[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(item['img'], width: 70, height: 70, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.fastfood))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            Text(item['category'], style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_formatRp(item['basePrice']), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: primaryGreen, size: 32),
                        onPressed: () {
                          CartManager.instance.addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${item['name']} added to basket'),
                            duration: const Duration(milliseconds: 800),
                          ));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}