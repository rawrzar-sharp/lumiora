import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'takeout.dart';
import 'menu_page.dart';
import 'splash.dart';
import 'payment.dart';
import 'profile.dart';
import 'history.dart';

// KODE BARU UNTUK main.dart (Bagian Atas)
class GlobalState {
  static String? userName;
  static bool showRewardPopup = false;
  static int vouchersCount = 0;
  static bool bannerBonusClaimed = false;
  static int currentCardStamps = 0;
  static int? customerId; // persisted customer id from backend
  
  // --- TAMBAHAN FASE 3: Pengontrol Dark Mode ---
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to restore persisted user data from SharedPreferences
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // --- TAMBAHAN FASE 3: Membaca Tema Terakhir ---
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    GlobalState.themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    final stored = prefs.getString('user_data');
    if (stored != null && stored.isNotEmpty) {
      final dynamic decoded = jsonDecode(stored);
      final Map<String, dynamic> data = (decoded is Map && decoded['data'] is Map)
          ? Map<String, dynamic>.from(decoded['data'])
          : (decoded is Map && decoded['user'] is Map)
              ? Map<String, dynamic>.from(decoded['user'])
              : Map<String, dynamic>.from(decoded);
      GlobalState.userName = data['name'] as String?;
      GlobalState.vouchersCount = (data['vouchers'] is int) ? data['vouchers'] as int : int.tryParse('${data['vouchers']}') ?? 0;
      GlobalState.currentCardStamps = (data['loyalty_stamps'] is int) ? data['loyalty_stamps'] as int : int.tryParse('${data['loyalty_stamps']}') ?? 0;
      GlobalState.customerId = int.tryParse((data['customer_id'] ?? data['id'] ?? '').toString());
    }
  } catch (e) {
    // ignore restore errors
  }

  runApp(const MyApp());
}


// KODE BARU UNTUK MyApp
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- TAMBAHAN FASE 3: Listener Tema ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: GlobalState.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lumiora Home',
          themeMode: currentMode, // Terapkan tema saat ini
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Sans-Serif',
            scaffoldBackgroundColor: const Color(0xFFEBE5D9),
            primaryColor: const Color(0xFF7B8C2A),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Sans-Serif',
            scaffoldBackgroundColor: const Color(0xFF121212), // Warna background gelap
            primaryColor: const Color(0xFF7B8C2A),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
            ),
          ),
          home: const SplashScreen(), 
        );
      },
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

 class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);

  int _bottomNavIndex = 0;
  bool _isTrioActive = true;

  @override
  void initState() {
    super.initState();
    
    // 🔥 PERBAIKAN POP-UP: Cek apakah ada hadiah setelah kembali dari pembayaran
    if (GlobalState.showRewardPopup) {
      GlobalState.showRewardPopup = false; // Matikan agar tidak muncul terus-menerus
      
      // Gunakan post-frame callback agar dialog muncul SETELAH halaman beres dimuat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRewardDialog();
      });
    }
  }

  // --- POP-UP HADIAH (DESAIN BARU SESUAI IDE KAMU!) ---
  void _showRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Memaksa user memencet tombol
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F1), // Warna cream background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryGreen, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Bintang / Medali
              Icon(Icons.stars_rounded, color: Colors.amber.shade500, size: 70),
              const SizedBox(height: 16),

              // Judul
              Text(
                "STAMP CARD COMPLETED!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Deskripsi
              const Text(
                "Awesome! You've collected 10 stamps.\nEnjoy your free coffee on us!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // UI Kartu Voucher (Ticket Style)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ]
                ),
                child: Row(
                  children: [
                    // Bagian Kiri (Hijau)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.local_cafe, color: Colors.white, size: 36),
                    ),
                    // Garis Putus-putus (Divider)
                    Container(
                      height: 80,
                      width: 2,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300, width: 2, style: BorderStyle.none),
                        ),
                      ),
                      child: CustomPaint(
                        painter: DottedLinePainter(color: Colors.grey.shade300),
                      ),
                    ),
                    // Bagian Kanan (Teks Voucher)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("1x Free Coffee", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textDark)),
                            const SizedBox(height: 4),
                            Text("Valid for any classic brew", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tombol-tombol
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context); // Tutup Pop-up
                },
                child: const Text("Got it!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  // Opsional: Nanti bisa ditambah navigasi ke halaman list voucher
                },
                child: Text("See My Vouchers", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

 void _onFooterItemTapped(int index) {
    if (index == _bottomNavIndex) return; 

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
      ).then((_) {
        if (mounted) setState(() => _bottomNavIndex = 0);
      });
    } else if (index == 2) {
      // History tab — accessible from the home footer per spec.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      ).then((_) {
        if (mounted) setState(() => _bottomNavIndex = 0);
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      ).then((_) {
        if (mounted) setState(() => _bottomNavIndex = 0);
      });
    } else {
      setState(() {
        _bottomNavIndex = index;
      });
    }
  }   

  void _navigateToMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MenuPage()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _bottomNavIndex = 0;
        });
      }
    });
  }

  final List<Map<String, String>> trioProducts = [
    {'title': 'Trio Cafe', 'desc': 'Triple the drinks.\nTriple the fun.', 'price': 'Rp 50.000', 'rating': '5.0', 'img': 'assets/images/prod_trio_cafe.png'},
    {'title': 'Triple Brew', 'desc': 'Matcha, Choco, and\nCoffee', 'price': 'Rp 65.000', 'rating': '5.0', 'img': 'assets/images/prod_triple_brew.png'},
    {'title': 'Coffee Splash', 'desc': 'Cappuccino, Latte, and\nCaramel Macchiato', 'price': 'Rp 55.000', 'rating': '4.5', 'img': 'assets/images/prod_coffee_splash.png'},
    {'title': 'Brunch Deals', 'desc': 'Vanilla latte, Cappuccino,\nand Sando', 'price': 'Rp 45.000', 'rating': '5.0', 'img': 'assets/images/prod_brunch_deals.png'},
  ];

  final List<Map<String, String>> duoProducts = [
    {'title': 'Duo Cafe', 'desc': 'Start work with your\nfave latte cup.', 'price': 'Rp 25.000', 'rating': '4.8', 'img': 'assets/images/prod_coffee_splash.png'},
    {'title': 'Twin-Flavors', 'desc': 'Caramel macchiato\n+ Latte', 'price': 'Rp 30.000', 'rating': '4.9', 'img': 'assets/images/prod_triple_brew.png'},
    {'title': 'Sit Down Deals', 'desc': 'Lava Hazelnut + Croissant', 'price': 'Rp 18.000', 'rating': '4.7', 'img': 'assets/images/prod_brunch_deals.png'}, 
    {'title': 'Dual Brews', 'desc': 'Cappuccino + Matcha', 'price': 'Rp 38.000', 'rating': '4.8', 'img': 'assets/images/prod_triple_brew.png'}, 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroAndHeader(),
            Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: DottedBackgroundPainter(color: lightGreenCard.withOpacity(0.5)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      // const SizedBox(height: 16),
                      // _buildStampTrackerCard(), 
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildToggle(),
                  const SizedBox(height: 20),
                  _buildProductGrid(),
                  const SizedBox(height: 20),
                  _buildGrandFeastBanner(), 
                  const SizedBox(height: 20), 
                  _buildHorizontalDuoCards(), // Relocated right below Grand Feast Banner with full designs
                  const SizedBox(height: 20),
                  _buildBonusUnlockedCard(), 
                  const SizedBox(height: 24),
                  _buildHalalFooterCard(), // High-Fidelity Mockup Redesign
                  const SizedBox(height: 40),
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

  Widget _buildHeroAndHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              height: 260,
              width: double.infinity,
              color: const Color(0xFFFBF8F1),
              child: Image.asset(
                'assets/images/hero_coffee_splash.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: primaryGreen.withOpacity(0.15),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, color: primaryGreen, size: 40),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              color: primaryGreen,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${GlobalState.userName?.split(' ')[0] ?? 'Guest'}!',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Earn stamps with every order',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Stamps badge — placed BEFORE vouchers per the spec
                      _buildStatBadge(Icons.workspace_premium, GlobalState.currentCardStamps.toString(), 'Stamps'),
                      const SizedBox(width: 10),
                      // Vouchers badge
                      _buildStatBadge(Icons.confirmation_num, GlobalState.vouchersCount.toString(), 'Vouchers'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
// Lumiora logo medallion — bigger + uses the real brand asset
        Positioned(
          right: 18,
          top: 192,
          child: HoverBounceWrapper(
            onTap: () {},
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F1),
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen, width: 5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              // 1. REMOVED the padding so the image touches the green border
              
              // 2. WRAPPED the image in a ClipOval (acts as a circular cookie-cutter)
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_lumiora.png',
                  // 3. CHANGED to BoxFit.cover so the grey background fills the circle entirely
                  fit: BoxFit.cover, 
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa, color: primaryGreen, size: 40),
                        const SizedBox(height: 4),
                        Text('LUMIORA',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w900, color: textDark, letterSpacing: 1.6)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label) {
    return HoverBounceWrapper(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEBE5D9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, height: 1)),
                Text(label, style: const TextStyle(fontSize: 9, color: Colors.black87, height: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: HoverBounceWrapper(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TakeoutPage()),
              );
            },
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFEBE5D9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryGreen, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_cafe, size: 45, color: primaryGreen),
                  const SizedBox(height: 8),
                  Text('Pick Up', style: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: HoverBounceWrapper(
            onTap: () {}, 
            child: Container(
              height: 110,
              decoration: BoxDecoration(color: darkGrey, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delivery_dining, size: 40, color: Colors.white38),
                  SizedBox(height: 4),
                  Text('COMING SOON', style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 0.5)),
                  Text('Delivery', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HoverBounceWrapper(
            onTap: () => setState(() => _isTrioActive = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                color: !_isTrioActive ? primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text('Duo', style: TextStyle(fontWeight: FontWeight.bold, color: !_isTrioActive ? Colors.white : primaryGreen)),
            ),
          ),
          HoverBounceWrapper(
            onTap: () => setState(() => _isTrioActive = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                color: _isTrioActive ? primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text('Trio', style: TextStyle(fontWeight: FontWeight.bold, color: _isTrioActive ? Colors.white : primaryGreen)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _isTrioActive ? trioProducts : duoProducts;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return HoverBounceWrapper(
          onTap: _navigateToMenu, 
          child: Container(
            decoration: BoxDecoration(color: lightGreenCard, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 12, color: primaryGreen),
                        const SizedBox(width: 2),
                        Text(product['rating']!, style: TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(product['title']!, style: TextStyle(fontWeight: FontWeight.w900, color: primaryGreen, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(product['desc']!, style: TextStyle(fontSize: 9, color: primaryGreen, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text(product['price']!, style: TextStyle(fontWeight: FontWeight.w500, color: textDark, fontSize: 12)),
                  ],
                ),
                Positioned(
                  right: -15, bottom: -15,
                  child: SizedBox(
                    width: 85, height: 85,
                    child: Image.asset(
                      product['img']!, 
                      fit: BoxFit.contain, 
                      errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/prod_triple_brew.png', fit: BoxFit.contain)
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrandFeastBanner() {
    return HoverBounceWrapper(
      onTap: _navigateToMenu, 
      child: Container(
        height: 160, width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8DCC4),
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/banner_grand_feast.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16, top: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grand\nFeast', style: TextStyle(color: primaryGreen, fontSize: 32, fontFamily: 'serif', fontWeight: FontWeight.bold, height: 1.0)),
                  const SizedBox(height: 8),
                  const Text('The Ultimate\nSharing Combo\nfor Everyone', style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.2)),
                  const SizedBox(height: 12),
                  const Text('Rp 150.000', style: TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Text('Rp 105.000', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ),
            Positioned(
              right: 8, bottom: 0, top: 0,
              child: Image.asset(
                'assets/images/grand_feast.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DESIGN REFRESH: Upgraded Duo Slider Card Layout with specific header element & added cards
  Widget _buildHorizontalDuoCards() {
    final List<Map<String, dynamic>> multiDuoItems = [
      {'title': 'Tea & Croissant Duo', 'price': 'Rp 35.000', 'icon': Icons.coffee, 'bgColor': const Color(0xFFF1F5EC)},
      {'title': 'Coffee & Cake Duo', 'price': 'Rp 40.000', 'icon': Icons.cake, 'bgColor': const Color(0xFFEDF2E7)},
      {'title': 'Matcha & Tart Duo', 'price': 'Rp 38.000', 'icon': Icons.cookie, 'bgColor': const Color(0xFFE7ECE1)},
      {'title': 'Chai & Muffin Duo', 'price': 'Rp 36.000', 'icon': Icons.icecream_outlined, 'bgColor': const Color(0xFFEFF4EA)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exclusive Duo Combos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              Text(
                'Slide for more →',
                style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: multiDuoItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final duo = multiDuoItems[index];
              return HoverBounceWrapper(
                onTap: _navigateToMenu,
                child: Container(
                  width: 185,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: duo['bgColor'],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(duo['icon'], color: primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              duo['title'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark, height: 1.15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              duo['price'],
                              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- BANNER VOUCHER DIKLIK ---
  Widget _buildBonusUnlockedCard() {
    bool isClaimed = GlobalState.bannerBonusClaimed;

    return HoverBounceWrapper(
      onTap: () {
        if (!isClaimed) {
          setState(() {
            // 🔥 UPDATE: Tandai banner sudah diklaim, dan tambah vouchernya!
            GlobalState.bannerBonusClaimed = true;
            GlobalState.vouchersCount += 1; 
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎉 Bonus voucher claimed successfully! Check your pocket.'),
              backgroundColor: darkGrey,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isClaimed 
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF7B8C2A), const Color(0xFF5E6D1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isClaimed ? 'Voucher Claimed' : 'Milestone Bonus Unlocked!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isClaimed ? 'Applied to your next checkout menu item' : 'Tap to claim your 20% Weekend Treats Voucher',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isClaimed ? Icons.check_circle : Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // High-fidelity Halal Indonesia certification card (proper white-on-green
  // contrast — the previous build had white text on a pale green background
  // which was unreadable).
  Widget _buildHalalFooterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, const Color(0xFF5E6D1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: primaryGreen.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mark / emblem
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(40, 50),
                painter: HalalLogoEmblemPainter(),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'CERTIFIED HALAL',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Halal Indonesia',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ID241103130106 • BPJPH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
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
            // Notice how we include the onTap parameter here!
            _buildNavItem(Icons.home_filled, 'Home', 0, onTap: () => _onFooterItemTapped(0)),
            _buildNavItem(Icons.local_cafe, 'Menu', 1, onTap: () => _onFooterItemTapped(1)),
            const SizedBox(width: 48), // Leaves space for the floating QR Button
            _buildNavItem(Icons.receipt_long, 'History', 2, onTap: () => _onFooterItemTapped(2)),
            _buildNavItem(Icons.person, 'Profile', 3, onTap: () => _onFooterItemTapped(3)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {required VoidCallback onTap}) {
    final isActive = _bottomNavIndex == index;
    final color = isActive ? primaryGreen : Colors.grey.shade500;
    return Expanded(
      child: HoverBounceWrapper(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class HoverBounceWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const HoverBounceWrapper({Key? key, required this.child, this.onTap}) : super(key: key);
  @override
  State<HoverBounceWrapper> createState() => _HoverBounceWrapperState();
}

class _HoverBounceWrapperState extends State<HoverBounceWrapper> {
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
        child: AnimatedScale(scale: scale, duration: const Duration(milliseconds: 150), curve: Curves.easeInOut, child: widget.child),
      ),
    );
  }
}

class DottedBackgroundPainter extends CustomPainter {
  final Color color;
  DottedBackgroundPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (double i = 0; i < size.width; i += 15) {
      for (double j = 0; j < size.height; j += 15) {
        canvas.drawCircle(Offset(i, j), 1.5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tambahan: Painter untuk efek garis putus-putus pada kartu voucher di dialog pop-up
class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
      
    const double dashHeight = 5;
    const double dashSpace = 4;
    double startY = 0;
    
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HalalLogoEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final baseOutlinePath = Path();
    baseOutlinePath.moveTo(size.width * 0.5, size.height * 0.05);
    baseOutlinePath.lineTo(size.width * 0.05, size.height * 0.85);
    baseOutlinePath.lineTo(size.width * 0.95, size.height * 0.85);
    baseOutlinePath.close();
    canvas.drawPath(baseOutlinePath, paint);

    // Dynamic interior line partitions matching high-fidelity asset shapes
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.05), Offset(size.width * 0.5, size.height * 0.85), paint);
    canvas.drawLine(Offset(size.width * 0.32, size.height * 0.35), Offset(size.width * 0.32, size.height * 0.85), paint);
    canvas.drawLine(Offset(size.width * 0.68, size.height * 0.35), Offset(size.width * 0.68, size.height * 0.85), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}