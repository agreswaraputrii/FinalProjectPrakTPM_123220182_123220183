import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // Diperlukan untuk mengakses Hive Box
import '../pages/home_page.dart';
import '../pages/register_page.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart'; // Import AuthService yang baru dibuat

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  late AuthService _authService; // Deklarasi AuthService

  final Color primaryColor = const Color(0xFF4E342E); // Coklat tua
  final Color accentColor = const Color(0xFFFF7043); // Oranye aksen

  @override
  void initState() {
    super.initState();
    _initAuthServiceAndCheckLogin(); // Panggil fungsi inisialisasi dan cek login
  }

  // Fungsi untuk inisialisasi AuthService dan mengecek sesi aktif
  Future<void> _initAuthServiceAndCheckLogin() async {
    // Pastikan Hive Box sudah terbuka. Ini juga dipanggil di main.dart,
    // tapi aman untuk memastikan lagi di sini.
    if (!Hive.isBoxOpen('userBox')) {
      await Hive.openBox<UserModel>('userBox');
    }
    _authService = AuthService(Hive.box<UserModel>('userBox'));

    // Cek apakah ada sesi aktif (auto-login)
    final user = await _authService.getLoggedInUser();
    if (user != null) {
      // Jika ada sesi aktif, langsung navigasi ke home page tanpa melalui login form
      if (mounted) { // Pastikan widget masih mounted sebelum navigasi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(user: user),
          ),
        );
      }
    }
  }

  void showCustomSnackbar(String message, {bool success = true}) {
    final color = success ? Colors.green.shade600 : Colors.red.shade600;
    final icon = success ? Icons.check_circle : Icons.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void login() async {
    FocusScope.of(context).unfocus(); // Sembunyikan keyboard

    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      showCustomSnackbar("Username dan password wajib diisi", success: false);
      return;
    }

    // Panggil fungsi login dari AuthService
    final user = await _authService.loginUser(
      usernameController.text,
      passwordController.text,
    );

    if (user != null) {
      showCustomSnackbar("Login berhasil!", success: true);
      await Future.delayed(const Duration(milliseconds: 500)); // Tunda sebentar
      if (mounted) { // Pastikan widget masih mounted sebelum navigasi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(user: user),
          ),
        );
      }
    } else {
      showCustomSnackbar("Login gagal: username atau password salah", success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_grocery_store, size: 64, color: primaryColor),
              const SizedBox(height: 12),
              Text(
                "Groceries Store",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                shadowColor: Colors.brown.shade200,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        decoration: InputDecoration(
                          labelText: "Username",
                          labelStyle: const TextStyle(fontFamily: 'Poppins'),
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: accentColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => login(),
                        style: const TextStyle(fontFamily: 'Poppins'),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(fontFamily: 'Poppins'),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: accentColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: primaryColor,
                            elevation: 6,
                            shadowColor: accentColor.withOpacity(0.7),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          "Belum punya akun? Register di sini",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.brown.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}