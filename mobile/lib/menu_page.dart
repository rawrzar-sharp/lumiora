  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:flutter/foundation.dart';
  import 'cart_manager.dart';
  import 'cart.dart';
  import 'profile.dart';
  import 'main.dart'; 
  import 'app_config.dart';

  class MenuPage extends StatefulWidget {
    const MenuPage({super.key});
    @override
    State<MenuPage> createState() => _MenuPageState();
  }

  class _MenuPageState extends State<MenuPage> {
    final Color primaryGreen = const Color(0xFF7B8C2A);
    final Color textDark = const Color(0xFF2C3028);
    final Color lightGreenCard = const Color(0xFFDCE2B9);
    String get baseUrl => AppConfig.backendUrl;
    
    List<Map<String, dynamic>> _menu = [];
    bool _loading = true;
    String? _errorMessage;
    
    int _bottomNavIndex = 1; 

    // --- Scroll Spy Setup ---
    String _selectedCategory = 'All';
    final ScrollController _scrollController = ScrollController();
    final Map<String, GlobalKey> _categoryKeys = {};
    bool _isProgrammaticScroll = false;

    List<String> get _categories {
      final cats = _menu.map((e) => e['category'].toString()).toSet().toList();
      // Prefer a stable ordering that matches lumiora.sql categories
      final preferred = [
        'Latte Series',
        'Classics',
        'Non-Coffee',
        'Bundling Duo',
        'Bundling Trio',
        'Pastry & Bakery',
        'Skewers',
      ];

      final ordered = <String>[];
      for (var p in preferred) {
        if (cats.contains(p)) ordered.add(p);
      }
      // add any other categories not in preferred
      for (var c in cats) {
        if (!ordered.contains(c)) ordered.add(c);
      }

      return ['All', ...ordered]; // Keep 'All' as the first option
    }

    Map<String, List<Map<String, dynamic>>> get _groupedMenu {
      Map<String, List<Map<String, dynamic>>> map = {};
      for (var item in _menu) {
        final cat = item['category'].toString();
        if (!map.containsKey(cat)) map[cat] = [];
        map[cat]!.add(item);
      }
      return map;
    }

    @override
    void initState() {
      super.initState();
      _fetch();
      CartManager.instance.addListener(_onCartChange);
      _scrollController.addListener(_onScroll);
    }

    @override
    void dispose() {
      CartManager.instance.removeListener(_onCartChange);
      _scrollController.removeListener(_onScroll);
      _scrollController.dispose();
      super.dispose();
    }

      void _onCartChange() => setState(() {});

    Future<void> _fetch() async {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
      try {
        final res = await http.get(Uri.parse('$baseUrl/api/menu')).timeout(
          const Duration(seconds: 10),
          onTimeout: () => http.Response('{"success":false,"error":"Connection Timeout"}', 408),
        );
        if (!mounted) return; 

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          // support multiple API shapes: { menu: [...] } or { data: [...] }
          final List list = (data['menu'] is List)
              ? List.from(data['menu'])
              : (data['data'] is List) ? List.from(data['data']) : [];
          setState(() {
            final mappedList = list.map<Map<String, dynamic>>((item) {
              List<String> prefs = [];
              Map<String, List<String>> prefGroups = {};
              Map<String, int> addons = {};

              // customization options may be stored as JSON or missing.
              // The new schema exposes `preference_groups`, a map of
              // "Ice Level" → [...], "Sugar Level" → [...] etc.
              // We still parse the legacy `preferences` array as a fallback.
              final customRaw = item['customization_options'] ?? item['custom_options'] ?? item['custom'] ?? null;
              if (customRaw != null) {
                try {
                  final parsed = customRaw is String ? json.decode(customRaw) : customRaw;
                  if (parsed['preference_groups'] != null && parsed['preference_groups'] is Map) {
                    (parsed['preference_groups'] as Map).forEach((k, v) {
                      if (v is List) {
                        prefGroups[k.toString()] = List<String>.from(v.map((x) => x.toString()));
                      }
                    });
                  }
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

              // Default the first option of each preference group so the
              // bottom-sheet has something selected when it opens.
              final Map<String, String> defaultPrefs = {};
              prefGroups.forEach((k, v) {
                if (v.isNotEmpty) defaultPrefs[k] = v[0];
              });

              // Support both 'name' and legacy 'item_name'
              final rawName = item['name'] ?? item['item_name'] ?? '';
              final rawDesc = item['description'] ?? item['desc'] ?? '';
              final rawImg = item['image_url'] ?? item['image'] ?? item['img'] ?? '';
              final rawCategoryId = item['category_id'] ?? item['categoryId'] ?? item['cat_id'] ?? 0;
              final rawPrice = item['base_price'] ?? item['price'] ?? item['amount'] ?? 0;

              return {
                'id': item['id']?.toString() ?? '0',
                'name': rawName.toString(),
                'description': rawDesc.toString(),
                'category': _catName(rawCategoryId),
                'basePrice': double.tryParse(rawPrice.toString())?.round() ?? 0,
                'img': _resolveImage(rawName, rawImg, rawCategoryId),
                'is_available': item['is_available'] ?? 1,
                'stock': item['stock'] ?? 1,
                'selectedSpice': prefs.isNotEmpty ? prefs[0] : '',
                'spiceOptions': prefs,
                'preferenceGroups': prefGroups,
                'selectedPreferences': defaultPrefs,
                'selectedAddons': <String>[],
                'addonOptions': addons,
              };
            }).toList();
            
            _menu = mappedList.where((item) => 
              item['is_available'] == 1 || item['is_available'] == true
            ).toList();
            // Generate GlobalKeys for each unique category
            for (var cat in _categories) {
              if (cat != 'All') _categoryKeys[cat] = GlobalKey();
            }

            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Server Error (${res.statusCode}). Check if theres an issue behind this :3';
            _loading = false;
          });
        }
      } catch (e) {
        debugPrint('Menu fetch error: $e');
        setState(() {
          _errorMessage = 'Fail to Connect, Please Reset to ensure connection is correct.\nDetail: $e';
          _loading = false;
        });
      }
    }

    String _catName(dynamic cid) {
      switch (int.tryParse(cid.toString()) ?? 0) {
        case 1: return 'Latte Series';
        case 2: return 'Classics';
        case 3: return 'Non-Coffee';
        case 4: return 'Bundling Duo';
        case 5: return 'Bundling Trio';
        case 6: return 'Pastry & Bakery';
        case 7: return 'Skewers';
        default: return 'Other';
      }
    }

String _resolveImage(dynamic name, dynamic image_url, dynamic categoryId) {
  final String providedUrl = image_url?.toString().trim() ?? '';

  final Map<String, String> aliasMap = {
    'banana.png': 'bananalatte.png',
    'matcha.png': 'matchalatte.png',
    'matchalatte.png': 'matchalatte.png',
    'double_choc.png': 'doublechoco.png',
    'doublechoc.png': 'doublechoco.png',
    'triple_treat.png': 'tripletreat.png',
    'tripletreat.png': 'tripletreat.png',
    'nusantara_duo.png': 'nusantaraduo.png',
    'nusantaraduo.png': 'nusantaraduo.png',
    'caffe_mocha.png': 'caffemacha.png',
    'caffe mocha.png': 'caffemacha.png',
    'caffemacha.png': 'caffemacha.png',
    'house_favorites.png': 'housefav.png',
    'chocochips_muffin.png': 'chocomuffin.png',
    'ham_n_cheese_croissant.png': 'hamandcheese.png',
    'egg_sando.png': 'eggsando.png',
    'buttercream_aren_latte.png': 'buttercream.png',
    'creamy_aren_latte.png': 'creamyaren.png',
    'signature_pair.png': 'signaturepair.png',
  };

  String normalizeFilename(String value) {
    final clean = value.replaceAll(RegExp(r'^[\\/]+'), '').replaceAll(RegExp(r'\\+'), '/');
    final parts = clean.split('/');
    final baseName = parts.isNotEmpty ? parts.last : clean;
    return aliasMap[baseName.toLowerCase()] ?? baseName;
  }

  if (providedUrl.startsWith('http')) {
    return providedUrl;
  }

  if (providedUrl.startsWith('assets/')) {
    final resolved = normalizeFilename(providedUrl);
    return '$baseUrl/assets/images/$resolved';
  }

  if (providedUrl.startsWith('/assets/')) {
    final resolved = normalizeFilename(providedUrl);
    return '$baseUrl$resolved';
  }

  if (providedUrl.contains('.')) {
    final resolved = normalizeFilename(providedUrl);
    return '$baseUrl/assets/images/$resolved';
  }

  final slug = name
      ?.toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  if (slug != null && slug.isNotEmpty) {
    return '$baseUrl/assets/images/$slug.png';
  }

  return '$baseUrl/assets/images/prod_triple_brew.png';
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

    // --- Scroll Spy Interaction Logic ---
    void _onScroll() {
      if (_isProgrammaticScroll || _selectedCategory == 'All') return;

      String? closestCategory;
      for (var category in _categories.where((c) => c != 'All')) {
        final key = _categoryKeys[category];
        if (key?.currentContext != null) {
          final RenderBox box = key!.currentContext!.findRenderObject() as RenderBox;
          double dy = box.localToGlobal(Offset.zero).dy;
          
          // Threshold mapping logic to determine which section is active near the top
          if (dy <= 200 && dy > -500) { 
            closestCategory = category;
          }
        }
      }

      if (closestCategory != null && closestCategory != _selectedCategory) {
        setState(() {
          _selectedCategory = closestCategory!;
        });
      }
    }

    void _scrollToCategory(String category) async {
      setState(() {
        _selectedCategory = category;
      });

      if (category == 'All') {
        _isProgrammaticScroll = true;
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _isProgrammaticScroll = false;
        return;
      }

      final key = _categoryKeys[category];
      if (key?.currentContext != null) {
        setState(() {
          _isProgrammaticScroll = true;
        });
        
        await Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.05, 
        );
        
        Future.delayed(const Duration(milliseconds: 100), () {
          _isProgrammaticScroll = false;
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F1E1),
        body: SafeArea(
          top: true, 
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    _buildBody(),
                    if (CartManager.instance.count > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: SafeArea(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartPage()),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withOpacity(0.4), 
                                    blurRadius: 12, 
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${CartManager.instance.count} Item${CartManager.instance.count > 1 ? 's' : ''}',
                                                style: const TextStyle(color: Color(0xFFE2E9C5), fontSize: 12, fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                _formatRp(_cartSubtotal),
                                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12), 
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('View Cart', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    Widget _buildHeader() {
      return Container(
        color: const Color(0xFFF4F1E1),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Column(
          children: [
            Row(
              children: [
                // Load the image EXACTLY as it is, with no color blending
                Image.asset(
                  'assets/images/Only-Logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.spa, 
                    color: Color(0xFFB59A57), 
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1.5,
              width: double.infinity,
              color: const Color(0xFFB59A57).withOpacity(0.35),
            ),
          ],
        ),
      );
    }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        // Open QR Scanner
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR Scanner Opened")));
      },
      backgroundColor: primaryGreen,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFFEBE5D9),
      elevation: 10,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0, onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            }),
            _buildNavItem(Icons.local_cafe, 'Menu', 1, onTap: () {
              setState(() => _bottomNavIndex = 1);
            }),
            const SizedBox(width: 48), // Leaves space for the floating QR Button
            _buildNavItem(Icons.receipt_long, 'History', 2, onTap: () {}), // Add history routing later
            _buildNavItem(Icons.person, 'Profile', 3, onTap: () {
               // Route to profile page
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            }),
          ],
        ),
      ),
    );
  }

    Widget _buildNavItem(IconData icon, String label, int index, {required VoidCallback onTap}) {
      final isActive = _bottomNavIndex == index;
      final color = isActive ? primaryGreen : Colors.grey.shade500;
      return Expanded(
        child: MenuHoverBounceWrapper(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 4),
                Text(
                  label, 
                  style: TextStyle(fontSize: 11, color: color, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildFallbackImage() {
      return Image.asset(
        'assets/images/prod_triple_brew.png',
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    }

    Widget _buildBody() {
      if (_loading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryGreen, strokeWidth: 4),
              const SizedBox(height: 16),
              Text(
                'Connecting to Lumiora...',
                style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }

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

      if (_menu.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 80, color: primaryGreen.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text('Menu Belum Tersedia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Nothing here, No menu here, Start browsing today!', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      // --- UPGRADED UI: Split Layout (Sidebar + Scroll View) ---
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDEBAR (Category Switcher)
          Container(
            width: 90,
            color: const Color(0xFFF4F1E1),
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return InkWell(
                  onTap: () => _scrollToCategory(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.transparent : Colors.transparent,
                      border: Border(
                        right: BorderSide(
                          color: isSelected ? primaryGreen : Colors.transparent, 
                          width: 4
                        )
                      )
                    ),
                    child: Text(
                      cat,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? textDark : Colors.grey.shade600,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // RIGHT MAIN CONTENT (Scrollable Sections)
          Expanded(
            child: Container(
              color: const Color(0xFFEBE5D9), 
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), 
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedCategory == 'All' 
                    ? _buildAllSections() 
                    : [_buildSingleSection(_selectedCategory)],
                ),
              ),
            ),
          ),
        ],
      );
    }

    List<Widget> _buildAllSections() {
      return _categories.where((cat) => cat != 'All').map((cat) {
        return Column(
          key: _categoryKeys[cat],
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
              child: Text(
                cat,
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ..._buildItemsForCategory(cat),
            const SizedBox(height: 20),
          ],
        );
      }).toList();
    }

    Widget _buildSingleSection(String category) {
      return Column(
        key: _categoryKeys[category],
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
            child: Text(
              category,
              style: TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ..._buildItemsForCategory(category),
        ],
      );
    }

    List<Widget> _buildItemsForCategory(String category) {
      final items = _groupedMenu[category] ?? [];
      return items.map((item) {
        final String imagePath = (item['img'] ?? item['image_url'] ?? '').toString();
        final bool isRemote = imagePath.startsWith('http');
        final String resolvedImagePath = isRemote
            ? imagePath
            : (imagePath.startsWith('/assets/') || imagePath.startsWith('assets/'))
                ? '$baseUrl/${imagePath.replaceFirst('assets/', 'assets/')}'
                : '$baseUrl$imagePath';

        final bool isOutOfStock = (item['stock'] != null && item['stock'] <= 0);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
            ],
            border: Border.all(color: primaryGreen.withOpacity(0.15), width: 1),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: isOutOfStock ? 0.5 : 1.0,
                child: Image.network(
                  resolvedImagePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                ),
              ),
            ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), 
                    const SizedBox(height: 6),
                    Text(
                      (item['description'] ?? '').toString(),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Tampilkan Harga dan Label Habis
                    Row(
                      children: [
                        Text(_formatRp(item['basePrice']), style: TextStyle(fontWeight: FontWeight.w800, color: isOutOfStock ? Colors.grey : primaryGreen, fontSize: 13)),
                        if (isOutOfStock) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade200)),
                            child: const Text('HABIS', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
             IconButton(
                icon: Icon(Icons.add_circle, color: isOutOfStock ? Colors.grey.shade300 : primaryGreen, size: 32), 
                onPressed: isOutOfStock ? null : () {
                  if (GlobalState.userName == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please Login / Sign Up in Profile to start ordering!'),
                        backgroundColor: primaryGreen,
                        action: SnackBarAction(
                          label: 'Login',
                          textColor: Colors.white,
                          onPressed: () {
                            // Navigate to Profile to login
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                          },
                        ),
                      )
                    );
                    return; // Stop the function here if not logged in
                  }

                  // 2. If logged in, proceed normally
                  final List spiceOpts = item['spiceOptions'] ?? [];
                  final Map addonOpts = item['addonOptions'] ?? {};
                  final Map prefGroups = item['preferenceGroups'] ?? {};

                  if (spiceOpts.isNotEmpty || addonOpts.isNotEmpty || prefGroups.isNotEmpty) {
                    _showModifierSheet(context, item);
                  } else {
                    CartManager.instance.addItem(item);
                  }
                },
              ),
            ],
          ),
        );
      }).toList();
    }

    void _showModifierSheet(BuildContext context, Map<String, dynamic> originalItem) {
      final Map<String, dynamic> tempItem = Map<String, dynamic>.from(originalItem);
      tempItem['selectedAddons'] = List<String>.from(originalItem['selectedAddons'] ?? []);
      // Deep-clone the multi-axis preferences map so changes in the sheet are
      // discardable until the user taps Add to cart.
      tempItem['selectedPreferences'] = Map<String, String>.from(
        (originalItem['selectedPreferences'] as Map?)?.cast<String, String>() ?? <String, String>{},
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final List<String> spiceOpts = List<String>.from(tempItem['spiceOptions'] ?? []);
              final Map<String, int> addonOpts = Map<String, int>.from(tempItem['addonOptions'] ?? {});
              final Map<String, List<String>> prefGroups = (tempItem['preferenceGroups'] as Map?)
                  ?.map((k, v) => MapEntry(k.toString(), List<String>.from((v as List).map((x) => x.toString())))) ?? {};
              final Map<String, String> selectedPrefs = Map<String, String>.from(tempItem['selectedPreferences'] ?? {});
              final List<String> itemSelectedAddons = List<String>.from(tempItem['selectedAddons'] ?? []);

              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F1E1),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(tempItem['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text("Customize your item", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),

                    // NEW: render every preference axis (Ice Level / Sugar
                    // Level / Coffee Bean / Temperature / Spice Level / Style)
                    // as its own chip row. This is the customer-friendly view
                    // the round-4 ticket asked for.
                    ...prefGroups.entries.map((entry) {
                      final groupLabel = entry.key;
                      final opts = entry.value;
                      if (opts.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(groupLabel.toUpperCase(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryGreen)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: opts.map<Widget>((opt) {
                                final bool isSel = selectedPrefs[groupLabel] == opt;
                                return ChoiceChip(
                                  label: Text(opt,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold, fontSize: 12,
                                    )),
                                  selected: isSel,
                                  selectedColor: primaryGreen,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: primaryGreen.withOpacity(0.4)),
                                  ),
                                  onSelected: (_) => setModalState(() {
                                    selectedPrefs[groupLabel] = opt;
                                    tempItem['selectedPreferences'] = selectedPrefs;
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    if (prefGroups.isEmpty && spiceOpts.isNotEmpty) ...[
                      Text("PREFERENCES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryGreen)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: spiceOpts.map<Widget>((opt) {
                          bool isSel = tempItem['selectedSpice'] == opt;
                          return ChoiceChip(
                            label: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            selected: isSel,
                            selectedColor: primaryGreen,
                            backgroundColor: Colors.white,
                            onSelected: (val) => setModalState(() => tempItem['selectedSpice'] = opt),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (addonOpts.isNotEmpty) ...[
                      Text("ADD-ONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryGreen)),
                      const SizedBox(height: 8),
                      ...addonOpts.keys.map((addonKey) {
                        bool hasAddon = itemSelectedAddons.contains(addonKey);
                        int extraCost = addonOpts[addonKey] ?? 0;
                        return CheckboxListTile(
                          title: Text(addonKey, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text("+ ${_formatRp(extraCost)}", style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          value: hasAddon,
                          activeColor: primaryGreen,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool? checked) {
                            setModalState(() {
                              if (checked == true) {
                                itemSelectedAddons.add(addonKey);
                              } else {
                                itemSelectedAddons.remove(addonKey);
                              }
                              tempItem['selectedAddons'] = itemSelectedAddons;
                            });
                          },
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        CartManager.instance.addItem(tempItem);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Add to Cart", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ),    
                  ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  class MenuHoverBounceWrapper extends StatefulWidget {
    final Widget child;
    final VoidCallback? onTap;
    const MenuHoverBounceWrapper({Key? key, required this.child, this.onTap}) : super(key: key);

    @override
    State<MenuHoverBounceWrapper> createState() => _MenuHoverBounceWrapperState();
  }

  class _MenuHoverBounceWrapperState extends State<MenuHoverBounceWrapper> {
    bool _isHovering = false;
    bool _isPressed = false;

    @override
    Widget build(BuildContext context) {
      final double scale = _isPressed ? 0.95 : (_isHovering ? 1.02 : 1.0);
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (widget.onTap != null) widget.onTap!();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: widget.child,
          ),
        ),
      );
    }
  }