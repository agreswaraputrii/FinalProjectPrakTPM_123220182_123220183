// lib/services/order_service.dart

import 'package:hive/hive.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class OrderService {
  final Box<OrderModel> _orderBox;
  final Box<UserModel> _userBox;

  OrderService(this._orderBox, this._userBox);

  // --- METHOD YANG DITAMBAHKAN ---
  /// Method untuk mengambil semua pesanan dari database Hive.
  /// Ini yang akan dipanggil oleh `loadOrders()` di provider.
  List<OrderModel> getAllOrders() {
    final orders = _orderBox.values.toList();
    // Urutkan pesanan dari yang paling baru ke yang paling lama
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return orders;
  }

  // --- METHOD YANG DITAMBAHKAN ---
  /// Method generik untuk menyimpan pesanan ke Hive.
  /// Ini yang akan dipanggil oleh `addOrder()` di provider.
  Future<void> saveOrder(OrderModel newOrder) async {
    // Menggunakan orderId sebagai key unik untuk menyimpan data.
    // ID ini sudah di-generate secara otomatis oleh constructor OrderModel.
    await _orderBox.put(newOrder.orderId, newOrder);
    print('OrderService: Order saved with ID: ${newOrder.orderId}');
  }

  // Method untuk mendapatkan daftar pesanan di mana pengguna saat ini adalah customer
  List<OrderModel> getOrdersAsCustomer(String customerUsername) {
    final orders = _orderBox.values
        .where((order) => order.customerUsername == customerUsername)
        .toList();
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return orders;
  }

  // Method untuk mendapatkan daftar pesanan di mana pengguna saat ini adalah seller
  List<OrderModel> getOrdersAsSeller(String sellerUsername) {
    final orders = _orderBox.values
        .where((order) => order.sellerUsername == sellerUsername)
        .toList();
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return orders;
  }

  // Memperbarui status pesanan (Kode Anda sudah bagus, tidak perlu diubah)
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = _orderBox.get(orderId);
    if (order != null) {
      order.status = newStatus;
      await order.save();
      print(
        'OrderService: Order ${orderId} status updated to ${newStatus.name}',
      );
    } else {
      print('OrderService: Order with ID ${orderId} not found for update.');
    }
  }

  // Metode opsional: mendapatkan satu pesanan berdasarkan ID (Kode Anda sudah bagus)
  OrderModel? getOrderById(String orderId) {
    return _orderBox.get(orderId);
  }

  // Untuk debugging (Kode Anda sudah bagus)
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

  // Method createOrder Anda yang sebelumnya tidak lagi diperlukan karena
  // logikanya sudah dipindahkan ke checkout_page dan provider.
  // Namun, jika Anda masih menggunakannya di tempat lain, Anda bisa membiarkannya.
  // Untuk saat ini, saya hapus agar lebih bersih.
}
