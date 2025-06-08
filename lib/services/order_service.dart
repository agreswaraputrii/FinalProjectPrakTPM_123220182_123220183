// lib/services/order_service.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // Digunakan untuk menghasilkan orderId
import '../models/order_model.dart';
import '../models/user_model.dart'; // Diperlukan jika Anda menyimpan UserModel di Hive dan pass ke OrderService

class OrderService {
  final Box<OrderModel> _orderBox;
  final Box<UserModel>
  _userBox; // Dibiarkan jika Anda memerlukannya untuk fungsionalitas lain

  OrderService(this._orderBox, this._userBox); // Konstruktor

  // Metode untuk membuat pesanan baru
  Future<OrderModel> createOrder({
    required String customerUsername,
    required String customerName,
    required String customerAddress,
    required String customerPhoneNumber,
    required List<OrderProductItem> items, // Menggunakan OrderProductItem
    required double subtotalAmount,
    required String courierService,
    required double courierCost,
    required double totalAmount,
    required String paymentMethod,
    required String selectedCurrency,
    required String sellerUsername, // Seller yang produknya dipesan
  }) async {
    final newOrder = OrderModel(
      customerUsername: customerUsername,
      customerName: customerName,
      customerAddress: customerAddress,
      customerPhoneNumber: customerPhoneNumber,
      items: items,
      subtotalAmount: subtotalAmount,
      courierService: courierService,
      courierCost: courierCost,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      selectedCurrency: selectedCurrency,
      orderDate: DateTime.now(), // Otomatis tanggal dan waktu saat ini
      status: OrderStatus.pending, // Status awal adalah 'Pending'
      sellerUsername: sellerUsername,
    );

    // Hive.put() jika orderId sudah digenerate di konstruktor model
    await _orderBox.put(newOrder.orderId, newOrder);
    print(
      'OrderService: New order created with ID: ${newOrder.orderId} for customer: ${customerUsername}',
    );
    return newOrder;
  }

  // Mendapatkan daftar pesanan di mana pengguna saat ini adalah customer
  List<OrderModel> getOrdersAsCustomer(String customerUsername) {
    return _orderBox.values
        .where((order) => order.customerUsername == customerUsername)
        .toList();
  }

  // Mendapatkan daftar pesanan di mana pengguna saat ini adalah seller
  List<OrderModel> getOrdersAsSeller(String sellerUsername) {
    return _orderBox.values
        .where((order) => order.sellerUsername == sellerUsername)
        .toList();
  }

  // Memperbarui status pesanan
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = _orderBox.get(orderId);
    if (order != null) {
      order.status = newStatus; // Perbarui status
      await order.save(); // Simpan perubahan ke Hive
      print(
        'OrderService: Order ${orderId} status updated to ${newStatus.name}',
      );
    } else {
      print('OrderService: Order with ID ${orderId} not found for update.');
    }
  }

  // Metode opsional: mendapatkan satu pesanan berdasarkan ID
  OrderModel? getOrderById(String orderId) {
    return _orderBox.get(orderId);
  }

  // Untuk debugging: menampilkan semua pesanan
  void debugPrintAllOrders() {
    print('--- All Orders in Hive ---');
    if (_orderBox.isEmpty) {
      print('No orders found.');
      return;
    }
    _orderBox.values.forEach((order) {
      print(
        'Order ID: ${order.orderId.substring(0, 8)}..., Customer: ${order.customerUsername}, Seller: ${order.sellerUsername}, Status: ${order.status.name}, Total: ${order.totalAmount}',
      );
      for (var item in order.items) {
        print('  - Product: ${item.productName}, Qty: ${item.quantity}');
      }
    });
    print('--------------------------');
  }
}
