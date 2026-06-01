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
  final String baseUrl = 'http://localhost:3000'; // IP khusus Emulator Android ke localhost komputer
  List<Map<String, dynamic>> _menu = [];
  bool _loading = true;
  String? _errorMessage;

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
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // Menambahkan timeout 10 detik agar loading tidak menggantung selamanya
      final res = await http.get(Uri.parse('$baseUrl/api/menu')).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"success":false,"error":"Connection Timeout"}', 408),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List list = data['menu'] ?? [];
        setState(() {
          _menu = list.map<Map<String, dynamic>>((item) {
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
              'id': item['id']?.toString() ?? '0',
              'name': (item['name'] ?? '').toString(),
              'category': _catName(item['category_id']),
              'basePrice': double.tryParse((item['base_price'] ?? 0).toString())?.round() ?? 0,
              'img': _resolveImage(item['name'], item['image_url']),
              'selectedSpice': prefs.isNotEmpty ? prefs[0] : '',
              'spiceOptions': prefs,                  // SELALU List<String>, tidak null
              'selectedAddons': <String>[],           // SELALU List<String>, tidak null
              'addonOptions': addons,                 // SELALU Map<String,int>, tidak null
            };
          }).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server Error (${res.statusCode}). Periksa apakah backend Node.js bermasalah.';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Menu fetch error: $e');
      setState(() {
        _errorMessage = 'Gagal terhubung ke database. Pastikan server backend Anda sudah menyala di port 3000.\nDetail: $e';
        _loading = false;
      });
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

  String _resolveImage(dynamic name, dynamic url) {
    if (url != null && url.toString().isNotEmpty) return url.toString();
    final n = (name ?? '').toString().toLowerCase();
    if (n.contains('tuna') || n.contains('sando'))      return 'assets/images/sando(new_bonus_unlock).png';
    if (n.contains('truffle') || n.contains('toast'))   return 'assets/images/prod_brunch_deals.png';
    if (n.contains('brisket') || n.contains('hash'))    return 'assets/images/prod_brunch_deals (2).png';
    if (n.contains('pistachio') && n.contains('crois')) return 'assets/images/crossait(new_bonus_unlock).png';
    if (n.contains('butter croissant'))                 return 'assets/images/crossait(new_bonus_unlock).png';
    if (n.contains('croissant'))                        return 'assets/images/crossait(new_bonus_unlock).png';
    if (n.contains('sea salt') || n.contains('latte'))  return 'assets/images/prod_coffee_splash.png';
    if (n.contains('americano') || n.contains('coffee'))return 'assets/images/prod_coffee_splash.png';
    if (n.contains('matcha'))                           return 'assets/images/prod_triple_brew.png';
    if (n.contains('chocolate') || n.contains('lychee'))return 'assets/images/prod_triple_brew.png';
    if (n.contains('trio') || n.contains('combo'))      return 'assets/images/prod_trio_cafe.png';
    return 'assets/images/prod_triple_brew.png';
  }

  String _formatRp(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';

  int get _cartSubtotal {
    int total = 0;
    for (var item in CartManager.instance.items) {
      int itemCost = item['basePrice'] as int;
      total += itemCost * (item['quantity'] as int);
    }
    return total;
  }

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
      body: _buildBody(),
      bottomNavigationBar: CartManager.instance.count > 0
          ? SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TakeoutPage()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: primaryGreen.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${CartManager.instance.count} Item${CartManager.instance.count > 1 ? 's' : ''}',
                                style: const TextStyle(color: Color(0xFFE2E9C5), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(_formatRp(_cartSubtotal),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text('View Basket', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    // Skenario 1: Sedang Loading
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryGreen, strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Menghubungkan ke Lumiora Database...',
              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Skenario 2: Terjadi Eror Koneksi / Database Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 80, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Koneksi Gagal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Skenario 3: Data Kosong
    if (_menu.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: primaryGreen.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Menu Belum Tersedia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Database kosong atau tidak ada menu aktif.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Skenario 4: Berhasil Menampilkan Menu
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menu.length,
      itemBuilder: (c, i) {
        final item = _menu[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  item['img'],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90, height: 90,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood),
                  ),
                ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item['name']} added to basket'),
                      duration: const Duration(milliseconds: 1500),
                      action: SnackBarAction(
                        label: 'View Basket',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TakeoutPage()),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}