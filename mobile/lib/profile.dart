import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart'; 
import 'menu_page.dart';

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
  int loyaltyStamps = 0; 

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in globally
    if (GlobalState.userName != null) {
      isLoggedIn = true;
      loyaltyStamps = GlobalState.currentCardStamps;
    }
  }

  Future<void> _handleAuth(bool isSignUp) async {
    final name = nameController.text.trim();
    final contact = contactController.text.trim();
    final password = passwordController.text.trim();

    if (contact.isEmpty || password.isEmpty || (isSignUp && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Colors.redAccent)
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'contactInfo': contact, 'password': password}),
      );

      final result = jsonDecode(response.body);

      if (result['success']) {
        setState(() {
          isLoggedIn = true;
          userData = result['user'];
          loyaltyStamps = result['user']['loyalty_stamps'] ?? 0;
          
          // Sync with Global State across the app
          GlobalState.userName = result['user']['name'];
          GlobalState.vouchersCount = result['user']['vouchers'] ?? 0;
          GlobalState.currentCardStamps = loyaltyStamps;
        });
        Navigator.of(context).pop(); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: primaryGreen));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to connect to Lumiora servers.')));
    }
  }

  void _showLuxuryAuthDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        bool isSignUp = false;
        bool isPasswordVisible = false;
        bool wantsMarketing = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF8F1),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 32, left: 24, right: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    
                    // Luxury Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("LUMIORÀ", style: TextStyle(fontSize: 28, fontFamily: 'serif', color: goldCardColor, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tab Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(30)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isSignUp = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: !isSignUp ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(30), boxShadow: !isSignUp ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : []),
                                child: Center(child: Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, color: !isSignUp ? primaryGreen : Colors.grey))),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isSignUp = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: isSignUp ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(30), boxShadow: isSignUp ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : []),
                                child: Center(child: Text("Join Now", style: TextStyle(fontWeight: FontWeight.bold, color: isSignUp ? primaryGreen : Colors.grey))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs
                    if (isSignUp) ...[
                      _buildAuthField(controller: nameController, label: "Full Name", icon: Icons.person_outline),
                      const SizedBox(height: 16),
                    ],
                    _buildAuthField(controller: contactController, label: "Email or Phone Number", icon: Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildAuthField(
                      controller: passwordController, 
                      label: "Password", 
                      icon: Icons.lock_outline, 
                      isPassword: true, 
                      isVisible: isPasswordVisible,
                      onVisibilityToggle: () => setModalState(() => isPasswordVisible = !isPasswordVisible)
                    ),
                    
                    const SizedBox(height: 24),

                    // Marketing Checkbox
                    if (isSignUp)
                      Theme(
                        data: Theme.of(context).copyWith(unselectedWidgetColor: goldCardColor),
                        child: CheckboxListTile(
                          title: const Text("Keep me updated on exclusive offers and tasting events.", style: TextStyle(fontSize: 12, color: Colors.black87)),
                          value: wantsMarketing, 
                          activeColor: goldCardColor,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) => setModalState(() => wantsMarketing = val!),
                        ),
                      ),

                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => _handleAuth(isSignUp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen, 
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(isSignUp ? "BECOME A MEMBER" : "ACCESS ACCOUNT", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
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
    return Scaffold(
      backgroundColor: scaffoldColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              InkWell(
                onTap: isLoggedIn ? null : _showLuxuryAuthDialog,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: goldCardColor, width: 2)),
                        child: Center(child: Text(isLoggedIn ? GlobalState.userName?.substring(0,1).toUpperCase() ?? 'L' : 'L', style: const TextStyle(fontSize: 26, fontFamily: 'serif', color: Color(0xFFB59A57), fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? "WELCOME BACK," : "JOIN LUMIORÀ",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 11, letterSpacing: 1),
                          ),
                          Text(
                            isLoggedIn ? (GlobalState.userName?.toUpperCase() ?? 'GUEST') : "LOGIN / SIGN UP",
                            style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 18),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (!isLoggedIn) const Icon(Icons.chevron_right, color: Colors.black54),
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

              const SizedBox(height: 32),
              const Text("SETTINGS & PREFERENCES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 12),
              
              // Professional Settings List
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildSettingsTile(Icons.person_outline, "Personal Information"),
                    _buildSettingsTile(Icons.payment_outlined, "Payment Methods"),
                    _buildSettingsTile(Icons.history, "Order History"),
                    _buildSettingsTile(Icons.notifications_outlined, "Notifications"),
                    _buildSettingsTile(Icons.help_outline, "Support & FAQ", isLast: !isLoggedIn),
                    if (isLoggedIn)
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        onTap: () {
                          setState(() { 
                            isLoggedIn = false; 
                            GlobalState.userName = null; 
                            GlobalState.vouchersCount = 0; 
                            loyaltyStamps = 0; 
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
      onTap: _showLuxuryAuthDialog,
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
                child: Text("$loyaltyStamps/10", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
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
              bool isStamped = index < loyaltyStamps;
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

  Widget _buildSettingsTile(IconData icon, String title, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: primaryGreen),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, color: Colors.black26),
          onTap: () {},
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade200, indent: 56),
      ],
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