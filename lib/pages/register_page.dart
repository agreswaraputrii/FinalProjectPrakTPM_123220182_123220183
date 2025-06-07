import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // Diperlukan untuk mengakses Hive Box
import '../models/user_model.dart';
import '../services/auth_service.dart'; // Import AuthService

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false;
  late AuthService _authService; // Deklarasi AuthService
  bool _isRegisteringAsSeller = false; // State untuk checkbox "Daftar sebagai Penjual"

  @override
  void initState() {
    super.initState();
    _initAuthService();
  }

  // Fungsi untuk inisialisasi AuthService
  Future<void> _initAuthService() async {
    // Pastikan Hive Box sudah terbuka
    if (!Hive.isBoxOpen('userBox')) {
      await Hive.openBox<UserModel>('userBox');
    }
    _authService = AuthService(Hive.box<UserModel>('userBox'));
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void register() async {
    FocusScope.of(context).unfocus();

    final username = usernameController.text.trim();
    final password = passwordController.text;
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    // Validasi input
    if (username.isEmpty ||
        password.isEmpty ||
        fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Semua kolom harus diisi",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Password harus minimal 6 karakter",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    // Tentukan peran pengguna berdasarkan checkbox
    List<String> userRoles = ['customer']; // Setiap user pasti customer
    if (_isRegisteringAsSeller) {
      userRoles.add('seller'); // Tambahkan peran 'seller' jika checkbox dicentang
    }

    // Panggil fungsi registerUser dari AuthService
    final success = await _authService.registerUser(
      username: username,
      password: password, // Password akan di-hash di dalam AuthService
      fullName: fullName,
      email: email,
      phoneNumber: phone,
      roles: userRoles, // Kirim daftar peran yang dipilih
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Registrasi berhasil",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      if (mounted) { // Pastikan widget masih mounted sebelum navigasi
        Navigator.pop(context); // Kembali ke halaman login
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Username sudah digunakan",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade600,
        title: const Text(
          "Register",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16), // Tambahkan jarak sebelum checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isRegisteringAsSeller,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _isRegisteringAsSeller = newValue ?? false;
                        });
                      },
                    ),
                    const Text(
                      "Daftar juga sebagai Penjual",
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.brown.shade600,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Register",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}