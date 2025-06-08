import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  late Box<ProductModel> _productBox;

  List<ProductModel> _apiProducts = [];
  List<ProductModel> _localProducts = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- PERBAIKAN 2: Filter produk langsung di getter ---
  /// Sekarang getter ini secara aktif menyaring semua produk
  /// dan hanya mengembalikan yang kategorinya 'groceries'.
  List<ProductModel> get allProducts {
    // Gabungkan semua produk dari sumber lokal (Hive) dan API
    final all = [..._localProducts, ..._apiProducts];

    // Kembalikan hanya produk yang kategorinya 'groceries'
    return all
        .where((product) => product.category.toLowerCase() == 'groceries')
        .toList();
  }

  ProductProvider() {
    _productBox = Hive.box<ProductModel>('productBox');
    _loadLocalProducts();
    // --- PERBAIKAN 1: Panggil dengan kategori 'groceries' ---
    fetchProducts(
      category: 'groceries',
    ); // Panggil dengan kategori spesifik saat startup
  }

  void _loadLocalProducts() {
    _localProducts = _productBox.values.toList();
    // Tidak perlu notifyListeners() di sini karena fetchProducts akan melakukannya
  }

  Future<void> fetchProducts({String? category = 'groceries'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _apiProducts = await _productService.fetchProducts(category: category);
    } catch (e) {
      _errorMessage = 'Failed to load products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLocalProduct(ProductModel product) async {
    // Pastikan produk yang ditambahkan juga memiliki kategori groceries jika ingin langsung tampil
    // atau biarkan apa adanya dan getter 'allProducts' yang akan menyaringnya.
    await _productBox.put(product.id, product);
    _loadLocalProducts(); // Muat ulang dari Hive agar konsisten
    print('ProductProvider: Local product saved to Hive: ${product.title}');
  }

  Future<bool> updateProduct(String id, ProductModel updatedProduct) async {
    final index = _localProducts.indexWhere((p) => p.id == id);
    if (index != -1) {
      await _productBox.put(id, updatedProduct);
      _loadLocalProducts(); // Muat ulang dari Hive
      return true;
    }
    return false;
  }

  Future<bool> deleteProduct(String productId) async {
    final index = _localProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      await _productBox.delete(productId);
      _loadLocalProducts(); // Muat ulang dari Hive
      return true;
    }
    return false;
  }

  List<ProductModel> getProductsByUploader(String uploaderUsername) {
    // Getter ini juga secara otomatis akan terfilter karena menggunakan 'allProducts'
    return allProducts
        .where((p) => p.uploaderUsername == uploaderUsername)
        .toList();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
