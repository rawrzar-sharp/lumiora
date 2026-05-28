import 'package:flutter/material.dart';
import 'takeout.dart'; // <-- ADDED: Importing the takeout page

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
        scaffoldBackgroundColor: const Color(0xFFEBE5D9),
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color lightGreenCard = const Color(0xFFDCE2B9);
  final Color darkGrey = const Color(0xFF4A4D4A);
  final Color textDark = const Color(0xFF2C3028);

  int _bottomNavIndex = 0;
  bool _isTrioActive = true;

  // Data for Trio Menu
  final List<Map<String, String>> trioProducts = [
    {'title': 'Trio Cafe', 'desc': 'Triple the drinks.\nTriple the fun.', 'price': 'Rp 50.000', 'rating': '5.0', 'img': 'assets/images/prod_trio_cafe.png'},
    {'title': 'Triple Brew', 'desc': 'Matcha, Choco, and\nCoffee', 'price': 'Rp 65.000', 'rating': '5.0', 'img': 'assets/images/prod_triple_brew.png'},
    {'title': 'Coffee Splash', 'desc': 'Cappuccino, Latte, and\nCaramel Macchiato', 'price': 'Rp 55.000', 'rating': '4.5', 'img': 'assets/images/prod_coffee_splash.png'},
    {'title': 'Brunch Deals', 'desc': 'Vanilla latte, Cappuccino,\nand Sando', 'price': 'Rp 45.000', 'rating': '5.0', 'img': 'assets/images/prod_brunch_deals.png'},
  ];

  // Data for Duo Menu
  final List<Map<String, String>> duoProducts = [
    {'title': 'Duo Boost', 'desc': 'Double Espresso & \nAmericano', 'price': 'Rp 35.000', 'rating': '4.8', 'img': 'assets/images/prod_coffee_splash.png'},
    {'title': 'Sweet Pair', 'desc': 'Mocha & Caramel \nMacchiato', 'price': 'Rp 40.000', 'rating': '4.9', 'img': 'assets/images/prod_triple_brew.png'},
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
                      const SizedBox(height: 30),
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

  Widget _buildHeroAndHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF8F1),
                image: DecorationImage(
                  image: AssetImage('assets/images/hero_coffee_splash.png'),
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
                    'Hello, Rafdah!',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatBadge(Icons.workspace_premium, '123', 'Stamps'),
                      const SizedBox(width: 12),
                      _buildStatBadge(Icons.confirmation_num, '1', 'Vouchers'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          top: 190,
          child: HoverBounceWrapper(
            onTap: () {},
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1E1),
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen, width: 4),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.spa, color: primaryGreen, size: 28),
                    const SizedBox(height: 2),
                    Text('LUMIORA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: textDark, letterSpacing: 1.2)),
                  ],
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
              // <-- ADDED: Temporary connection to Takeout Page
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: GridView.builder(
        key: ValueKey<bool>(_isTrioActive), 
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return HoverBounceWrapper(
            onTap: () {
              // Note: You can paste the Navigator.push code here too if you want the items to open the page!
            },
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
                      Text(product['desc']!, style: TextStyle(fontSize: 9, color: primaryGreen, height: 1.2)),
                      const Spacer(),
                      Text(product['price']!, style: TextStyle(fontWeight: FontWeight.w500, color: textDark, fontSize: 12)),
                    ],
                  ),
                  Positioned(
                    right: -15, bottom: -15,
                    child: SizedBox(
                      width: 85, height: 85,
                      child: Image.asset(product['img']!, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 40, color: Colors.white54)),
                    ),
                  ),
                  Positioned(
                    right: -5, top: -5,
                    child: Icon(Icons.eco, size: 30, color: primaryGreen.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrandFeastBanner() {
    return HoverBounceWrapper(
      onTap: () {},
      child: Container(
        height: 160, width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8DCC4),
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(image: AssetImage('assets/images/banner_grand_feast.png'), fit: BoxFit.cover),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHalalFooter() {
    return HoverBounceWrapper(
      onTap: () {},
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(color: lightGreenCard, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/images/logo_halal_indonesia.png'), fit: BoxFit.contain),
                ),
              ),
              const Text('HALAL\nINDONESIA', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, height: 1.1)),
              const SizedBox(height: 4),
              const Text('ID241103130106', style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.0))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      height: 85, width: 85,
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEBE5D9)),
      child: Center(
        child: HoverBounceWrapper(
          onTap: () {},
          child: Container(
            width: 65, height: 65,
            decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                SizedBox(height: 2),
                Text('SCAN QR', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
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
            _buildNavItem(Icons.home_filled, 'Home', 0),
            _buildNavItem(Icons.local_cafe, 'Menu', 1),
            const SizedBox(width: 60), 
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
      child: HoverBounceWrapper(
        onTap: () => setState(() => _bottomNavIndex = index),
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

// --- NEW ANIMATION UTILITY ---

/// Adds a subtle hover scale up, and a satisfying tap scale down.
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

class DottedBackgroundPainter extends CustomPainter {
  final Color color;
  DottedBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (double i = 0; i < size.width; i += 20.0) {
      for (double j = 0; j < size.height; j += 20.0) {
        canvas.drawCircle(Offset(i, j), 2.5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}