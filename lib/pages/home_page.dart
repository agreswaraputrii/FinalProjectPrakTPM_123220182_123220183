// lib/pages/home_page.dart - Versi Debug
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

// Import Models
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/notification_model.dart';

// PENTING: Impor CartItem dari cart_page.dart Anda.
import '../pages/cart_page.dart';

// Import Services
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// Import Providers
import '../providers/product_provider.dart';

// Import Pages
import '../pages/login_page.dart';
import '../pages/detail_page.dart';
import '../pages/favorite_page.dart';
import '../pages/profile_page.dart';
import '../pages/notification_page.dart';
import '../pages/add_product_page.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ProductModel> favoriteProducts = [];
  List<CartItem> cartItems = [];

  late AuthService _authService;
  late NotificationService _notificationService;
  bool _servicesInitialized = false;
  Box<NotificationModel>? _notificationBox;

  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('HomePage initState called');
    }
    _initServices();

    // Load products after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print('About to fetch products');
      }
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.fetchProducts().catchError((error) {
        if (kDebugMode) {
          print('Error fetching products: $error');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading products: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    });
  }

  Future<void> _initServices() async {
    try {
      if (kDebugMode) {
        print('Initializing services...');
      }

      if (!Hive.isBoxOpen('userBox')) {
        await Hive.openBox<UserModel>('userBox');
      }
      if (!Hive.isBoxOpen('notificationBox')) {
        await Hive.openBox<NotificationModel>('notificationBox');
      }

      _notificationBox = Hive.box<NotificationModel>('notificationBox');
      _authService = AuthService(Hive.box<UserModel>('userBox'));
      _notificationService = NotificationService(_notificationBox!);

      _updateNotificationCount();

      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }

      if (kDebugMode) {
        print('Services initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing services: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load app data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Set services as initialized even if there's an error to prevent infinite loading
        setState(() {
          _servicesInitialized = true;
        });
      }
    }
  }

  int _getUnreadCountForUser(String username) {
    try {
      if (!_servicesInitialized ||
          _notificationBox == null ||
          !_notificationBox!.isOpen) {
        return 0;
      }
      return _notificationService.getUnreadNotificationCount(username);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: $e');
      }
      return 0;
    }
  }

  void _updateNotificationCount() {
    if (_servicesInitialized) {
      final count = _getUnreadCountForUser(widget.user.username);
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
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

  Future<void> _showQuantityDialogWithAdd(
    BuildContext context,
    ProductModel product,
  ) async {
    final controller = TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah ke Keranjang"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Jumlah"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 1;
              if (quantity > 0 && quantity <= product.stock) {
                _addToCart(product, quantity);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Jumlah tidak valid atau melebihi stok (${product.stock})',
                    ),
                  ),
                );
              }
            },
            child: const Text("Tambahkan"),
          ),
        ],
      ),
    );
  }

  final Color primaryColor = const Color(0xFF4E342E);
  final Color accentColor = const Color(0xFFFF7043);

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('HomePage build called');
    }

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
          // Tombol Notifikasi
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
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (kDebugMode) {
                  print('Consumer builder called');
                  print('isLoading: ${productProvider.isLoading}');
                  print('errorMessage: ${productProvider.errorMessage}');
                  print('products length: ${productProvider.products.length}');
                }

                // Jika masih loading
                if (productProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat produk...'),
                      ],
                    ),
                  );
                }

                // Jika ada error
                if (productProvider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Terjadi kesalahan:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (kDebugMode) {
                                print('Retry button pressed');
                              }
                              productProvider.clearErrorMessage();
                              productProvider.fetchProducts();
                            },
                            child: const Text('Coba Lagi'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              // Show debug info
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Debug Info'),
                                  content: Text(
                                    'Error: ${productProvider.errorMessage}\n'
                                    'Services Initialized: $_servicesInitialized\n'
                                    'User: ${widget.user.username}',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text('Debug Info'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Jika tidak ada produk
                if (productProvider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada produk ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada produk yang tersedia saat ini',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            productProvider.fetchProducts();
                          },
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }

                // Menampilkan grid produk
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    final isProductFavorite = favoriteProducts.contains(
                      product,
                    );

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
                                currentUser: widget.user,
                                isSeller: widget.user.roles.contains('seller'),
                                isInitialFavorite: isProductFavorite,
                              ),
                            ),
                          ).then((_) {
                            productProvider.fetchProducts();
                            setState(() {});
                          });
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
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildIconButton(
                                        icon: isProductFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isProductFavorite
                                            ? Colors.red
                                            : Colors.white,
                                        onPressed: () =>
                                            _toggleFavorite(product),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildIconButton(
                                        icon: Icons.add_shopping_cart,
                                        color: product.stock > 0
                                            ? Colors.white
                                            : Colors.grey,
                                        onPressed: product.stock > 0
                                            ? () => _showQuantityDialogWithAdd(
                                                context,
                                                product,
                                              )
                                            : null,
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
                                    "\$${product.finalPrice.toStringAsFixed(2)} USD",
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
                                        product.rating.toStringAsFixed(1),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.user.roles.contains('seller')
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductPage(),
                  ),
                ).then((_) {
                  Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).fetchProducts();
                });
              },
              child: const Icon(Icons.add),
              tooltip: 'Tambah Produk',
              backgroundColor: accentColor,
            )
          : null,
    );
  }
}
