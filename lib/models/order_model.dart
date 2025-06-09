// lib/models/order_model.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // Digunakan untuk menghasilkan orderId jika tidak disediakan

part 'order_model.g.dart'; // Hive generator akan membuat file ini

@HiveType(
  typeId: 1,
) // ORDER STATUS: TypeId 1. Pastikan unik di seluruh aplikasi
enum OrderStatus {
  @HiveField(0)
  pending, // Menunggu konfirmasi/pembayaran
  @HiveField(1)
  confirmed, // Pesanan dikonfirmasi
  @HiveField(2)
  processing, // Sedang diproses / dikemas
  @HiveField(3)
  shipped, // Sudah dikirim
  @HiveField(4)
  delivered, // Sudah diterima pembeli
  @HiveField(5)
  cancelled, // Pesanan dibatalkan
}

@HiveType(typeId: 2) // ORDER PRODUCT ITEM: TypeId 2. Pastikan unik
class OrderProductItem extends HiveObject {
  @HiveField(0)
  String productId; // ID produk (dari ProductModel)
  @HiveField(1)
  String productName;
  @HiveField(2)
  String productImageUrl;
  @HiveField(3)
  double price; // Harga per unit
  @HiveField(4)
  double discountPercentage;
  @HiveField(5)
  int quantity;

  OrderProductItem({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.price,
    required this.discountPercentage,
    required this.quantity,
  });

  // Getter untuk harga setelah diskon per unit
  double get discountedPricePerUnit => price * (1 - discountPercentage / 100);

  // Getter untuk subtotal item ini (harga setelah diskon * quantity)
  double get subtotal => discountedPricePerUnit * quantity;
}

@HiveType(typeId: 3) // ORDER MODEL: TypeId 3. Pastikan unik
class OrderModel extends HiveObject {
  @HiveField(0)
  String orderId; // ID unik untuk pesanan
  @HiveField(1)
  String customerUsername; // Username pembeli
  @HiveField(2)
  String customerName; // Nama lengkap pembeli
  @HiveField(3)
  String customerAddress; // Alamat pengiriman
  @HiveField(4)
  String customerPhoneNumber; // Nomor telepon pembeli
  @HiveField(5)
  List<OrderProductItem> items; // Daftar produk yang dipesan
  @HiveField(6)
  double subtotalAmount; // Total harga item (sebelum ongkir, setelah diskon)
  @HiveField(7)
  String courierService; // Layanan kurir
  @HiveField(8)
  double courierCost; // Biaya kurir
  @HiveField(9)
  double totalAmount; // Total keseluruhan (subtotal + ongkir)
  @HiveField(10)
  String paymentMethod; // Metode pembayaran
  @HiveField(11)
  String selectedCurrency; // Mata uang yang dipilih
  @HiveField(12)
  DateTime orderDate; // Tanggal dan waktu pesanan dibuat
  @HiveField(13)
  OrderStatus status; // Status pesanan (menggunakan enum OrderStatus)
  @HiveField(14)
  String sellerUsername; // Username penjual (asumsi satu penjual per order)
  @HiveField(15, defaultValue: false)
  bool hasBeenReviewed;

  OrderModel({
    // orderId dan orderDate bisa di-generate otomatis jika tidak disediakan
    String? orderId,
    required this.customerUsername,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhoneNumber,
    required this.items,
    required this.subtotalAmount,
    required this.courierService,
    required this.courierCost,
    required this.totalAmount,
    required this.paymentMethod,
    required this.selectedCurrency,
    DateTime? orderDate,
    this.status = OrderStatus.pending, // Default status saat order dibuat
    required this.sellerUsername, // Seller yang terkait dengan pesanan
    this.hasBeenReviewed = false, // Nilai default saat order dibuat
  }) : orderId =
           orderId ?? const Uuid().v4(), // Generate UUID jika tidak ada ID
       orderDate =
           orderDate ??
           DateTime.now(); // Gunakan waktu saat ini jika tidak ada tanggal
}
