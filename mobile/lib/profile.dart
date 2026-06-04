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

    Widget _buildLuxuryAuthForm() {
    return Column(
      children: [
        TextField(
          controller: contactController,
          decoration: InputDecoration(
            labelText: "Phone / Member ID",
            prefixIcon: const Icon(Icons.phone, color: Color(0xFFB59A57)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),
        CheckboxListTile(
          title: const Text("Terms and Conditions: I confirm I have read and accept the Terms of Use and Privacy Policy."),
          value: _wantsMarketing, 
          onChanged: (val) {
            setState(() {
              _wantsMarketing = val!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB59A57),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          onPressed: _handleAuth,
          child: const Text("ACCESS LOUNGE", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  int _bottomNavIndex = 3; 
  bool isLoggedIn = false;
  Map<String, dynamic>? userData;
  int loyaltyStamps = 0; 
  bool _isPasswordVisible = false;
  bool _wantsMarketing = false;
  bool _acceptedTerms = false;

  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _handleAuth() async {
    final contact = contactController.text.trim();
    final password = passwordController.text.trim();

    if (contact.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both phone number and password'), backgroundColor: Colors.redAccent)
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.orange)
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contactInfo': contact, 'password': password}),
      );

      final result = jsonDecode(response.body);

      if (result['success']) {
        setState(() {
          isLoggedIn = true;
          userData = result['user'];
          loyaltyStamps = result['user']['loyalty_stamps'] ?? 0;
          // Sync with Global State
          GlobalState.vouchersCount = result['user']['vouchers'] ?? 0;
        });
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Successful!'), backgroundColor: Colors.green));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Login failed'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to connect to server')));
    }
  }

  void _showLoginDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFECE3),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 32, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("WELCOME", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  Container(width: 40, height: 2, color: primaryGreen, margin: const EdgeInsets.only(top: 4, bottom: 24)),
                  
                  // Phone Input
                  Row(
                    children: [
                      Container(
                        width: 60,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade400))),
                        child: const TextField(
                          decoration: InputDecoration(hintText: "+62", border: InputBorder.none),
                          style: TextStyle(fontWeight: FontWeight.bold),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade400))),
                          child: TextField(
                            controller: contactController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(hintText: "Phone Number...", border: InputBorder.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Password Input
                  Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade400))),
                    child: TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: "Password", 
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setModalState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, 
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("LOGIN / SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
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
              InkWell(
                onTap: isLoggedIn ? null : _showLoginDialog,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: goldCardColor, width: 2), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]),
                        child: const Center(child: Text('L', style: TextStyle(fontSize: 26, fontFamily: 'serif', color: Color(0xFFB59A57), fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isLoggedIn ? "HELLO, ${userData?['name']?.toString().toUpperCase() ?? 'GUEST'}" : "LOGIN / SIGN UP",
                        style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 16),
                      ),
                      const Spacer(),
                      if (!isLoggedIn) const Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Customer Gold Card - Interactive
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: goldCardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: goldCardColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if(!isLoggedIn) _showLoginDialog();
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("CUSTOMER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 2)),
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                                child: const Center(child: Text('L', style: TextStyle(fontSize: 28, fontFamily: 'serif', color: Colors.white))),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                          ),
                          child: const Text("View My Benefits  >", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // My Account Section
              const Text("MY ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildAccountBox("Vouchers", GlobalState.vouchersCount.toString(), Icons.confirmation_num_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAccountBox("Gift a Coffee", "Invite & earn", Icons.card_giftcard)),
                ],
              ),
              const SizedBox(height: 24),

              // Loyalty Stamps Full Layout (5 Top, 5 Bottom)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: paleGreenCard, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("LOYALTY STAMPS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Text("$loyaltyStamps/10", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text("Get a voucher after 10 stamps.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 24),
                    
                    // The 5x2 Grid Requirement
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // Exactly 5 stamps per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        bool isStamped = index < loyaltyStamps;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isStamped ? primaryGreen : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isStamped ? [BoxShadow(color: primaryGreen.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))] : null,
                            border: isStamped ? null : Border.all(color: Colors.grey.shade400, width: 1.5)
                          ),
                          child: isStamped 
                              ? const Icon(Icons.star_rounded, color: Colors.white, size: 24) 
                              : Center(child: Text("${index + 1}", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold))),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive FAQ Section
              const Text("FAQ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 12),
              _buildInteractiveFaq("How do I earn points?", "You can earn points by ordering through the app or scanning your QR code in-store at the register. 1 Stamp is awarded per transaction."),
              _buildInteractiveFaq("What are your opening hours?", "We're open every day from 8:00 AM to 10:00 PM. Hours may change during public holidays."),
              _buildInteractiveFaq("Can I use multiple vouchers?", "Usually, only one voucher can be applied per transaction unless specifically stated otherwise on the voucher terms."),
              _buildInteractiveFaq("How do I reset my password?", "Currently, please ask the barista in-store to reset your password if you forget it."),
              
              if (isLoggedIn) ...[
                const SizedBox(height: 30),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() { isLoggedIn = false; userData = null; loyaltyStamps = 0; GlobalState.vouchersCount = 0; }),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ]
            ],
          ),
        ),
      ),
      
      // Floating QR Button exactly like menu_page
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR Scanner Opened")));
        },
        backgroundColor: primaryGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: _buildBottomNav(), 
    );
  }

  Widget _buildAccountBox(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInteractiveFaq(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Removes borders
        child: ExpansionTile(
          iconColor: primaryGreen,
          collapsedIconColor: Colors.black54,
          title: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Text(answer, style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black54)),
            )
          ],
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
              const SizedBox(width: 48), // Leaves space for the QR Button
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
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MenuPage()));
          }
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