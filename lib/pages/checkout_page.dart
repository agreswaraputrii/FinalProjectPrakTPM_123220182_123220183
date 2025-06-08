// lib/pages/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

// --- IMPORT UNTUK LBS (LOKASI) ---
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../pages/cart_page.dart';
import 'success_page.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/local_notification_service.dart';
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
  final TextEditingController _courierController = TextEditingController(
    text: "Gratis Ongkir",
  );

  String? selectedCourier;
  String? selectedPayment;
  String selectedCurrency = 'USD';

  bool _isFreeShipping = false;

  late NotificationService _notificationService;
  late UserModel? _currentUser;

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
    _checkFreeShipping();
    _initServices();
  }

  void _checkFreeShipping() {
    if (widget.cartItems.isNotEmpty &&
        widget.cartItems.every((item) => item.product.hasFreeShipping)) {
      setState(() {
        _isFreeShipping = true;
        selectedCourier = 'Gratis Ongkir';
      });
    }
  }

  Future<void> _initServices() async {
    if (!Hive.isBoxOpen('notificationBox')) {
      await Hive.openBox<NotificationModel>('notificationBox');
    }
    final userBox = Hive.box<UserModel>('userBox');
    final authService = AuthService(userBox);
    _currentUser = await authService.getLoggedInUser();

    _notificationService = NotificationService(
      Hive.box<NotificationModel>('notificationBox'),
    );

    if (_currentUser != null) {
      _nameController.text = _currentUser!.fullName;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _courierController.dispose();
    super.dispose();
  }

  double get subtotal => widget.cartItems.fold(
    0,
    (sum, item) => sum + item.product.finalPrice * item.quantity,
  );
  double get courierCost =>
      _isFreeShipping ? 0.0 : (courierPrices[selectedCourier] ?? 0.0);
  double get totalUSD => subtotal + courierCost;
  double get totalConverted =>
      totalUSD * (currencyRates[selectedCurrency] ?? 1.0);
  String get formattedTotal {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: selectedCurrency == 'IDR' ? 'Rp ' : '\$',
    );
    return format.format(totalConverted);
  }

  // --- METHOD LBS YANG DIKEMBALIKAN ---
  Future<void> _getCurrentLocationAndFillAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Layanan lokasi tidak aktif. Mohon aktifkan GPS.'),
            ),
          );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')),
            );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Buka pengaturan aplikasi.',
              ),
            ),
          );
        return;
      }

      if (mounted)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.country}";
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
    }
  }

  void _checkout() async {
    final isCourierValid = _isFreeShipping || selectedCourier != null;
    if (!_formKey.currentState!.validate() ||
        !isCourierValid ||
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String actualSellerUsername =
          widget.cartItems.first.product.uploaderUsername ?? 'admin_store';

      List<OrderProductItem> orderItems = widget.cartItems.map((cartItem) {
        return OrderProductItem(
          productId: cartItem.product.id,
          productName: cartItem.product.title,
          productImageUrl: cartItem.product.thumbnail,
          price: cartItem.product.price,
          discountPercentage: cartItem.product.discountPercentage,
          quantity: cartItem.quantity,
        );
      }).toList();

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
        sellerUsername: actualSellerUsername,
      );

      await context.read<OrderProvider>().addOrder(newOrder);

      // In-App Notification
      await _notificationService.addNotification(
        targetUsername: _currentUser!.username,
        type: NotificationType.orderPaid,
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} sedang diproses.',
        referenceId: newOrder.orderId,
      );
      await _notificationService.addNotification(
        targetUsername: actualSellerUsername,
        type: NotificationType.newOrder,
        title: 'Pesanan Baru!',
        body: 'Anda menerima pesanan baru dari ${_currentUser!.fullName}.',
        referenceId: newOrder.orderId,
      );

      // Push Notification
      await LocalNotificationService.showNotification(
        id: newOrder.hashCode,
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} sedang diproses oleh penjual.',
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
        widget.onCheckoutComplete();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat checkout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF4E342E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
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
                decoration: const InputDecoration(
                  labelText: 'Nama Penerima',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                maxLines: 3,
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _getCurrentLocationAndFillAddress,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Gunakan Lokasi Saya'),
                ),
              ),
              const SizedBox(height: 8),

              _isFreeShipping
                  ? TextFormField(
                      controller: _courierController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Jasa Kirim',
                        prefixIcon: Icon(
                          Icons.local_shipping,
                          color: Colors.green.shade700,
                        ),
                        filled: true,
                        fillColor: Colors.green[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: selectedCourier,
                      hint: const Text('Pilih Jasa Kirim'),
                      items: courierPrices.keys
                          .map(
                            (courier) => DropdownMenuItem(
                              value: courier,
                              child: Text(
                                '$courier (+\$${courierPrices[courier]})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedCourier = val),
                      validator: (val) =>
                          val == null ? 'Pilih jasa kirim' : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Jasa Kirim',
                      ),
                    ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPayment,
                hint: const Text('Pilih Metode Pembayaran'),
                items: paymentMethods
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedPayment = val),
                validator: (val) =>
                    val == null ? 'Pilih metode pembayaran' : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Metode Pembayaran',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Mata Uang',
                  border: OutlineInputBorder(),
                ),
                items: currencyRates.keys
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedCurrency = val!),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: Text(
                  'Subtotal',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                trailing: Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              ListTile(
                title: Text(
                  'Ongkos Kirim',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                trailing: Text(
                  '\$${courierCost.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _isFreeShipping ? Colors.green : null,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(
                  'Total Pembayaran',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  formattedTotal,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _checkout,
                child: Text(
                  'Bayar Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
