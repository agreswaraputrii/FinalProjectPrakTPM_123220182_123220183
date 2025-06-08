// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'dart:async'; // Import for Timer

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
import '../pages/profile_page.dart'; // User Profile Page
import '../pages/my_personal_profile_page.dart'; // My Personal Profile Page
import '../pages/saran_kesan_page.dart'; // Saran & Kesan Page
import '../pages/notification_page.dart';
import '../pages/add_product_page.dart';

enum SortOption {
  none,
  priceLowToHigh,
  priceHighToLow,
  ratingLowToHigh,
  ratingHighToLow,
}

// Definisikan TimeZoneOption
enum TimeZoneOption { wib, wita, wit, london }

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
  int _selectedIndex =
      0; // 0: Home, 1: User Profile, 2: My Personal Profile, 3: Saran & Kesan, 4: Logout Placeholder

  // Search and Sort variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // Inisialisasi dengan string kosong
  SortOption _currentSortOption = SortOption.none;

  // Time conversion variables
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  // Default to WIB
  TimeZoneOption _selectedTimeZone = TimeZoneOption.wib;

  // Color scheme (matching RegisterPage)
  final Color primaryColor = const Color(0xFF2E7D32); // Green
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35); // Orange accent
  final Color backgroundColor = const Color(0xFFF1F8E9);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initServices();
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

    // Initialize timer for time conversion
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer?.cancel(); // Cancel the timer
    super.dispose();
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
        print(
          'Error initializing services or opening Hive boxes in HomePage: $e',
        );
      }
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
      setState(() {
        _notificationCount = count;
      });
    }
  }

  // Filter and sort products
  List<ProductModel> _getFilteredAndSortedProducts(
    List<ProductModel> products,
  ) {
    // Mulai dengan semua produk yang ada
    List<ProductModel> filteredProducts = List.from(products);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        final productTitleLower = product.title.toLowerCase();
        final productCategoryLower = product.category.toLowerCase();

        return productTitleLower.contains(_searchQuery) ||
            productCategoryLower.contains(_searchQuery);
      }).toList();
    }

    // Sort products
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
        // Biarkan urutan asli
        break;
    }
    return filteredProducts;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urutkan Berdasarkan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.clear,
                  color: _currentSortOption == SortOption.none
                      ? primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  'Default',
                  style: GoogleFonts.poppins(
                    color: _currentSortOption == SortOption.none
                        ? primaryColor
                        : Colors.black,
                    fontWeight: _currentSortOption == SortOption.none
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.none;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.arrow_upward,
                  color: _currentSortOption == SortOption.priceLowToHigh
                      ? primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  'Harga Terendah ke Tertinggi',
                  style: GoogleFonts.poppins(
                    color: _currentSortOption == SortOption.priceLowToHigh
                        ? primaryColor
                        : Colors.black,
                    fontWeight: _currentSortOption == SortOption.priceLowToHigh
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.priceLowToHigh;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.arrow_downward,
                  color: _currentSortOption == SortOption.priceHighToLow
                      ? primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  'Harga Tertinggi ke Terendah',
                  style: GoogleFonts.poppins(
                    color: _currentSortOption == SortOption.priceHighToLow
                        ? primaryColor
                        : Colors.black,
                    fontWeight: _currentSortOption == SortOption.priceHighToLow
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.priceHighToLow;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.star_border,
                  color: _currentSortOption == SortOption.ratingLowToHigh
                      ? primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  'Rating Terendah ke Tertinggi',
                  style: GoogleFonts.poppins(
                    color: _currentSortOption == SortOption.ratingLowToHigh
                        ? primaryColor
                        : Colors.black,
                    fontWeight: _currentSortOption == SortOption.ratingLowToHigh
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.ratingLowToHigh;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.star,
                  color: _currentSortOption == SortOption.ratingHighToLow
                      ? primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  'Rating Tertinggi ke Terendah',
                  style: GoogleFonts.poppins(
                    color: _currentSortOption == SortOption.ratingHighToLow
                        ? primaryColor
                        : Colors.black,
                    fontWeight: _currentSortOption == SortOption.ratingHighToLow
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.ratingHighToLow;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Hasil pencarian: "$_searchQuery"'
                  : 'Semua Produk',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: _showSortOptions,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Urutkan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  double priceAfterDiscount(ProductModel product) {
    return product.price * (1 - product.discountPercentage / 100);
  }

  // New Widget for Time Conversion with Dropdown
  Widget _buildTimeConversionDropdown() {
    final formatter = DateFormat('HH:mm:ss');
    DateTime displayedTime;
    String timeZoneName;

    // Determine which time to display based on _selectedTimeZone
    switch (_selectedTimeZone) {
      case TimeZoneOption.wib:
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 7));
        timeZoneName = "WIB";
        break;
      case TimeZoneOption.wita:
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 8));
        timeZoneName = "WITA";
        break;
      case TimeZoneOption.wit:
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 9));
        timeZoneName = "WIT";
        break;
      case TimeZoneOption.london:
        // Adjust for BST/GMT if needed (assuming BST for now, UTC+1)
        displayedTime = _currentTime.toUtc().add(const Duration(hours: 1));
        timeZoneName = "London";
        break;
    }

    return Container(
      color: secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$timeZoneName: ${formatter.format(displayedTime)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          DropdownButton<TimeZoneOption>(
            value: _selectedTimeZone,
            dropdownColor: secondaryColor, // Dropdown menu background color
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: const SizedBox(), // Remove the default underline
            onChanged: (TimeZoneOption? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedTimeZone = newValue;
                });
              }
            },
            items: const <DropdownMenuItem<TimeZoneOption>>[
              DropdownMenuItem<TimeZoneOption>(
                value: TimeZoneOption.wib,
                child: Text('WIB', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem<TimeZoneOption>(
                value: TimeZoneOption.wita,
                child: Text('WITA', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem<TimeZoneOption>(
                value: TimeZoneOption.wit,
                child: Text('WIT', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem<TimeZoneOption>(
                value: TimeZoneOption.london,
                child: Text('London', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeTab(),
      ProfilePage(currentUser: widget.user, onLogout: _logout),
      MyPersonalProfilePage(),
      SaranKesanPage(),
    ];

    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = "Home";
        break;
      case 1:
        appBarTitle = "Profil Pengguna";
        break;
      case 2:
        appBarTitle = "Profil Pribadi";
        break;
      case 3:
        appBarTitle = "Saran dan Kesan";
        break;
      default:
        appBarTitle = "Home";
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          appBarTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_selectedIndex == 0) ...[
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
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
          ],
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 4) {
            _logout();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
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
                ).then((_) {
                  Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).fetchProducts(category: 'groceries');
                });
              },
              child: const Icon(Icons.add),
              tooltip: 'Tambah Produk',
              backgroundColor: accentColor,
            )
          : null,
    );
  }

  // --- Widgets for each tab ---
  Widget _buildHomeTab() {
    return Column(
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
        // Add the dropdown widget here
        _buildTimeConversionDropdown(),
        _buildSearchBar(),
        _buildFilterSortBar(),
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productProvider.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          productProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            productProvider.fetchProducts(
                              category: 'groceries',
                            );
                            productProvider.clearErrorMessage();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (productProvider.allProducts.isEmpty) {
                return const Center(child: Text('Tidak ada produk ditemukan.'));
              }

              // Apply filter and sorting
              final filteredProducts = _getFilteredAndSortedProducts(
                productProvider.allProducts,
              );

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada produk yang sesuai\ndengan pencarian Anda',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        child: const Text('Hapus Filter'),
                      ),
                    ],
                  ),
                );
              }

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
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final isProductFavorite = favoriteProducts.any(
                    (favProd) => favProd.id == product.id,
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
                          setState(() {});
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: Image.network(
                                    product.thumbnail,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[300],
                                              alignment: Alignment.center,
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
                                        color: Colors.white,
                                        onPressed: product.stock > 0
                                            ? () {
                                                _showQuantityDialogWithAdd(
                                                  context,
                                                  product,
                                                );
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                ],
                              ),
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
    );
  }
}
