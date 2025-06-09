// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/order_service.dart';
import '../services/local_notification_service.dart';

class OrderProvider with ChangeNotifier {
  late OrderService _orderService;
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  OrderProvider() {
    final orderBox = Hive.box<OrderModel>('orderBox');
    final userBox = Hive.box<UserModel>('userBox');
    _orderService = OrderService(orderBox, userBox);
    loadOrders();
  }

  List<OrderModel> get allOrders => _orders;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    _orders = _orderService.getAllOrders();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addOrder(OrderModel newOrder) async {
    await _orderService.saveOrder(newOrder);
    _orders.insert(0, newOrder);
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _orderService.updateOrderStatus(orderId, newStatus);
    final index = _orders.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      _orders[index].status = newStatus;

      String notificationTitle = 'Status Pesanan Berubah';
      String notificationBody =
          'Status pesanan #${orderId.substring(0, 8)} Anda telah diperbarui.';

      switch (newStatus) {
        case OrderStatus.confirmed:
          notificationBody = 'Pesanan Anda telah dikonfirmasi oleh penjual.';
          break;
        case OrderStatus.shipped:
          notificationBody = 'Kabar baik! Pesanan Anda telah dikirim.';
          break;
        case OrderStatus.delivered:
          notificationTitle = 'Pesanan Telah Tiba!';
          notificationBody = 'Jangan lupa konfirmasi penerimaan pesanan Anda.';
          break;
        default:
          break;
      }

      await LocalNotificationService.showNotification(
        id: orderId.hashCode,
        title: notificationTitle,
        body: notificationBody,
      );

      notifyListeners();
    }
  }

  // --- METHOD YANG DITAMBAHKAN UNTUK MENGATASI ERROR ---
  Future<void> markOrderAsReviewed(String orderId) async {
    // Panggil service untuk mendapatkan order berdasarkan ID
    final order = _orderService.getOrderById(orderId);
    if (order != null) {
      // Ubah status ulasan menjadi true
      order.hasBeenReviewed = true;
      // Simpan perubahan ke database Hive
      await order.save();

      // Perbarui juga state di dalam list provider agar UI langsung reaktif
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _orders[index].hasBeenReviewed = true;
        notifyListeners();
      }
    }
  }

  List<OrderModel> getOrdersForCustomer(String username) {
    return _orders
        .where((order) => order.customerUsername == username)
        .toList();
  }

  List<OrderModel> getOrdersForSeller(String username) {
    return _orders.where((order) => order.sellerUsername == username).toList();
  }
}
