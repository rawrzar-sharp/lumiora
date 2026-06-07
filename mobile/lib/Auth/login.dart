import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Sesuaikan path ke file main.dart Anda
import '../app_config.dart'; // Menggunakan AppConfig.backendUrl Anda
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryGreen = const Color(0xFF7B8C2A);
  final Color textDark = const Color(0xFF2C3028);
  final Color darkGrey = const Color(0xFF4A4D4A);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Menghubungkan ke API Backend login
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _contactController.text.trim(), // Menggunakan 'email' sesuai spesifikasi backend
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // 🔥 FIX: Backend returns `{ success, message, data: { id, user_id, customer_id, name, ... } }`.
        // Older builds returned `{ user: {...} }` so fall back gracefully.
        final Map<String, dynamic> responseData =
            (responseBody['data'] as Map?)?.cast<String, dynamic>() ??
                (responseBody['user'] as Map?)?.cast<String, dynamic>() ??
                responseBody;

        // 🔥 FIX KUNCI EMAS: Simpan data secara persisten ke HP User
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('customer_id', responseData['id'].toString());
        await prefs.setString('user_data', jsonEncode(responseData));

        // 3. Set GlobalState agar langsung aktif di session berjalan saat ini
        // Prefer the explicit `customer_id` from backend when available; fall back to `id`.
        GlobalState.customerId = int.tryParse(
            (responseData['customer_id'] ?? responseData['id']).toString());
        GlobalState.userName = responseData['name'] as String?;
        
        // Pastikan parsing tipe data angkanya aman
        GlobalState.currentCardStamps = int.tryParse(responseData['loyalty_stamps']?.toString() ?? '0') ?? 0;
        GlobalState.vouchersCount = int.tryParse(responseData['vouchers']?.toString() ?? '0') ?? 0;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             // Pakai GlobalState.userName yang baru di-set, atau responseData['name']
             content: Text("Welcome back, ${GlobalState.userName ?? 'Member'}!"), 
             backgroundColor: primaryGreen
          ),
        );

        // Pindah halaman ke HomeScreen utama
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(errorData['message'] ?? "Login failed. Check your credentials.");
      }
    } catch (e) {
      _showErrorSnackBar("Connection error: Gagal terhubung ke server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5D9), // Mengikuti brand color cream Lumiora
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "LUMIORÀ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Access Your Rewards Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: darkGrey, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                
                // Input Email
                Text("Email Address", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Email cannot be empty" : null,
                ),
                const SizedBox(height: 16),

                // Input Password
                Text("Password", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Password cannot be empty" : null,
                ),
                const SizedBox(height: 32),

                // Tombol Login
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("ACCESS ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 20),

                // Link ke Register
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                  },
                  child: Text(
                    "New to Lumiora? Join Rewards Here",
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}