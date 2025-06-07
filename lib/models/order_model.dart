import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'order_model.g.dart';

@HiveType(typeId: 1) // ORDER STATUS: TypeId 1
enum OrderStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  paid,
  @HiveField(2)
  shipped,
  @HiveField(3)
  delivered,
  @HiveField(4)
  completed,
  @HiveField(5)
  cancelled,
}

@HiveType(typeId: 2) // ORDER PRODUCT ITEM: TypeId 2
class OrderProductItem extends HiveObject {
  @HiveField(0)
  String productId;
  @HiveField(1)
  String productName;
  @HiveField(2)
  String productImageUrl;
  @HiveField(3)
  double price;
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

  double get discountedPrice => price * (1 - discountPercentage / 100);
  double get subtotal => discountedPrice * quantity;
}

@HiveType(typeId: 3) // ORDER MODEL: TypeId 3
class OrderModel extends HiveObject {
  @HiveField(0)
  String orderId;
  @HiveField(1)
  String customerUsername;
  @HiveField(2)
  String customerName;
  @HiveField(3)
  String customerAddress;
  @HiveField(4)
  String customerPhoneNumber;
  @HiveField(5)
  List<OrderProductItem> items;
  @HiveField(6)
  double subtotalAmount;
  @HiveField(7)
  String courierService;
  @HiveField(8)
  double courierCost;
  @HiveField(9)
  double totalAmount;
  @HiveField(10)
  String paymentMethod;
  @HiveField(11)
  String selectedCurrency;
  @HiveField(12)
  DateTime orderDate;
  @HiveField(13)
  OrderStatus status;
  @HiveField(14)
  String sellerUsername;

  OrderModel({
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
    this.status = OrderStatus.pending,
    required this.sellerUsername,
  })  : orderId = orderId ?? const Uuid().v4(),
        orderDate = orderDate ?? DateTime.now();
}