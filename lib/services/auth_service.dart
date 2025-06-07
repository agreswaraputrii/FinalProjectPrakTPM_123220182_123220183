import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart'; // Digunakan untuk hashing SHA-256
import 'dart:convert'; // Digunakan untuk utf8.encode
import 'package:uuid/uuid.dart'; // Digunakan untuk menghasilkan ID sesi unik

import '../models/user_model.dart';

class AuthService {
  final Box<UserModel> _userBox;
  final Uuid _uuid = Uuid(); // Inisialisasi generator UUID

  // Konstruktor untuk menerima Hive Box
  AuthService(this._userBox);

  // Fungsi utilitas untuk menghash password menggunakan SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Konversi string password ke bytes
    var digest = sha256.convert(bytes); // Lakukan hashing SHA-256
    return digest.toString(); // Kembalikan hash dalam bentuk string heksadesimal
  }

  // Fungsi untuk mendaftarkan pengguna baru
  Future<bool> registerUser({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phoneNumber,
    List<String> roles = const ['customer'], // Default peran adalah 'customer'
  }) async {
    // Cek apakah username sudah ada di Hive Box
    if (_userBox.values.any((user) => user.username == username)) {
      return false; // Registrasi gagal, username sudah digunakan
    }

    // Hash password sebelum menyimpannya
    final hashedPassword = _hashPassword(password);

    // Buat objek UserModel baru dengan password yang sudah di-hash
    final newUser = UserModel(
      username: username,
      hashedPassword: hashedPassword, // Simpan password yang sudah di-hash
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      roles: roles, // Gunakan peran yang diberikan
    );

    // Tambahkan user baru ke Hive Box
    await _userBox.add(newUser);
    return true; // Registrasi berhasil
  }

  // Fungsi untuk melakukan login pengguna
  Future<UserModel?> loginUser(String username, String password) async {
    // Hash password yang diinput pengguna untuk dibandingkan
    final inputHashedPassword = _hashPassword(password);

    try {
      // Cari pengguna berdasarkan username dan hashed password
      final user = _userBox.values.firstWhere(
        (u) => u.username == username && u.hashedPassword == inputHashedPassword,
      );

      // Jika login berhasil, buat ID sesi unik dan simpan ke objek user
      final sessionId = _uuid.v4(); // Buat UUID versi 4
      user.currentSessionId = sessionId;
      await user.save(); // Simpan perubahan pada user ke Hive

      return user; // Kembalikan objek user yang berhasil login
    } catch (e) {
      // Jika user tidak ditemukan atau password salah
      return null; // Login gagal
    }
  }

  // Fungsi untuk melakukan logout pengguna
  Future<void> logoutUser(UserModel user) async {
    user.currentSessionId = null; // Hapus ID sesi
    await user.save(); // Simpan perubahan pada user ke Hive
  }

  // Fungsi untuk mendapatkan pengguna yang sedang login (untuk auto-login)
  Future<UserModel?> getLoggedInUser() async {
    try {
      // Cari pengguna di Hive Box yang memiliki currentSessionId yang tidak null
      return _userBox.values.firstWhere((user) => user.currentSessionId != null);
    } catch (e) {
      // Jika tidak ada user dengan sesi aktif
      return null;
    }
  }
}