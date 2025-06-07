import 'package:hive/hive.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class OrderService {
  final Box<OrderModel> _orderBox;
  final Box<UserModel> _userBox;

  OrderService(this._orderBox, this._userBox);

  Future<OrderModel> createOrder({
    required String customerUsername,
    required String customerName,
    required String customerAddress,
    required String customerPhoneNumber,
    required List<OrderProductItem> items,
    required double subtotalAmount,
    required String courierService,
    required double courierCost,
    required double totalAmount,
    required String paymentMethod,
    required String selectedCurrency,
    // Kita akan asumsikan semua produk dari seller yang sama atau seller default
    String sellerUsername = 'admin_seller', // Placeholder default seller
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
      orderDate: DateTime.now(),
      status: OrderStatus.paid,
      sellerUsername: sellerUsername, // Menggunakan parameter sellerUsername
    );

    await _orderBox.add(newOrder);
    return newOrder;
  }

  List<OrderModel> getOrdersAsCustomer(String customerUsername) {
    return _orderBox.values
        .where((order) => order.customerUsername == customerUsername)
        .toList();
  }

  List<OrderModel> getOrdersAsSeller(String sellerUsername) {
    return _orderBox.values
        .where((order) => order.sellerUsername == sellerUsername)
        .toList();
  }

  Future<void> updateOrderStatus(
    OrderModel order,
    OrderStatus newStatus,
  ) async {
    order.status = newStatus;
    await order.save();
  }
}
