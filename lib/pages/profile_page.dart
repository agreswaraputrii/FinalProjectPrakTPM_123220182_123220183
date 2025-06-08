// lib/pages/profile_page.dart (User Profile)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../models/user_model.dart';
import '../models/product_model.dart'; // Import ProductModel
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../providers/product_provider.dart'; // Import ProductProvider
import '../pages/detail_page.dart'; // Import DetailPage for navigation (optional)

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
  late OrderService _orderService;
  int customerOrdersCount = 0;
  int sellerOrdersCount = 0;
  // No need for a local list here if we use Consumer directly for products.
  // We'll let the Consumer rebuild the product list section.

  final Color primaryColor = const Color(0xFF2E7D32); // Green
  final Color accentColor = const Color(0xFFFF6B35); // Orange accent
  final Color backgroundColor = const Color(0xFFF1F8E9);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initServicesAndLoadData();
  }

  Future<void> _initServicesAndLoadData() async {
    if (!Hive.isBoxOpen('orderBox')) {
      await Hive.openBox<OrderModel>('orderBox');
    }
    _orderService = OrderService(
      Hive.box<OrderModel>('orderBox'),
      Hive.box<UserModel>('userBox'),
    );

    _loadOrderCounts();
    // No need to call _loadMyUploadedProducts here, Consumer will handle it.
  }

  Future<void> _loadOrderCounts() async {
    final customerOrders = _orderService.getOrdersAsCustomer(
      widget.currentUser.username,
    );
    setState(() {
      customerOrdersCount = customerOrders.length;
    });

    if (widget.currentUser.roles.contains('seller')) {
      final sellerOrders = _orderService.getOrdersAsSeller(
        widget.currentUser.username,
      );
      setState(() {
        sellerOrdersCount = sellerOrders.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire Column with a Consumer to react to ProductProvider changes
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Filter products dynamically from the provider's allProducts
        final myUploadedProducts = productProvider.allProducts
            .where((p) => p.uploaderUsername == widget.currentUser.username)
            .toList();

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
                  // User Avatar (can be generic person icon)
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

                  // User Info Card
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
                          spreadRadius: 0,
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

                  // Order Summary Cards
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
                        customerOrdersCount,
                        primaryColor,
                        Icons.shopping_bag_outlined,
                      ),
                      if (widget.currentUser.roles.contains('seller'))
                        _buildOrderSummaryCard(
                          'Pesanan Masuk',
                          sellerOrdersCount,
                          accentColor,
                          Icons.store_mall_directory_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Fitur riwayat pesanan (customer) akan datang!",
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
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Fitur manajemen pesanan (seller) akan datang!",
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
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),

                  // NEW SECTION: My Uploaded Products (only for sellers)
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
                            shrinkWrap:
                                true, // Important for ListView inside SingleChildScrollView
                            physics:
                                const NeverScrollableScrollPhysics(), // Prevent inner scrolling
                            itemCount: myUploadedProducts.length,
                            itemBuilder: (context, index) {
                              final product = myUploadedProducts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 3,
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
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
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.grey[400],
                                  ),
                                  onTap: () {
                                    // Navigate to product detail page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPage(
                                          product: product,
                                          // You will need to pass these callbacks down from HomePage
                                          // or make DetailPage fetch them via Provider
                                          // For simplicity, if DetailPage needs onAddToCart/onAddToFavorite,
                                          // HomePage needs to pass them to ProfilePage, and ProfilePage to DetailPage
                                          // Or, DetailPage can use Provider.of<CartProvider>(context).addItem, etc.
                                          // The latter is generally preferred.
                                          onAddToCart: (p, q) {
                                            /* Placeholder if not passed */
                                          },
                                          onAddToFavorite: (p, isFav) {
                                            /* Placeholder if not passed */
                                          },
                                          currentUser: widget
                                              .currentUser, // Pass current user
                                          isSeller: widget.currentUser.roles
                                              .contains('seller'),
                                          isInitialFavorite:
                                              false, // You might need to check actual favorite status
                                        ),
                                      ),
                                    ).then((_) {
                                      // After returning from DetailPage (e.g., product deleted/edited)
                                      // The Consumer in ProfilePage will rebuild, refreshing the list
                                      // Or if you want a more explicit refresh, call setState or _loadMyUploadedProducts()
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
