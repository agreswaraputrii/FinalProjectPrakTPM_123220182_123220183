import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart'; // <-- TAMBAHKAN INI

import '../pages/cart_page.dart'; // Asumsi CartItem ada di sini
import 'success_page.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/local_notification_service.dart'; // Import service notifikasi
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../providers/order_provider.dart';

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

  late NotificationService _notificationService;
  late UserModel? _currentUser; // Untuk menyimpan user yang sedang login

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
    // Pastikan semua Hive Box yang diperlukan sudah terbuka
    if (!Hive.isBoxOpen('orderBox')) {
      await Hive.openBox<OrderModel>('orderBox');
    }
    if (!Hive.isBoxOpen('notificationBox')) {
      await Hive.openBox<NotificationModel>('notificationBox');
    }
    // Asumsi userBox sudah terbuka di main.dart
    final userBox = Hive.box<UserModel>('userBox');
    final authService = AuthService(userBox);
    _currentUser = await authService.getLoggedInUser();

    _notificationService = NotificationService(
      Hive.box<NotificationModel>('notificationBox'),
    );

    // Jika user punya nama dan alamat default, bisa diisi otomatis
    if (_currentUser != null) {
      _nameController.text = _currentUser!.fullName;
      // Jika UserModel Anda memiliki field alamat:
      // _addressController.text = _currentUser!.address;
    }
    setState(() {}); // Untuk refresh UI setelah data user terload
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
    // Cek apakah layanan lokasi aktif
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

    // Request permission
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

    try {
      // Tampilkan loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Dapatkan posisi saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout 10 detik
      );

      // Konversi koordinat ke alamat
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Tutup loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Format alamat yang lebih detail
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += address.isEmpty
              ? place.subLocality!
              : ', ${place.subLocality!}';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += address.isEmpty ? place.locality! : ', ${place.locality!}';
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          address += address.isEmpty
              ? place.subAdministrativeArea!
              : ', ${place.subAdministrativeArea!}';
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          address += address.isEmpty
              ? place.administrativeArea!
              : ', ${place.administrativeArea!}';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          address += address.isEmpty ? place.country! : ', ${place.country!}';
        }

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
      // Tutup loading dialog jika masih terbuka
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
      print('Error getting location: $e'); // Untuk debugging
    }
  }

  void _checkout() async {
    if (!_formKey.currentState!.validate() ||
        selectedCourier == null ||
        selectedPayment == null ||
        _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data dan pastikan Anda login!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang Anda kosong!')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Dapatkan sellerUsername dari produk yang dibeli.
      // Asumsi sementara: semua produk dalam satu checkout berasal dari seller yang sama.
      final String actualSellerUsername =
          widget.cartItems.first.product.uploaderUsername ?? 'admin_store';

      // Jika uploaderUsername null (misal dari produk API dummy), beri fallback
      if (actualSellerUsername == 'unknown_seller') {
        // Handle error, jangan lanjutkan checkout jika seller tidak diketahui
        Navigator.of(context).pop(); // Tutup dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Penjual produk tidak ditemukan!'),
          ),
        );
        return;
      }

      // 2. Buat OrderProductItem dari CartItem
      List<OrderProductItem> orderItems = widget.cartItems.map((cartItem) {
        return OrderProductItem(
          productId: cartItem.product.id,
          productName: cartItem.product.title,
          productImageUrl: cartItem.product.thumbnail,
          price: cartItem.product.price,
          discountPercentage: cartItem.product.discountPercentage,
          quantity: cartItem.quantity,
          // PENTING: Tambahkan seller username di setiap item
          // Ini akan berguna jika Anda ingin mendukung checkout dari banyak seller sekaligus
          // sellerUsername: cartItem.product.uploaderUsername,
        );
      }).toList();

      // 3. Buat objek OrderModel baru
      final newOrder = OrderModel(
        customerUsername: _currentUser!.username,
        customerName: _nameController.text,
        customerAddress: _addressController.text,
        customerPhoneNumber: _currentUser!.phoneNumber,
        items: orderItems,
        subtotalAmount: subtotal,
        courierService: selectedCourier!,
        courierCost: courierCost,
        totalAmount: totalUSD,
        paymentMethod: selectedPayment!,
        selectedCurrency: selectedCurrency,
        sellerUsername:
            actualSellerUsername, // <-- GUNAKAN USERNAME SELLER YANG BENAR
      );

      // 4. Panggil OrderProvider untuk menambah pesanan
      // Ini akan menyimpan ke Hive DAN memberitahu UI
      await Provider.of<OrderProvider>(
        context,
        listen: false,
      ).addOrder(newOrder);

      // 1. Notifikasi In-App (yang sudah Anda miliki)
      await _notificationService.addNotification(
        targetUsername: _currentUser!.username,
        type: NotificationType.orderPaid,
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} telah berhasil dibayar.',
        referenceId: newOrder.orderId,
      );
      await _notificationService.addNotification(
        targetUsername: actualSellerUsername,
        type: NotificationType.newOrder,
        title: 'Pesanan Baru Masuk!',
        body: 'Ada pesanan baru dari ${_currentUser!.fullName}.',
        referenceId: newOrder.orderId,
      );

      // 2. Notifikasi Push (yang baru kita tambahkan)
      // Untuk Pembeli
      await LocalNotificationService.showNotification(
        id: newOrder.hashCode, // Gunakan ID unik
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} sedang diproses oleh penjual.',
      );
      // Untuk Penjual (Anda bisa menambahkan logika agar ini hanya muncul jika penjualnya bukan user saat ini)
      // ID harus berbeda agar tidak menimpa notifikasi pembeli
      await LocalNotificationService.showNotification(
        id: newOrder.hashCode + 1,
        title: 'Pesanan Baru!',
        body: 'Anda menerima pesanan baru dari ${_currentUser!.fullName}.',
      );

      // 5. Buat Notifikasi (logika notifikasi Anda sudah bagus)
      await _notificationService.addNotification(
        targetUsername: _currentUser!.username,
        type: NotificationType.orderPaid,
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} telah berhasil dibayar. Total: ${formattedTotal}.',
        referenceId: newOrder.orderId,
      );

      await _notificationService.addNotification(
        targetUsername:
            actualSellerUsername, // Kirim notif ke seller yang benar
        type: NotificationType.newOrder,
        title: 'Pesanan Baru Masuk!',
        body:
            'Ada pesanan baru dari ${_currentUser!.fullName}. ID Pesanan: #${newOrder.orderId.substring(0, 8)}.',
        referenceId: newOrder.orderId,
      );
      // Tutup loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        // Navigasi ke SuccessPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
        widget.onCheckoutComplete(); // Panggil callback
      }
    } catch (e) {
      // Tutup loading dialog jika ada error
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat checkout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Checkout Error: $e'); // Untuk debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF4E342E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text('Checkout', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Penerima'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
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
                decoration: const InputDecoration(labelText: 'Mata Uang'),
                items: currencyRates.keys.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedCurrency = val!),
              ),
              const SizedBox(height: 24),
              Text(
                'Total: $formattedTotal',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _checkout,
                child: Text('Bayar Sekarang', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
