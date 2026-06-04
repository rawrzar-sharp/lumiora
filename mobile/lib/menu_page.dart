  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'cart_manager.dart';
  import 'cart.dart';
  import 'profile.dart';
  import 'main.dart'; 

  class MenuPage extends StatefulWidget {
    const MenuPage({super.key});
    @override
    State<MenuPage> createState() => _MenuPageState();
  }

  class _MenuPageState extends State<MenuPage> {
    final Color primaryGreen = const Color(0xFF7B8C2A);
    final Color textDark = const Color(0xFF2C3028);
    final Color lightGreenCard = const Color(0xFFDCE2B9);
    final String baseUrl = 'http://localhost:3000';
    
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
      return ['All', ...cats]; // Keep 'All' as the first option
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

    void _onFooterItemTapped(int index) {
      if (index == _bottomNavIndex) return;

      if (index == 0) {
        Navigator.pop(context);
      } else {
        setState(() {
          _bottomNavIndex = index;
        });
      }
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
                'img': _resolveImage(item['name'], item['image_url'], item['category_id']),
                'selectedSpice': prefs.isNotEmpty ? prefs[0] : '',
                'spiceOptions': prefs,                  
                'selectedAddons': <String>[],           
                'addonOptions': addons,                 
              };
            }).toList();
            
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
        case 1: return 'Brunch';
        case 2: return 'Pastry';
        case 3: return 'Coffee';
        case 4: return 'Non-Coffee';
        case 5: return 'Trio Deals';
        default: return 'Other';
      }
    }

    String _resolveImage(dynamic name, dynamic url, dynamic categoryId) {
      final n = (name ?? '').toString().toLowerCase();

      if (n.contains('tuna') || n.contains('sando')) return 'assets/images/sando(new_bonus_unlock).png';
      if (n.contains('croissant') || n.contains('pastry')) return 'assets/images/crossait(new_bonus_unlock).png';
      if (n.contains('toast') || n.contains('brisket') || n.contains('hash')) return 'assets/images/prod_brunch_deals (3).png'; 
      
      if (n.contains('matcha') || n.contains('green')) return 'assets/images/prod_trio_cafe.png';
      if (n.contains('caramel') || n.contains('macchiato')) return 'assets/images/prod_brunch_deals (2).png';
      if (n.contains('americano') || n.contains('black') || n.contains('sea salt')) return 'assets/images/prod_coffee_splash.png';
      if (n.contains('latte') || n.contains('milk')) return 'assets/images/prod_trio_cafe (2).png';
      if (n.contains('trio') || n.contains('combo')) return 'assets/images/Triplecafe(new_bonus_unlock).png';

      final cat = int.tryParse(categoryId?.toString() ?? '0') ?? 0;
      switch (cat) {
        case 1: return 'assets/images/prod_brunch_deals (3).png'; 
        case 2: return 'assets/images/crossait(new_bonus_unlock).png'; 
        case 3: return 'assets/images/prod_coffee_splash.png'; 
        case 4: return 'assets/images/prod_triple_brew.png'; 
        case 5: return 'assets/images/prod_trio_cafe.png'; 
        default: return 'assets/images/prod_triple_brew.png'; 
      }
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB59A57), width: 1.5),
                  ),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 13,
                          top: 4,
                          child: Text(
                            'L',
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFB59A57),
                              height: 1.1,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 11,
                          child: Icon(
                            Icons.spa, 
                            size: 15, 
                            color: Color(0xFFB59A57),
                          ),
                        ),
                      ],
                    ),
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
        final String imagePath = item['img']?.toString() ?? '';
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
                child: imagePath.startsWith('assets/')
                    ? Image.asset(
                        imagePath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                      )
                    : Image.network(
                        imagePath.startsWith('http') ? imagePath : '$baseUrl$imagePath',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), 
                    const SizedBox(height: 4),
                    Text('Description here...', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text(_formatRp(item['basePrice']), style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: primaryGreen, size: 28), 
                onPressed: () {
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

                  if (spiceOpts.isNotEmpty || addonOpts.isNotEmpty) {
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

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final List<String> spiceOpts = List<String>.from(tempItem['spiceOptions'] ?? []);
              final Map<String, int> addonOpts = Map<String, int>.from(tempItem['addonOptions'] ?? {});
              final List<String> itemSelectedAddons = List<String>.from(tempItem['selectedAddons'] ?? []);

              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F1E1),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(tempItem['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text("Customize your item", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),
                    
                    if (spiceOpts.isNotEmpty) ...[
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