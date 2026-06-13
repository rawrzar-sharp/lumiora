import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'main.dart'; 
import 'menu_page.dart';
import 'auth/login.dart';
import 'auth/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';
import 'history.dart'; // <--- Tambahan untuk Rute Order History

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

  String get _apiBase => AppConfig.backendUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); 
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final decodedData = jsonDecode(userDataString);
      final Map<String, dynamic> userObj =
          (decodedData is Map && decodedData['data'] is Map)
              ? Map<String, dynamic>.from(decodedData['data'])
              : (decodedData is Map && decodedData['user'] is Map)
                  ? Map<String, dynamic>.from(decodedData['user'])
                  : Map<String, dynamic>.from(decodedData);

      if (mounted) {
        setState(() {
          isLoggedIn = true;
          userData = userObj;
          GlobalState.userName = userObj['name'] as String?;
          GlobalState.customerId = int.tryParse(
              (userObj['customer_id'] ?? userObj['id'] ?? '').toString());
          GlobalState.vouchersCount = int.tryParse(
                  (userObj['vouchers'] ?? '0').toString()) ??
              GlobalState.vouchersCount;
          GlobalState.currentCardStamps = int.tryParse(
                  (userObj['loyalty_stamps'] ?? '0').toString()) ??
              GlobalState.currentCardStamps;
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
        fillColor: Theme.of(context).cardColor,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              GestureDetector(
                onTap: isLoggedIn
                    ? null 
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
                      CircleAvatar(
                        radius: 26, 
                        backgroundColor: Theme.of(context).cardColor,
                        child: Text(
                          isLoggedIn ? initial : "L", 
                          style: TextStyle(
                            color: goldCardColor, 
                            fontSize: 26, 
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? textDark, 
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLoggedIn)
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              isLoggedIn ? _buildMemberCard() : _buildGuestCard(),
              
              const SizedBox(height: 24),
              Text("MY ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Theme.of(context).textTheme.bodyLarge?.color ?? textDark)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _buildAccountBox("Vouchers", GlobalState.vouchersCount.toString(), Icons.confirmation_num_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAccountBox("Gift a Coffee", "Invite & earn", Icons.card_giftcard)),
                ],
              ),
              const SizedBox(height: 24),

              _buildStampsSection(),
              const SizedBox(height: 12),
              Text("Preferences & Appearance", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Theme.of(context).textTheme.bodyLarge?.color ?? textDark)),
              const SizedBox(height: 8),
              
              _buildPreferenceList(),

              const SizedBox(height: 32),
              Text("SETTINGS & PREFERENCES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Theme.of(context).textTheme.bodyLarge?.color ?? textDark)),
              const SizedBox(height: 12),
              
              // Professional Settings List
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), 
                child: Column(
                  children: [
                    _buildSettingsTile(Icons.person_outline, "Personal Information", onTap: () {
                      if (!isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
                        return;
                      }
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => EditProfilePage(userData: userData))
                      ).then((_) => _loadUserProfile());
                    }),
                    
                    // --- UPDATE: RUTE BARU KE HALAMAN NYATA ---
                    _buildSettingsTile(Icons.payment_outlined, "Payment Methods", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsPage()));
                    }),
                    _buildSettingsTile(Icons.history, "Order History", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
                    }),
                    _buildSettingsTile(Icons.notifications_outlined, "Notifications", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPreferencesPage()));
                    }),
                    _buildSettingsTile(Icons.help_outline, "Support & FAQ", isLast: !isLoggedIn, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportFaqPage()));
                    }),
                    // ------------------------------------------

                    if (isLoggedIn)
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        onTap: () async {
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
            const Text("Join Lumiora Rewards", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("Earn points, get free drinks, and unlock exclusive pastry drops.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildStampsSection() {
    final stamps = GlobalState.currentCardStamps;
    final progress = (stamps / 10).clamp(0.0, 1.0);
    final remaining = 10 - stamps;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primaryGreen.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, const Color(0xFF5E6D1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("LOYALTY CARD", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      Text("Lumiora Rewards", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Stamps collected", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            "$stamps / 10",
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            remaining > 0
                                ? "$remaining more for a free signature drink"
                                : "Free drink unlocked — claim it on your next order!",
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.local_cafe, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFFBF8F1),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final bool isStamped = index < stamps;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    decoration: BoxDecoration(
                      color: isStamped ? primaryGreen : Colors.white,
                      shape: BoxShape.circle,
                      border: isStamped
                          ? null
                          : Border.all(color: Colors.grey.shade300, width: 1.5),
                      boxShadow: isStamped
                          ? [BoxShadow(color: primaryGreen.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: isStamped
                        ? const Icon(Icons.local_cafe, color: Colors.white, size: 20)
                        : Center(
                            child: Text("${index + 1}",
                                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {bool isLast = false, VoidCallback? onTap, Widget? trailing}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: primaryGreen),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade200, indent: 56),
      ],
    );
  }

  Widget _buildPreferenceList() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: GlobalState.themeNotifier,
            builder: (context, currentMode, child) {
              final isDark = currentMode == ThemeMode.dark;
              return _buildSettingsTile(
                isDark ? Icons.dark_mode : Icons.light_mode, 
                "Dark Mode", 
                trailing: Switch(
                  value: isDark,
                  activeColor: primaryGreen,
                  onChanged: (val) async {
                    GlobalState.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_dark_mode', val);
                  },
                ),
                onTap: null, 
              );
            },
          ),
          
          // --- UPDATE: RUTE BARU KE HALAMAN NYATA ---
          _buildSettingsTile(Icons.language, "Language & Locale", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageLocalePage()));
          }),
          _buildSettingsTile(Icons.notifications, "Notification Preferences", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesPage()));
          }),
          _buildSettingsTile(Icons.security, "Privacy & Security", onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityPage()));
          }, isLast: true),
          // ------------------------------------------
        ],
      ),
    );
  }

  Widget _buildAccountBox(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
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
          else if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
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

// =========================================================================
// BAGIAN FASE 3 OPSI A: HALAMAN UI & FORM BARU
// =========================================================================

// 1. Edit Profile Page (Dengan DatePicker)
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfilePage({Key? key, this.userData}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  DateTime? _selectedBirthday;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['phone'] ?? '');
    
    String? bdayRaw = widget.userData?['birthday'];
    if (bdayRaw != null && bdayRaw.isNotEmpty) {
      try {
        _selectedBirthday = DateTime.parse(bdayRaw.substring(0, 10));
      } catch (e) {
        _selectedBirthday = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (GlobalState.customerId == null) return;
    
    setState(() => _isLoading = true);

    try {
      final String formattedDate = _selectedBirthday != null 
          ? "${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}"
          : "";

      final response = await http.put(
        Uri.parse('${AppConfig.backendUrl}/api/customers/${GlobalState.customerId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'birthday': formattedDate,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        Map<String, dynamic> updatedData = Map.from(widget.userData ?? {});
        updatedData['name'] = _nameController.text;
        updatedData['phone'] = _phoneController.text;
        updatedData['birthday'] = formattedDate;
        
        await prefs.setString('user_data', jsonEncode({'data': updatedData}));
        GlobalState.userName = _nameController.text;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF7B8C2A)));
          Navigator.pop(context); 
        }
      } else {
        throw Exception("Failed to update");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(radius: 50, backgroundColor: primaryGreen.withOpacity(0.2), child: Icon(Icons.person, size: 60, color: primaryGreen)),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.camera_alt, size: 20, color: primaryGreen)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text("Full Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true, fillColor: Theme.of(context).cardColor,
                prefixIcon: Icon(Icons.person_outline, color: primaryGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Phone Number", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true, fillColor: Theme.of(context).cardColor,
                prefixIcon: Icon(Icons.phone_outlined, color: primaryGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Birthday", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickBirthday(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined, color: primaryGreen),
                    const SizedBox(width: 12),
                    Text(
                      _selectedBirthday != null ? "${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}" : "Select your birthday",
                      style: TextStyle(fontSize: 16, color: _selectedBirthday != null ? (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black) : Colors.grey),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_month, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Language & Locale Page
class LanguageLocalePage extends StatefulWidget {
  const LanguageLocalePage({Key? key}) : super(key: key);
  @override
  State<LanguageLocalePage> createState() => _LanguageLocalePageState();
}
class _LanguageLocalePageState extends State<LanguageLocalePage> {
  String _selectedLang = 'English';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Language & Locale", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Select Application Language", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                RadioListTile(
                  title: const Text("English", style: TextStyle(fontWeight: FontWeight.bold)),
                  value: 'English', groupValue: _selectedLang,
                  activeColor: const Color(0xFF7B8C2A),
                  onChanged: (val) => setState(() => _selectedLang = val.toString()),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                RadioListTile(
                  title: const Text("Bahasa Indonesia", style: TextStyle(fontWeight: FontWeight.bold)),
                  value: 'Indonesian', groupValue: _selectedLang,
                  activeColor: const Color(0xFF7B8C2A),
                  onChanged: (val) => setState(() => _selectedLang = val.toString()),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// 3. Notification Preferences Page
class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({Key? key}) : super(key: key);
  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}
class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  bool _orderUpdates = true;
  bool _promos = true;
  bool _appAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Order Updates", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Get alerts when your coffee is ready.", style: TextStyle(fontSize: 12)),
                  value: _orderUpdates, activeColor: const Color(0xFF7B8C2A),
                  onChanged: (val) => setState(() => _orderUpdates = val),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                SwitchListTile(
                  title: const Text("Promos & Rewards", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Discounts and free voucher alerts.", style: TextStyle(fontSize: 12)),
                  value: _promos, activeColor: const Color(0xFF7B8C2A),
                  onChanged: (val) => setState(() => _promos = val),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                SwitchListTile(
                  title: const Text("App Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("System maintenance information.", style: TextStyle(fontSize: 12)),
                  value: _appAlerts, activeColor: const Color(0xFF7B8C2A),
                  onChanged: (val) => setState(() => _appAlerts = val),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// 4. Privacy & Security Page
class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({Key? key}) : super(key: key);
  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}
class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _biometric = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Privacy & Security", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // Dummy action
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text("Biometric Login", style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _biometric, activeColor: const Color(0xFF7B8C2A),
                  onChanged: (val) => setState(() => _biometric = val),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text("Terms & Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, 
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, elevation: 0, padding: const EdgeInsets.all(16)),
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text("Request Account Deletion", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}

// 5. Payment Methods Page
class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Payment Methods", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7B8C2A))),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: const Color(0xFF7B8C2A), size: 30),
                const SizedBox(width: 16),
                const Expanded(child: Text("Lumiora Pay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                const Text("Rp 150.000", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7B8C2A))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Saved Methods", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.credit_card, color: Colors.blueAccent),
                  title: const Text("Credit Card", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("**** **** **** 1234"),
                  trailing: const Icon(Icons.more_vert),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: const Icon(Icons.phone_android, color: Colors.green),
                  title: const Text("GoPay", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("0812-****-5678"),
                  trailing: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), side: const BorderSide(color: Colors.grey)),
            icon: const Icon(Icons.add, color: Colors.grey),
            label: const Text("Add New Payment Method", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}

// 6. Support & FAQ Page
class SupportFaqPage extends StatelessWidget {
  const SupportFaqPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Support & FAQ", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B8C2A), padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.support_agent, color: Colors.white),
            label: const Text("Chat with Live Support (WhatsApp)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {},
          ),
          const SizedBox(height: 30),
          const Text("Frequently Asked Questions", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const ExpansionTile(
                  title: Text("How do I claim my free voucher?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  children: [Padding(padding: EdgeInsets.all(16.0), child: Text("You will automatically get 1 voucher for every 10 stamps you collect. You can apply it at checkout!"))],
                ),
                const ExpansionTile(
                  title: Text("Where is Lumiora located?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  children: [Padding(padding: EdgeInsets.all(16.0), child: Text("Our main outlet is located in Bekasi, West Java. Come say hi!"))],
                ),
                const ExpansionTile(
                  title: Text("Can I cancel an ongoing order?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  children: [Padding(padding: EdgeInsets.all(16.0), child: Text("Orders that have entered 'In Kitchen' status cannot be cancelled. Please contact staff immediately if you made a mistake."))]
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}