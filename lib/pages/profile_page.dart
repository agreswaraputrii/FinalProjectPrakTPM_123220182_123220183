import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart'; // <-- IMPORT ORDER PROVIDER
import '../pages/detail_page.dart';
import '../models/product_model.dart';
import '../pages/manage_orders_page.dart';
import '../pages/my_orders_page.dart';

class ProfilePage extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Hapus semua state lokal yang berhubungan dengan data,
  // karena sekarang kita akan mengambilnya langsung dari Provider.
  // late OrderService _orderService;
  // int customerOrdersCount = 0;
  // int sellerOrdersCount = 0;

  final Color primaryColor = const Color(0xFF2E7D32);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);
  final Color cardColor = Colors.white;

  // Hapus semua method yang berhubungan dengan loading data manual
  // @override
  // void initState() {
  //   super.initState();
  //   _initServicesAndLoadData();
  // }
  // Future<void> _initServicesAndLoadData() async { ... }
  // Future<void> _loadOrderCounts() async { ... }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer2 untuk mendengarkan perubahan dari ProductProvider dan OrderProvider
    return Consumer2<ProductProvider, OrderProvider>(
      builder: (context, productProvider, orderProvider, child) {
        // Ambil data produk yang diunggah oleh user ini dari ProductProvider
        final myUploadedProducts = productProvider.allProducts
            .where((p) => p.uploaderUsername == widget.currentUser.username)
            .toList();

        // Ambil data jumlah pesanan secara REAL-TIME dari OrderProvider
        final customerOrdersCount = orderProvider
            .getOrdersForCustomer(widget.currentUser.username)
            .length;

        final sellerOrdersCount = orderProvider
            .getOrdersForSeller(widget.currentUser.username)
            .length;

        // Mulai bangun UI dengan data yang sudah reaktif
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                Colors.white,
                backgroundColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- User Avatar ---
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person_rounded,
                      size: 70,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- User Name & Username ---
                  Text(
                    widget.currentUser.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '@${widget.currentUser.username}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // --- User Info Card ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Informasi Akun:",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildProfileInfoRow(
                          icon: Icons.person_rounded,
                          label: "Username",
                          value: widget.currentUser.username,
                        ),
                        _buildProfileInfoRow(
                          icon: Icons.badge_rounded,
                          label: "Nama Lengkap",
                          value: widget.currentUser.fullName,
                        ),
                        _buildProfileInfoRow(
                          icon: Icons.email_rounded,
                          label: "Email",
                          value: widget.currentUser.email,
                        ),
                        _buildProfileInfoRow(
                          icon: Icons.phone_rounded,
                          label: "Nomor Telepon",
                          value: widget.currentUser.phoneNumber,
                        ),
                        _buildProfileInfoRow(
                          icon: Icons.category_rounded,
                          label: "Peran",
                          value: widget.currentUser.roles
                              .map((role) => role.toUpperCase())
                              .join(', '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- PERBAIKAN UTAMA DI SINI ---
                  // --- Order Summary Cards (Data dari Provider) ---
                  Text(
                    'Ringkasan Pesanan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildOrderSummaryCard(
                        'Pesanan Saya',
                        customerOrdersCount, // <-- Data reaktif
                        primaryColor,
                        Icons.shopping_bag_outlined,
                      ),
                      if (widget.currentUser.roles.contains('seller'))
                        _buildOrderSummaryCard(
                          'Pesanan Masuk',
                          sellerOrdersCount, // <-- Data reaktif
                          accentColor,
                          Icons.store_mall_directory_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyOrdersPage(
                              currentUser:
                                  widget.currentUser, // Kirim objek UserModel
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: Text(
                        'Lihat Riwayat Pesanan Saya',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (widget.currentUser.roles.contains('seller'))
                    const SizedBox(height: 10),
                  if (widget.currentUser.roles.contains('seller'))
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageOrdersPage(
                                sellerUsername: widget.currentUser.username,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment, color: Colors.white),
                        label: Text(
                          'Kelola Pesanan Masuk',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  // --- My Uploaded Products (Data dari Provider) ---
                  if (widget.currentUser.roles.contains('seller')) ...[
                    Text(
                      'Produk Saya',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    myUploadedProducts.isEmpty
                        ? Text(
                            'Anda belum mengupload produk apapun.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myUploadedProducts.length,
                            itemBuilder: (context, index) {
                              final product = myUploadedProducts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product.thumbnail,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) =>
                                          const Icon(Icons.image),
                                    ),
                                  ),
                                  title: Text(
                                    product.title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '\$${product.finalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      color: primaryColor,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPage(
                                          product: product,
                                          currentUser: widget.currentUser,
                                          isSeller: true,
                                          onAddToCart: (p, q) {},
                                          onAddToFavorite: (p, f) {},
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets (Tidak ada perubahan) ---
  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
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
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
