import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, ProductModel> _items = {};

  Map<String, ProductModel> get items => {..._items};

  int get itemCount => _items.length;

  double get totalPrice {
    double total = 0.0;
    _items.forEach((key, product) {
      total += product.price * product.quantity;
    });
    return total;
  }

  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      // Kalau sudah ada, tambah quantity
      _items.update(
        product.id,
        (existingProduct) {
          existingProduct.quantity += 1;
          return existingProduct;
        },
      );
    } else {
      // Kalau belum ada, masukkan baru dengan quantity 1
      _items.putIfAbsent(product.id, () {
        product.quantity = 1;
        return product;
      });
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity -= 1;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }
}
