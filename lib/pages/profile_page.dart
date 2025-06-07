import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/order_model.dart'; // Import OrderModel
import '../services/order_service.dart'; // Import OrderService

class ProfilePage extends StatefulWidget {
  final UserModel currentUser; // Menerima objek user yang sedang login

  const ProfilePage({super.key, required this.currentUser});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late OrderService _orderService;
  int customerOrdersCount = 0;
  int sellerOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _initServicesAndLoadData();
  }

  Future<void> _initServicesAndLoadData() async {
    // Pastikan Hive Box sudah terbuka
    if (!Hive.isBoxOpen('orderBox')) {
      await Hive.openBox<OrderModel>('orderBox');
    }
    // Asumsi userBox sudah terbuka di main.dart
    _orderService = OrderService(Hive.box<OrderModel>('orderBox'), Hive.box<UserModel>('userBox'));

    _loadOrderCounts();
  }

  Future<void> _loadOrderCounts() async {
    // Mendapatkan jumlah pesanan sebagai customer
    final customerOrders = _orderService.getOrdersAsCustomer(widget.currentUser.username);
    setState(() {
      customerOrdersCount = customerOrders.length;
    });

    // Mendapatkan jumlah pesanan sebagai seller (jika user adalah seller)
    if (widget.currentUser.roles.contains('seller')) {
      final sellerOrders = _orderService.getOrdersAsSeller(widget.currentUser.username);
      setState(() {
        sellerOrdersCount = sellerOrders.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF4E342E); // Warna primary Anda

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Pengguna', style: GoogleFonts.poppins()),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.brown,
              child: Icon(Icons.person, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              widget.currentUser.fullName,
              style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: themeColor),
            ),
            Text(
              '@${widget.currentUser.username}',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileInfoRow(Icons.email, 'Email', widget.currentUser.email),
                    const Divider(height: 20),
                    _buildProfileInfoRow(Icons.phone, 'Nomor Telepon', widget.currentUser.phoneNumber),
                    const Divider(height: 20),
                    _buildProfileInfoRow(Icons.badge, 'Peran', widget.currentUser.roles.map((role) => role.toUpperCase()).join(', ')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Ringkasan Pesanan',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderSummaryCard(
                  'Pesanan Saya',
                  customerOrdersCount,
                  Colors.blueAccent,
                  Icons.shopping_bag_outlined,
                ),
                if (widget.currentUser.roles.contains('seller')) // Hanya tampilkan jika user adalah seller
                  _buildOrderSummaryCard(
                    'Pesanan Masuk',
                    sellerOrdersCount,
                    Colors.orange,
                    Icons.store_mall_directory_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 30),
            // Anda bisa tambahkan tombol untuk mengelola pesanan lebih lanjut di sini
            ElevatedButton.icon(
              onPressed: () {
                // Contoh navigasi ke halaman daftar pesanan customer
                // Anda perlu membuat halaman OrderHistoryPage jika ingin ini berfungsi
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fitur riwayat pesanan (customer) akan datang!")),
                );
              },
              icon: const Icon(Icons.history),
              label: Text('Lihat Riwayat Pesanan Saya', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (widget.currentUser.roles.contains('seller'))
              const SizedBox(height: 10),
            if (widget.currentUser.roles.contains('seller'))
              ElevatedButton.icon(
                onPressed: () {
                  // Contoh navigasi ke halaman manajemen pesanan seller
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fitur manajemen pesanan (seller) akan datang!")),
                  );
                },
                icon: const Icon(Icons.assignment),
                label: Text('Kelola Pesanan Masuk', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[700], size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 5),
              Text(
                '$count',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}