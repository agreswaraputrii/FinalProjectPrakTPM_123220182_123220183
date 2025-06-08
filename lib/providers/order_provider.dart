// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  late OrderService _orderService;
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  OrderProvider() {
    // Inisialisasi service saat provider dibuat
    // Pastikan box sudah dibuka sebelumnya di main.dart atau halaman splash
    final orderBox = Hive.box<OrderModel>('orderBox');
    final userBox = Hive.box<UserModel>('userBox');
    _orderService = OrderService(orderBox, userBox);
    loadOrders(); // Langsung muat data pesanan
  }

  // Getter
  List<OrderModel> get allOrders => _orders;
  bool get isLoading => _isLoading;

  // Method untuk memuat semua pesanan dari Hive
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    
    _orders = _orderService.getAllOrders();
    
    _isLoading = false;
    notifyListeners();
  }

  // Method untuk menambah pesanan baru
  Future<void> addOrder(OrderModel newOrder) async {
    // Simpan ke Hive melalui service
    await _orderService.saveOrder(newOrder);

    // Tambahkan ke list lokal dan beritahu UI untuk update
    _orders.insert(0, newOrder); // Tambah di awal list
    notifyListeners(); // INI BAGIAN PALING PENTING!
  }
  
  // Getter untuk memfilter pesanan sebagai pembeli (customer)
  List<OrderModel> getOrdersForCustomer(String username) {
    return _orders.where((order) => order.customerUsername == username).toList();
  }
  
  // Getter untuk memfilter pesanan sebagai penjual (seller)
  List<OrderModel> getOrdersForSeller(String username) {
    return _orders.where((order) => order.sellerUsername == username).toList();
  }
}