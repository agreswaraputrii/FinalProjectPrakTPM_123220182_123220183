import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../pages/cart_page.dart';
import 'success_page.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final void Function() onCheckoutComplete;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.onCheckoutComplete,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? selectedCourier;
  String? selectedPayment;
  String selectedCurrency = 'USD';

  OrderService? _orderService;
  NotificationService? _notificationService;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _servicesInitialized = false;

  final Map<String, double> courierPrices = {
    'JNE': 5.0,
    'SiCepat': 7.0,
    'AnterAja': 4.5,
  };

  final List<String> paymentMethods = ['Transfer Bank', 'QRIS', 'Kartu Kredit'];

  final Map<String, double> currencyRates = {
    'USD': 1.0,
    'IDR': 15000,
    'JPY': 155,
    'EUR': 0.9,
  };

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Pastikan semua Hive Box yang diperlukan sudah terbuka di main.dart.
      // Kita hanya akan mencoba mengaksesnya di sini.
      if (!Hive.isBoxOpen('orderBox')) {
        // Jika belum terbuka (misalnya, di dev hot reload), buka secara eksplisit
        await Hive.openBox<OrderModel>('orderBox');
      }
      if (!Hive.isBoxOpen('notificationBox')) {
        await Hive.openBox<NotificationModel>('notificationBox');
      }
      if (!Hive.isBoxOpen('userBox')) {
        await Hive.openBox<UserModel>('userBox');
      }

      final userBox = Hive.box<UserModel>('userBox');
      final authService = AuthService(userBox);
      _currentUser = await authService.getLoggedInUser();

      if (_currentUser == null) {
        throw Exception('User tidak ditemukan. Silakan login kembali.');
      }

      // Inisialisasi service setelah memastikan box terbuka
      _orderService = OrderService(Hive.box<OrderModel>('orderBox'), userBox);
      _notificationService = NotificationService(
        Hive.box<NotificationModel>('notificationBox'),
      );

      _nameController.text = _currentUser!.fullName;

      setState(() {
        _servicesInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error initializing services: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get subtotal {
    return widget.cartItems.fold(
      0,
      (sum, item) =>
          sum +
          item.product.price *
              (1 - item.product.discountPercentage / 100) *
              item.quantity,
    );
  }

  double get courierCost => courierPrices[selectedCourier] ?? 0.0;

  double get totalUSD => subtotal + courierCost;

  double get totalConverted =>
      totalUSD * (currencyRates[selectedCurrency] ?? 1.0);

  String get formattedTotal {
    final format = NumberFormat.currency(name: selectedCurrency);
    return format.format(totalConverted);
  }

  Future<void> _getCurrentLocationAndFillAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Layanan lokasi tidak aktif. Mohon aktifkan GPS.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin lokasi ditolak'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Mohon aktifkan di pengaturan aplikasi.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Mendapatkan lokasi...'),
              ],
            ),
          ),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        String address = addressParts.join(', ');

        setState(() {
          _addressController.text = address.isEmpty
              ? 'Alamat tidak ditemukan'
              : address;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi berhasil digunakan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat menemukan alamat untuk lokasi ini'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      String errorMessage = 'Gagal mendapatkan lokasi';
      if (e.toString().contains('timeout')) {
        errorMessage =
            'Waktu tunggu habis. Pastikan GPS aktif dan sinyal kuat.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet untuk mendapatkan alamat.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
      print('Error getting location: $e');
    }
  }

  void _checkout() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field yang diperlukan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedCourier == null || selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih jasa kirim dan metode pembayaran!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_servicesInitialized ||
        _currentUser == null ||
        _orderService == null ||
        _notificationService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Services belum siap. Mohon tunggu sebentar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Memproses checkout...'),
          ],
        ),
      ),
    );

    try {
      List<OrderProductItem> orderItems = widget.cartItems.map((cartItem) {
        return OrderProductItem(
          productId: cartItem.product.id.toString(),
          productName: cartItem.product.title,
          productImageUrl: cartItem.product.thumbnail,
          price: cartItem.product.price.toDouble(),
          discountPercentage: cartItem.product.discountPercentage.toDouble(),
          quantity: cartItem.quantity,
        );
      }).toList();

      String sellerUsernamePlaceholder = 'admin_seller_account';

      final newOrder = await _orderService!.createOrder(
        customerUsername: _currentUser!.username,
        customerName: _nameController.text.trim(),
        customerAddress: _addressController.text.trim(),
        customerPhoneNumber: _currentUser!.phoneNumber,
        items: orderItems,
        subtotalAmount: subtotal,
        courierService: selectedCourier!,
        courierCost: courierCost,
        totalAmount: totalUSD,
        paymentMethod: selectedPayment!,
        selectedCurrency: selectedCurrency,
        sellerUsername: sellerUsernamePlaceholder,
      );

      await _notificationService!.addNotification(
        targetUsername: _currentUser!.username,
        type: NotificationType.orderPaid,
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} telah berhasil dibayar. Total: $formattedTotal.',
        referenceId: newOrder.orderId,
      );

      if (sellerUsernamePlaceholder != 'admin_seller_account') {
        await _notificationService!.addNotification(
          targetUsername: sellerUsernamePlaceholder,
          type: NotificationType.newOrder,
          title: 'Pesanan Baru Masuk!',
          body:
              'Ada pesanan baru dari ${_currentUser!.fullName}. ID Pesanan: #${newOrder.orderId.substring(0, 8)}.',
          referenceId: newOrder.orderId,
        );
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
        widget.onCheckoutComplete();
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat checkout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Checkout Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF4E342E);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: themeColor,
          title: Text('Checkout', style: GoogleFonts.poppins()),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data checkout...'),
            ],
          ),
        ),
      );
    }

    if (!_servicesInitialized || _currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: themeColor,
          title: Text('Checkout', style: GoogleFonts.poppins()),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Gagal memuat data. Silakan coba lagi.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Info User
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Pembeli',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Username: ${_currentUser!.username}'),
                      Text('Email: ${_currentUser!.email}'),
                      Text('Phone: ${_currentUser!.phoneNumber}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Form Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Penerima',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nama penerima wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Alamat wajib diisi'
                    : null,
                maxLines: 3,
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _getCurrentLocationAndFillAddress,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Gunakan Lokasi Saya'),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedCourier,
                decoration: const InputDecoration(
                  labelText: 'Jasa Kirim',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Pilih Jasa Kirim'),
                items: courierPrices.keys.map((courier) {
                  return DropdownMenuItem(
                    value: courier,
                    child: Text('$courier (+\$${courierPrices[courier]})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedCourier = val),
                validator: (val) => val == null ? 'Pilih jasa kirim' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedPayment,
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Pilih Metode Pembayaran'),
                items: paymentMethods.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (val) => setState(() => selectedPayment = val),
                validator: (val) =>
                    val == null ? 'Pilih metode pembayaran' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Mata Uang',
                  border: OutlineInputBorder(),
                ),
                items: currencyRates.keys.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedCurrency = val!),
              ),
              const SizedBox(height: 24),

              // Order Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
                      Text('Ongkir: \$${courierCost.toStringAsFixed(2)}'),
                      const Divider(),
                      Text(
                        'Total: $formattedTotal',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _checkout,
                child: Text(
                  'Bayar Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
