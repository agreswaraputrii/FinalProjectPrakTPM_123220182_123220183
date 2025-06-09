// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:ui'; // For BackdropFilter
import 'package:sensors_plus/sensors_plus.dart';

// Import Models
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/notification_model.dart';
import '../pages/cart_page.dart';

// Import Services & Providers
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/product_provider.dart';

// Import Pages
import '../pages/login_page.dart';
import '../pages/detail_page.dart';
import '../pages/favorite_page.dart';
import '../pages/profile_page.dart';
import '../pages/my_personal_profile_page.dart';
import '../pages/saran_kesan_page.dart';
import '../pages/notification_page.dart';
import '../pages/add_product_page.dart';

enum SortOption {
  none,
  priceLowToHigh,
  priceHighToLow,
  ratingLowToHigh,
  ratingHighToLow,
}

enum TimeZoneOption { wib, wita, wit, london }

class HomePage extends StatefulWidget {
  final UserModel user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _accelerometerSubscription;
  bool _isTiltScrollEnabled = false;

  List<ProductModel> favoriteProducts = [];
  List<CartItem> cartItems = [];

  late AuthService _authService;
  late NotificationService _notificationService;
  bool _servicesInitialized = false;
  Box<NotificationModel>? _notificationBox;

  int _notificationCount = 0;
  int _selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _currentSortOption = SortOption.none;

  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  TimeZoneOption _selectedTimeZone = TimeZoneOption.wib;

  // --- Consistent Modern Color Scheme ---
  final Color primaryColor = const Color(0xFF2E7D32); // Deep Green
  final Color secondaryColor = const Color(0xFF4CAF50); // Bright Green
  final Color accentColor = const Color(0xFFFF8F00); // Amber Accent
  final Color backgroundColor = const Color(0xFFF1F8E9); // Light Greenish White
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initServices();
    _initTiltToScroll();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchProducts(category: 'groceries');
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => setState(() => _currentTime = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _searchController.dispose();
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // --- All backend and logic functions remain unchanged ---
  void _initTiltToScroll() {
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      if (_isTiltScrollEnabled) {
        const double threshold = 1.5;
        final double scrollSpeed = (event.y.abs() - threshold) * 20.0;
        if (event.y > threshold && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.offset + scrollSpeed,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        } else if (event.y < -threshold && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.offset - scrollSpeed,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  void _toggleTiltScroll() {
    setState(() => _isTiltScrollEnabled = !_isTiltScrollEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTiltScrollEnabled
              ? 'Fitur "Miringkan untuk Gulir" Aktif'
              : 'Fitur "Miringkan untuk Gulir" Nonaktif',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: _isTiltScrollEnabled ? primaryColor : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _initServices() async {
    try {
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
      setState(() {
        _servicesInitialized = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing services in HomePage: $e');
      }
    }
  }

  void _updateNotificationCount() {
    if (_servicesInitialized) {
      final count = _notificationService.getUnreadNotificationCount(
        widget.user.username,
      );
      if (mounted) {
        setState(() => _notificationCount = count);
      }
    }
  }

  List<ProductModel> _getFilteredAndSortedProducts(
    List<ProductModel> products,
  ) {
    List<ProductModel> filteredProducts = List.from(products);
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.title.toLowerCase().contains(_searchQuery) ||
            product.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    switch (_currentSortOption) {
      case SortOption.priceLowToHigh:
        filteredProducts.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case SortOption.priceHighToLow:
        filteredProducts.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case SortOption.ratingLowToHigh:
        filteredProducts.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case SortOption.ratingHighToLow:
        filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.none:
        break;
    }
    return filteredProducts;
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
      if (favoriteProducts.any((p) => p.id == product.id)) {
        favoriteProducts.removeWhere((p) => p.id == product.id);
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
        if (!favoriteProducts.any((p) => p.id == product.id))
          favoriteProducts.add(product);
      } else {
        favoriteProducts.removeWhere((p) => p.id == product.id);
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
    setState(
      () => cartItems.removeWhere(
        (item) => item.product.id == cartItem.product.id,
      ),
    );
  }

  void _changeQuantity(CartItem cartItem, int quantity) {
    setState(() {
      final index = cartItems.indexWhere(
        (item) => item.product.id == cartItem.product.id,
      );
      if (index != -1) cartItems[index].quantity = quantity;
    });
  }

  Future<void> _showQuantityDialogWithAdd(
    BuildContext context,
    ProductModel product,
  ) async {
    final int moq = product.minimumOrderQuantity;
    int currentQuantity = moq; // Mulai dari MOQ

    // Menggunakan StatefulBuilder untuk memperbarui UI dialog secara lokal
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDecrementDisabled = currentQuantity <= moq;
            final isIncrementDisabled = currentQuantity + moq > product.stock;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: cardColor,
              title: Row(
                children: [
                  Icon(
                    Icons.shopping_basket_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // Menggunakan Expanded untuk mencegah overflow
                    child: Text(
                      "Tambah Jumlah ${product.title}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: primaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Stok Tersedia: ${product.stock} ${product.unit}", // Menampilkan unit
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove,
                            color: isDecrementDisabled
                                ? Colors.grey
                                : primaryColor,
                          ),
                          onPressed: isDecrementDisabled
                              ? null
                              : () {
                                  setState(() {
                                    currentQuantity = (currentQuantity - moq)
                                        .clamp(moq, product.stock);
                                  });
                                },
                        ),
                        Expanded(
                          child: Text(
                            '$currentQuantity ${product.unit}', // Menampilkan unit
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            color: isIncrementDisabled
                                ? Colors.grey
                                : primaryColor,
                          ),
                          onPressed: isIncrementDisabled
                              ? null
                              : () {
                                  setState(() {
                                    currentQuantity = (currentQuantity + moq)
                                        .clamp(moq, product.stock);
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Harga per ${product.unit}: \$${product.finalPrice.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "Total Harga: \$${(product.finalPrice * currentQuantity).toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Batal",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (currentQuantity > 0 &&
                        currentQuantity % moq == 0 &&
                        currentQuantity <= product.stock) {
                      _addToCart(product, currentQuantity);
                      Navigator.pop(ctx);
                    } else {
                      String errorMessage = '';
                      if (currentQuantity <= 0) {
                        errorMessage =
                            'Jumlah tidak boleh kurang dari atau sama dengan 0.';
                      } else if (currentQuantity % moq != 0) {
                        errorMessage = 'Jumlah harus kelipatan $moq.';
                      } else if (currentQuantity > product.stock) {
                        errorMessage =
                            'Jumlah melebihi stok yang tersedia (${product.stock}).';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            errorMessage,
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    "Tambahkan",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urutkan Berdasarkan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...SortOption.values.map((option) {
                    final titles = {
                      SortOption.none: 'Default',
                      SortOption.priceLowToHigh: 'Harga: Terendah ke Tertinggi',
                      SortOption.priceHighToLow: 'Harga: Tertinggi ke Terendah',
                      SortOption.ratingLowToHigh:
                          'Rating: Terendah ke Tertinggi',
                      SortOption.ratingHighToLow:
                          'Rating: Tertinggi ke Terendah',
                    };
                    final icons = {
                      SortOption.none: Icons.sort,
                      SortOption.priceLowToHigh: Icons.arrow_upward,
                      SortOption.priceHighToLow: Icons.arrow_downward,
                      SortOption.ratingLowToHigh: Icons.star_border,
                      SortOption.ratingHighToLow: Icons.star,
                    };
                    final bool isSelected = _currentSortOption == option;
                    return ListTile(
                      leading: Icon(
                        icons[option],
                        color: isSelected ? accentColor : Colors.grey,
                      ),
                      title: Text(
                        titles[option]!,
                        style: GoogleFonts.poppins(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? primaryColor : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        setState(() => _currentSortOption = option);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // List of pages for IndexedStack
    final List<Widget> pages = [
      _buildHomeTab(),
      // Ensure other pages have transparent backgrounds to see the decoration
      Scaffold(
        backgroundColor: Colors.transparent,
        body: ProfilePage(currentUser: widget.user, onLogout: _logout),
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: MyPersonalProfilePage(),
      ),
      Scaffold(backgroundColor: Colors.transparent, body: SaranKesanPage()),
      // Placeholder for logout, it's not a page but an action
      Container(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildDecorativeBackground(),
          IndexedStack(index: _selectedIndex, children: pages),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton:
          widget.user.roles.contains('seller') && _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddProductPage(currentUser: widget.user),
                  ),
                ).then(
                  (_) => Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).fetchProducts(category: 'groceries'),
                );
              },
              backgroundColor: accentColor,
              tooltip: 'Tambah Produk',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- UI BUILDER WIDGETS (Revamped & Fixed) ---

  Widget _buildDecorativeBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, Colors.white],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            // Handle logout on the 5th item
            if (index == 4) {
              _logout();
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          backgroundColor: cardColor.withOpacity(0.85),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'User Profil',
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[200],
                backgroundImage: const AssetImage('assets/foto_saya.jpg'),
                child: const SizedBox.shrink(),
              ),
              label: 'My Profil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.feedback_rounded),
              label: 'Saran & Kesan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.logout_rounded),
              label: 'Logout',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHomeHeader(),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: innerBoxIsScrolled
                  ? Text(
                      'Groceries Store',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ];
      },
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterSortBar(),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (productProvider.errorMessage != null) {
                  return Center(child: Text(productProvider.errorMessage!));
                }
                final filteredProducts = _getFilteredAndSortedProducts(
                  productProvider.allProducts,
                );
                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada produk yang cocok.'),
                  );
                }
                return _buildProductGrid(filteredProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // FIX 1: Wrapped the text column in Expanded to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.user.fullName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderIcon(
                    Icons.screen_rotation_alt_rounded,
                    _isTiltScrollEnabled,
                    _toggleTiltScroll,
                  ),
                  _buildHeaderIcon(
                    Icons.notifications,
                    _notificationCount > 0,
                    () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NotificationPage(currentUser: widget.user),
                        ),
                      );
                      _updateNotificationCount();
                    },
                    badgeCount: _notificationCount,
                  ),
                  _buildHeaderIcon(
                    Icons.favorite,
                    favoriteProducts.isNotEmpty,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FavoritePage(favoriteProducts: favoriteProducts),
                      ),
                    ),
                  ),
                  _buildHeaderIcon(
                    Icons.shopping_cart,
                    cartItems.isNotEmpty,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartPage(
                          cartItems: cartItems,
                          onRemoveFromCart: _removeFromCart,
                          onQuantityChanged: _changeQuantity,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimeConversionDropdown(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(
    IconData icon,
    bool isActive,
    VoidCallback onPressed, {
    int badgeCount = 0,
  }) {
    return Stack(
      children: [
        IconButton(
          padding: const EdgeInsets.all(
            6,
          ), // Reduced padding to prevent overflow
          constraints: const BoxConstraints(),
          icon: Icon(
            icon,
            color: isActive ? accentColor : Colors.white,
            size: 26,
          ),
          onPressed: onPressed,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Cari buah, sayur, dll...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Produk Pilihan",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton.icon(
            onPressed: _showSortOptions,
            icon: Icon(Icons.sort, size: 20, color: primaryColor),
            label: Text(
              "Urutkan",
              style: GoogleFonts.poppins(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isFavorite = favoriteProducts.any((p) => p.id == product.id);
        return _buildProductCard(product, isFavorite);
      },
    );
  }

  Widget _buildProductCard(ProductModel product, bool isFavorite) {
    final bool isOutOfStock = product.stock == 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
            ],
          ),
          child: Column(
            // Column wrap to separate touch areas
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: InkWell(
                          // Make the image area tappable for detail page
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  product: product,
                                  onAddToCart: _addToCart,
                                  onAddToFavorite: _addToFavorites,
                                  currentUser: widget.user,
                                  isSeller: widget.user.roles.contains(
                                    'seller',
                                  ),
                                  isInitialFavorite: isFavorite,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: Image.network(
                            product.thumbnail,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => _toggleFavorite(product),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.black.withOpacity(0.4),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? Colors.redAccent
                                    : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Ini adalah tombol keranjang yang sekarang harus berfungsi
                          InkWell(
                            onTap: isOutOfStock
                                ? null
                                : () => _showQuantityDialogWithAdd(
                                    context,
                                    product,
                                  ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: isOutOfStock
                                  ? Colors.grey.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.4),
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "\$${product.finalPrice.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: accentColor, size: 16),
                              Text(
                                " ${product.rating.toString()}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildTimeConversionDropdown() {
    final formatter = DateFormat('HH:mm:ss');
    DateTime displayedTime;
    switch (_selectedTimeZone) {
      case TimeZoneOption.wib:
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 7));
        break;
      case TimeZoneOption.wita:
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 8));
        break;
      case TimeZoneOption.wit:
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 9));
        break;
      case TimeZoneOption.london:
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 1));
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${formatter.format(displayedTime)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          DropdownButton<TimeZoneOption>(
            value: _selectedTimeZone,
            dropdownColor: secondaryColor,
            icon: const Icon(Icons.public, color: Colors.white, size: 20),
            underline: const SizedBox(),
            onChanged: (TimeZoneOption? newValue) {
              if (newValue != null)
                setState(() => _selectedTimeZone = newValue);
            },
            items: TimeZoneOption.values.map((zone) {
              return DropdownMenuItem<TimeZoneOption>(
                value: zone,
                child: Text(
                  zone.name.toUpperCase(),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
