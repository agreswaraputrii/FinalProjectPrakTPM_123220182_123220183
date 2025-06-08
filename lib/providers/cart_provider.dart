import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  // CHANGED: Key type of the map changed from int to String
  final Map<String, ProductModel> _items = {};

  // CHANGED: Key type in the getter changed from int to String
  Map<String, ProductModel> get items => {..._items};

  int get itemCount => _items.length;

  double get totalPrice {
    double total = 0.0;
    // No change needed here, as it iterates over values
    _items.forEach((key, product) {
      total += product.price * product.quantity;
    });
    return total;
  }

  void addItem(ProductModel product) {
    // CHANGED: Using product.id (which is String) as the key
    if (_items.containsKey(product.id)) {
      // Kalau sudah ada, tambah quantity
      _items.update(
        product.id, // CHANGED: product.id is now String
        (existingProduct) {
          existingProduct.quantity += 1;
          return existingProduct;
        },
      );
    } else {
      // Kalau belum ada, masukkan baru dengan quantity 1
      _items.putIfAbsent(product.id, () {
        // CHANGED: product.id is now String
        product.quantity = 1;
        return product;
      });
    }
    notifyListeners();
  }

  // CHANGED: parameter productId changed from int to String
  void removeItem(String productId) {
    _items.remove(productId); // CHANGED: productId is now String
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // CHANGED: parameter productId changed from int to String
  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      // CHANGED: productId is now String
      _items[productId]!.quantity += 1;
      notifyListeners();
    }
  }

  // CHANGED: parameter productId changed from int to String
  void decreaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      // CHANGED: productId is now String
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity -= 1;
      } else {
        _items.remove(productId); // CHANGED: productId is now String
      }
      notifyListeners();
    }
  }
}
