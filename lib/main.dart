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
        scaffoldBackgroundColor: const Color(0xFFF4F1E1), // Light beige background
        primaryColor: const Color(0xFF7B8C2A), // Olive green
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);

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
                  const SizedBox(height: 40), // Bottom padding
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

  // --- Widget Builders ---

  Widget _buildHeroAndHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            // Top Hero Image Placeholder
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE8DCC4),
                image: DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/600x400/E8DCC4/888888?text=Coffee+Hero+Image'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Green Header Bar
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
        // Overlapping Round Logo
        Positioned(
          right: 16,
          top: 180, // Adjust this to sit right on the seam
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen, width: 4),
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
                  Icon(Icons.coffee, color: primaryGreen, size: 24),
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
        borderRadius: BorderRadius.circular(8),
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
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryGreen, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.coffee, size: 40, color: primaryGreen),
                const SizedBox(height: 8),
                Text(
                  'Pick Up',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: darkGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delivery_dining, size: 40, color: Colors.white38),
                const SizedBox(height: 8),
                const Text(
                  'COMING SOON',
                  style: TextStyle(fontSize: 10, color: Colors.white),
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
          height: 90,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New Bonus Unlock',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'First time buyer bonus.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 120, color: Colors.white24), // Placeholder for image
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: lightGreenCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Brew Stamp Card',
                        style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Collect 9 stamps, Get 10th cup for free!',
                        style: TextStyle(color: primaryGreen.withOpacity(0.8), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 140, color: Colors.black12), // Placeholder for stamp card graphic
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Duo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Trio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = [
      {'title': 'Trio Cafe', 'desc': 'Triple the drinks.\nTriple the fun.', 'price': 'Rp 50.000'},
      {'title': 'Triple Brew', 'desc': 'Matcha, Choco, and\nCoffee', 'price': 'Rp 55.000'},
      {'title': 'Coffee Splash', 'desc': 'Peppermint, Latte, and\nCaramel Macchiato', 'price': 'Rp 60.000'},
      {'title': 'Brunch Deals', 'desc': 'Red Velvet, Cappuccino,\nand Cake', 'price': 'Rp 80.000'},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4, // Adjust for card proportions
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          decoration: BoxDecoration(
            color: lightGreenCard,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Placeholder for product image (left side)
              Container(width: 50, color: Colors.black12), 
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product['title']!,
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['desc']!,
                      style: TextStyle(fontSize: 8, color: primaryGreen.withOpacity(0.8)),
                    ),
                    const Spacer(),
                    Text(
                      product['price']!,
                      style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 10),
                    ),
                  ],
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
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grand\nFeast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The Ultimate\nSharing Combo\nfor Everyone',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Rp 120.000',
                      style: TextStyle(
                        color: Colors.white54,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Rp 105.000',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Placeholder for the large feast image on the right
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: lightGreenCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.mosque_outlined, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            const Text(
              'HALAL\nINDONESIA',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.1),
            ),
            const Text(
              'ID 3411000101108',
              style: TextStyle(color: Colors.white, fontSize: 10),
            )
          ],
        ),
      ),
    );
  }

  // --- Bottom Navigation & FAB ---

  Widget _buildFAB() {
    return Container(
      height: 70,
      width: 70,
      margin: const EdgeInsets.only(top: 30),
      child: FloatingActionButton(
        backgroundColor: primaryGreen,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        onPressed: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(height: 2),
            Text('SCAN QR', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFFEBE6D6), // Matches the bottom bar color in the image
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.coffee, 'Menu', false),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.receipt_long, 'History', false),
            _buildNavItem(Icons.person, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final color = isActive ? primaryGreen : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}