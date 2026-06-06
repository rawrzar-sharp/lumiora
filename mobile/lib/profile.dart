import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'main.dart'; 
import 'menu_page.dart';
import 'auth/login.dart';
import 'auth/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color scaffoldColor = const Color(0xFFEFECE3); 
  final Color textDark = const Color(0xFF2C3028);
  final Color goldCardColor = const Color(0xFFB59A57);
  final Color paleGreenCard = const Color(0xFFDFE2C7);

  int _bottomNavIndex = 3; 
  bool isLoggedIn = false;
  Map<String, dynamic>? userData;
  

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String get _apiBase => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Otomatis membaca data login saat profil dibuka
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final decodedData = jsonDecode(userDataString);
      final userObj = decodedData['user'] ?? decodedData; 

      if (mounted) {
        setState(() {
          isLoggedIn = true;
          userData = userObj;
          GlobalState.userName = userObj['name']; 
        });
      }
    }
  }

  Widget _buildAuthField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: goldCardColor),
        suffixIcon: isPassword 
            ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: onVisibilityToggle)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryGreen, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayName = GlobalState.userName ?? userData?['name'] ?? 'Guest';
    String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G';
   return Scaffold(
      backgroundColor: scaffoldColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. GANTI BAGIAN HEADER INI:
              GestureDetector(
                onTap: isLoggedIn
                    ? null // Jika sudah login, tidak melakukan apa-apa saat ditekan
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // Lingkaran Inisial Nama (Otomatis menyesuaikan huruf pertama user)
                      CircleAvatar(
                        radius: 26, // Menyesuaikan ukuran agar mirip dengan desain sebelumnya
                        backgroundColor: Colors.white,
                        child: Text(
                          isLoggedIn ? initial : "L", // L untuk Lumiora jika belum login
                          style: TextStyle(
                            color: goldCardColor, // Menggunakan warna emas profil
                            fontSize: 26, 
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Teks Nama User
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn ? "WELCOME BACK," : "JOIN LUMIORÀ",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLoggedIn ? displayName.toUpperCase() : "LOGIN / SIGN UP",
                              style: TextStyle(
                                color: textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tampilkan panah (>) hanya jika BELUM login
                      if (!isLoggedIn)
                        const Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Membership Card View
              isLoggedIn ? _buildMemberCard() : _buildGuestCard(),
              
              const SizedBox(height: 24),
              const Text("MY ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _buildAccountBox("Vouchers", GlobalState.vouchersCount.toString(), Icons.confirmation_num_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAccountBox("Gift a Coffee", "Invite & earn", Icons.card_giftcard)),
                ],
              ),
              const SizedBox(height: 24),

              // Stamps View
              _buildStampsSection(),
              const SizedBox(height: 12),
              const Text("Preferences & Appearance", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 8),
              _buildPreferenceList(),

              const SizedBox(height: 32),
              const Text("SETTINGS & PREFERENCES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 12),
              
              // Professional Settings List
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildSettingsTile(Icons.person_outline, "Personal Information", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPlaceholder(title: "Personal Information")));
                    }),
                    _buildSettingsTile(Icons.payment_outlined, "Payment Methods", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPlaceholder(title: "Payment Methods")));
                    }),
                    _buildSettingsTile(Icons.history, "Order History", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPlaceholder(title: "Order History")));
                    }),
                    _buildSettingsTile(Icons.notifications_outlined, "Notifications", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPlaceholder(title: "Notifications")));
                    }),
                    _buildSettingsTile(Icons.help_outline, "Support & FAQ", isLast: !isLoggedIn),
                    if (isLoggedIn)
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        onTap: () async {
                          // Clear persisted user
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('user_data');
                          } catch (e) {}

                          setState(() { 
                            isLoggedIn = false; 
                            GlobalState.userName = null; 
                            GlobalState.vouchersCount = 0; 
                            GlobalState.currentCardStamps = 0; 
                            userData = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR Scanner Opened"))),
        backgroundColor: primaryGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(), 
    );
  }

  Widget _buildMemberCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFB59A57), Color(0xFFD4AF37)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: goldCardColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 30),
                    const SizedBox(height: 8),
                    const Text("GOLD TIER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 2)),
                  ],
                ),
                Text('LUMIORÀ', style: TextStyle(fontSize: 20, fontFamily: 'serif', color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Member ID: **** ${userData?['id'] ?? '0000'}", style: const TextStyle(color: Colors.white, letterSpacing: 1)),
                const Text("View Digital Card", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGuestCard() {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: paleGreenCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryGreen.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.stars_rounded, color: primaryGreen, size: 40),
            const SizedBox(height: 12),
            const Text("Join Lumiora Rewards", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Earn points, get free drinks, and unlock exclusive pastry drops.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildStampsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: paleGreenCard, 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("LOYALTY STAMPS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text("${GlobalState.currentCardStamps}/10", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              )
            ],
          ),
          const SizedBox(height: 6),
          const Text("Earn a free signature drink every 10 stamps.", style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 24),
              GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 12, mainAxisSpacing: 16),
            itemCount: 10,
            itemBuilder: (context, index) {
              bool isStamped = index < GlobalState.currentCardStamps;
              return Container(
                decoration: BoxDecoration(
                  color: isStamped ? primaryGreen : Colors.white,
                  shape: BoxShape.circle,
                  border: isStamped ? null : Border.all(color: Colors.grey.shade400, width: 1.5)
                ),
                child: isStamped 
                    ? const Icon(Icons.local_cafe, color: Colors.white, size: 20) 
                    : Center(child: Text("${index + 1}", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold))),
              );
            },
          ),
        ],
      ),
    );
  }

  // Replace your existing _buildSettingsTile function with this:
  Widget _buildSettingsTile(IconData icon, String title, {bool isLast = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: primaryGreen),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, color: Colors.black26),
          onTap: onTap, // Added this!
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade200, indent: 56),
      ],
    );
  }

  // Add extra settings entries to improve UI/UX
  Widget _buildPreferenceList() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(Icons.palette, "Theme & Appearance", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPlaceholder(title: "Theme & Appearance")));
          }),
          _buildSettingsTile(Icons.language, "Language & Locale", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPlaceholder(title: "Language & Locale")));
          }),
          _buildSettingsTile(Icons.notifications, "Notification Preferences", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPlaceholder(title: "Notification Preferences")));
          }),
          _buildSettingsTile(Icons.security, "Privacy & Security", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPlaceholder(title: "Privacy & Security")));
          }, isLast: true),
        ],
      ),
    );
  }

  Widget _buildAccountBox(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: goldCardColor, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: goldCardColor, fontWeight: FontWeight.bold)),
        ],
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
              const SizedBox(width: 48), 
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
          if (index == _bottomNavIndex) return;
          if (index == 0) Navigator.popUntil(context, (route) => route.isFirst);
          else if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MenuPage()));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: isActive ? FontWeight.w800 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class SettingsPlaceholder extends StatelessWidget {
  final String title;
  const SettingsPlaceholder({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECE3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFECE3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Color(0xFFB59A57)),
            const SizedBox(height: 16),
            Text("$title Page", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("This feature is currently under development.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}