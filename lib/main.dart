import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumiora Home',
      theme: ThemeData(
        fontFamily: 'Sans-Serif',
        scaffoldBackgroundColor: const Color(0xFFEBE5D9), // Menyesuaikan warna background figma
        primaryColor: const Color(0xFF7B8C2A),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Warna Utama
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);

  // Fungsionalitas State
  int _bottomNavIndex = 0; // 0: Home, 1: Menu, 2: History, 3: Profile
  bool _isTrioActive = true; // True jika Trio dipilih, False jika Duo dipilih

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroAndHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  _buildPromoBanners(),
                  const SizedBox(height: 20),
                  _buildToggle(),
                  const SizedBox(height: 20),
                  _buildProductGrid(),
                  const SizedBox(height: 20),
                  _buildGrandFeastBanner(),
                  const SizedBox(height: 20),
                  _buildHalalFooter(),
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

  // --- WIDGET BUILDERS ---

  Widget _buildHeroAndHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            // TODO: GANTI DENGAN GAMBAR HERO KOPI
            // Gunakan Image.asset('assets/hero_kopi.png', fit: BoxFit.cover) jika sudah ada gambar
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE8DCC4),
                image: DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/600x400/E8DCC4/888888?text=Hero+Image+(3+Gelas+Kopi)'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              height: 90,
              width: double.infinity,
              color: primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, {Name}!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatBadge(Icons.stars, '123', 'Stamps'),
                      const SizedBox(width: 8),
                      _buildStatBadge(Icons.local_offer, '1', 'Vouchers'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // TODO: GANTI DENGAN GAMBAR LOGO LUMIORA
        Positioned(
          right: 16,
          top: 170, 
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1E1),
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.coffee, color: primaryGreen, size: 24), // Ganti ini dengan Image.asset logo asli
                  const SizedBox(height: 4),
                  Text(
                    'LUMIORA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 8, color: Colors.black54, height: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              // Aksi saat Pick Up diklik
            },
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGreen, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_cafe, size: 40, color: primaryGreen),
                  const SizedBox(height: 8),
                  Text(
                    'Pick Up',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: darkGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delivery_dining, size: 36, color: Colors.white38),
                const SizedBox(height: 4),
                const Text(
                  'COMING SOON',
                  style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Delivery',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanners() {
    return Column(
      children: [
        Container(
          height: 85,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New Bonus\nUnlock',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'First time buyer bonus.',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              // TODO: GANTI DENGAN GAMBAR ROTI/CROISSANT
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage('https://via.placeholder.com/150x100/7B8C2A/FFFFFF?text=Roti'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 85,
          decoration: BoxDecoration(
            color: lightGreenCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Brew Stamp\nCard',
                        style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Collect 9 stamps, Get\n10th cup for free!',
                        style: TextStyle(color: primaryGreen, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              // TODO: GANTI DENGAN GAMBAR KARTU STEMPEL
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Gambar\nStamp', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Duo
          GestureDetector(
            onTap: () {
              setState(() {
                _isTrioActive = false; // Ubah state ke Duo
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              decoration: BoxDecoration(
                color: !_isTrioActive ? primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Duo', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: !_isTrioActive ? Colors.white : Colors.black54
                )
              ),
            ),
          ),
          // Tombol Trio
          GestureDetector(
            onTap: () {
              setState(() {
                _isTrioActive = true; // Ubah state ke Trio
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              decoration: BoxDecoration(
                color: _isTrioActive ? primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Trio', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: _isTrioActive ? Colors.white : Colors.black54
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    // Data produk (Bisa diganti sesuai dengan Duo atau Trio kedepannya)
    final products = [
      {'title': 'Trio Cafe', 'desc': 'Triple the drinks.\nTriple the fun.', 'price': 'Rp 50.000', 'rating': '5.0'},
      {'title': 'Triple Brew', 'desc': 'Matcha, Choco, and\nCoffee', 'price': 'Rp 55.000', 'rating': '5.0'},
      {'title': 'Coffee Splash', 'desc': 'Peppermint, Latte,\nand Macchiato', 'price': 'Rp 60.000', 'rating': '4.8'},
      {'title': 'Brunch Deals', 'desc': 'Red Velvet, Cappuccino,\nand Cake', 'price': 'Rp 80.000', 'rating': '4.9'},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          decoration: BoxDecoration(
            color: lightGreenCard,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, size: 10, color: primaryGreen),
                      const SizedBox(width: 2),
                      Text(product['rating']!, style: TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['title']!,
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['desc']!,
                    style: TextStyle(fontSize: 9, color: primaryGreen, height: 1.2),
                  ),
                  const Spacer(),
                  Text(
                    product['price']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 11),
                  ),
                ],
              ),
              // TODO: GANTI DENGAN GAMBAR PRODUK 
              Positioned(
                right: -10,
                bottom: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white54,
                  ),
                  child: const Center(child: Text('Img', style: TextStyle(fontSize: 10))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrandFeastBanner() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grand\nFeast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The Ultimate\nSharing Combo\nfor Everyone',
                  style: TextStyle(color: Colors.white, fontSize: 10, height: 1.2),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Text(
                      'Rp 120.000',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 10,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Rp 105.000',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // TODO: GANTI DENGAN GAMBAR GRAND FEAST KUE & KOPI
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: Container(
              width: 160,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/200x150/7B8C2A/FFFFFF?text=Feast+Image'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHalalFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: lightGreenCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            // TODO: GANTI DENGAN LOGO HALAL RESMI
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.mosque_outlined, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'HALAL\nINDONESIA',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1),
            ),
            const SizedBox(height: 4),
            const Text(
              'ID 3411000101108',
              style: TextStyle(color: Colors.white, fontSize: 10),
            )
          ],
        ),
      ),
    );
  }

  // --- BOTTOM NAVIGATION & FAB ---

  Widget _buildFAB() {
    return Container(
      height: 70,
      width: 70,
      margin: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEBE5D9), width: 4), // Border menyerupai figma
      ),
      child: FloatingActionButton(
        backgroundColor: primaryGreen,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        onPressed: () {
          // Aksi scan QR
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            SizedBox(height: 2),
            Text('SCAN QR', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: const Color(0xFFEBE5D9),
      elevation: 10,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0),
            _buildNavItem(Icons.local_cafe, 'Menu', 1),
            const SizedBox(width: 48), // Ruang kosong untuk FAB di tengah
            _buildNavItem(Icons.receipt_long, 'History', 2),
            _buildNavItem(Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _bottomNavIndex == index;
    final color = isActive ? primaryGreen : Colors.grey.shade500;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _bottomNavIndex = index; // Pindah tab state
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, 
                color: color, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ],
        ),
      ),
    );
  }
}