import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

import '../pages/login_page.dart';
import '../pages/detail_page.dart';
import '../pages/favorite_page.dart';
import '../pages/cart_page.dart';
import '../pages/profile_page.dart';
import '../pages/notification_page.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ProductModel> products = [];
  List<ProductModel> favoriteProducts = [];
  List<CartItem> cartItems = [];

  late AuthService _authService;
  late NotificationService _notificationService;
  bool _servicesInitialized = false;
  Box<NotificationModel>? _notificationBox;

  // Simple state variable for notification count
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _initServices();
    fetchProducts();
  }

  Future<void> _initServices() async {
    try {
      // Pastikan box sudah terbuka (biasanya di main.dart)
      if (!Hive.isBoxOpen('userBox')) {
        await Hive.openBox<UserModel>('userBox');
      }
      if (!Hive.isBoxOpen('notificationBox')) {
        await Hive.openBox<NotificationModel>('notificationBox');
      }

      // Simpan reference ke notification box
      _notificationBox = Hive.box<NotificationModel>('notificationBox');

      _authService = AuthService(Hive.box<UserModel>('userBox'));
      _notificationService = NotificationService(_notificationBox!);

      // Update the notification count initially
      _updateNotificationCount();

      setState(() {
        _servicesInitialized = true;
      });
    } catch (e) {
      print(
        'Error initializing services or opening Hive boxes in HomePage: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load app data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function untuk mendapatkan unread count
  int _getUnreadCountForUser(String username) {
    try {
      if (!_servicesInitialized ||
          _notificationBox == null ||
          !_notificationBox!.isOpen) {
        return 0;
      }
      return _notificationService.getUnreadNotificationCount(username);
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Function to update notification count
  void _updateNotificationCount() {
    if (_servicesInitialized) {
      final count = _getUnreadCountForUser(widget.user.username);
      setState(() {
        _notificationCount = count;
      });
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse('https://dummyjson.com/products/category/groceries');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> productList = data['products'];

      setState(() {
        products = productList
            .map((json) => ProductModel.fromJsonSafe(json))
            .toList();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Failed to load products: ${response.statusCode}');
    }
  }

  void _logout() async {
    if (_servicesInitialized) {
      await _authService.logoutUser(widget.user);
    }
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _toggleFavorite(ProductModel product) {
    setState(() {
      if (favoriteProducts.contains(product)) {
        favoriteProducts.remove(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.title} dihapus dari favorit')),
        );
      } else {
        favoriteProducts.add(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.title} ditambahkan ke favorit')),
        );
      }
    });
  }

  void _addToFavorites(ProductModel product, bool isFavorite) {
    setState(() {
      if (isFavorite) {
        if (!favoriteProducts.contains(product)) {
          favoriteProducts.add(product);
        }
      } else {
        favoriteProducts.remove(product);
      }
    });
  }

  void _addToCart(ProductModel product, int quantity) {
    setState(() {
      final index = cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (index != -1) {
        cartItems[index].quantity += quantity;
      } else {
        cartItems.add(CartItem(product: product, quantity: quantity));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.title} ($quantity) ditambahkan ke keranjang',
          ),
        ),
      );
    });
  }

  void _removeFromCart(CartItem cartItem) {
    setState(() {
      cartItems.removeWhere((item) => item.product.id == cartItem.product.id);
    });
  }

  void _changeQuantity(CartItem cartItem, int quantity) {
    setState(() {
      final index = cartItems.indexWhere(
        (item) => item.product.id == cartItem.product.id,
      );
      if (index != -1) {
        cartItems[index].quantity = quantity;
      }
    });
  }

  Future<void> _showQuantityDialogWithAdd(ProductModel product) async {
    final controller = TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tambah ke Keranjang"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Jumlah"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 1;
              _addToCart(product, quantity);
              Navigator.pop(context);
            },
            child: const Text("Tambahkan"),
          ),
        ],
      ),
    );
  }

  double priceAfterDiscount(ProductModel product) {
    return product.price * (1 - product.discountPercentage / 100);
  }

  final Color primaryColor = const Color(0xFF4E342E);
  final Color accentColor = const Color(0xFFFF7043);
  final Color priceColor = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Home",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        actions: [
          // Tombol Notifikasi yang disederhanakan
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                color: Colors.white,
                tooltip: "Notifikasi",
                onPressed: () async {
                  if (_servicesInitialized) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NotificationPage(currentUser: widget.user),
                      ),
                    );
                    // Update notification count after returning from notification page
                    _updateNotificationCount();
                  }
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Tombol Favorite
          IconButton(
            icon: const Icon(Icons.favorite),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FavoritePage(favoriteProducts: favoriteProducts),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          // Tombol Cart
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(
                    cartItems: cartItems,
                    onRemoveFromCart: _removeFromCart,
                    onQuantityChanged: _changeQuantity,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          // Tombol Profile
          IconButton(
            icon: const Icon(Icons.person),
            color: Colors.white,
            tooltip: "Profil",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(currentUser: widget.user),
                ),
              );
            },
          ),
          // Tombol Logout
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: primaryColor,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Text(
              "Selamat datang, ${widget.user.username}!",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.70,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isFavorite = favoriteProducts.contains(product);

                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        shadowColor: Colors.black45,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  product: product,
                                  onAddToCart: _addToCart,
                                  onAddToFavorite: _addToFavorites,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1.2,
                                    child: Image.network(
                                      product.thumbnail,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _buildIconButton(
                                          icon: isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFavorite
                                              ? Colors.red
                                              : Colors.white,
                                          onPressed: () =>
                                              _toggleFavorite(product),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildIconButton(
                                          icon: Icons.add_shopping_cart,
                                          color: Colors.white,
                                          onPressed: () =>
                                              _showQuantityDialogWithAdd(
                                                product,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.category,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "\$${priceAfterDiscount(product).toStringAsFixed(2)} USD",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber.shade600,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.rating.toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
