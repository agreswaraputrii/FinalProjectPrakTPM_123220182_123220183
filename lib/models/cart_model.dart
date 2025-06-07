import 'package:hive/hive.dart';

part 'cart_model.g.dart';

@HiveType(typeId: 2)
class CartModel extends HiveObject {
  @HiveField(0)
  final int productId;

  @HiveField(1)
  int quantity;

  CartModel({required this.productId, this.quantity = 1});
}
