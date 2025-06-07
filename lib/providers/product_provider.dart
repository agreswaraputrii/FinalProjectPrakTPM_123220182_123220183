// lib/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor (opsional, bisa untuk langsung memuat data saat provider dibuat)
  ProductProvider() {
    fetchProducts();
  }

  // --- Read Operations ---

  Future<void> fetchProducts({String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beri tahu UI bahwa loading dimulai

    try {
      _products = await _productService.fetchProducts(category: category);
    } catch (e) {
      _errorMessage = 'Failed to load products: ${e.toString()}';
      print('Error in ProductProvider.fetchProducts: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners(); // Beri tahu UI bahwa loading selesai atau ada error
    }
  }

  Future<ProductModel?> getProductDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    ProductModel? product;
    try {
      product = await _productService.getProductById(id);
    } catch (e) {
      _errorMessage = 'Failed to load product detail: ${e.toString()}';
      print('Error in ProductProvider.getProductDetail: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return product;
  }

  // --- CRUD Operations for Seller ---

  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProduct = await _productService.addProduct(product);
      // Tambahkan produk baru ke daftar lokal
      _products.add(newProduct);
      return true; // Berhasil
    } catch (e) {
      _errorMessage = 'Failed to add product: ${e.toString()}';
      print('Error in ProductProvider.addProduct: $_errorMessage');
      return false; // Gagal
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(int id, ProductModel updatedProduct) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultProduct = await _productService.updateProduct(id, updatedProduct);
      // Perbarui produk di daftar lokal
      int index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        // Karena DummyJSON mengembalikan produk yang sudah diperbarui dengan ID yang sama,
        // kita bisa langsung mengganti objek di daftar lokal.
        _products[index] = resultProduct;
      }
      return true; // Berhasil
    } catch (e) {
      _errorMessage = 'Failed to update product: ${e.toString()}';
      print('Error in ProductProvider.updateProduct: $_errorMessage');
      return false; // Gagal
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // DummyJSON mengembalikan produk yang dihapus.
      // Kita tidak perlu menyimpan objek yang dikembalikan, cukup konfirmasi bahwa operasi berhasil.
      await _productService.deleteProduct(id);
      // Hapus produk dari daftar lokal
      _products.removeWhere((product) => product.id == id);
      return true; // Berhasil
    } catch (e) {
      _errorMessage = 'Failed to delete product: ${e.toString()}';
      print('Error in ProductProvider.deleteProduct: $_errorMessage');
      return false; // Gagal
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Untuk menghapus pesan error setelah ditampilkan
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}