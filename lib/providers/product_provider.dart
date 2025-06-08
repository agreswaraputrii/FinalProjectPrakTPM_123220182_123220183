import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _apiProducts = []; // dari API groceries
  List<ProductModel> _localProducts = []; // produk yang ditambahkan user

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Semua produk yang akan ditampilkan di UI
  List<ProductModel> get allProducts => [
    // Combine local products (which could be any category) and API groceries
    // Ensure you filter local products too if needed
    ..._localProducts.where(
      (p) => p.category == 'groceries',
    ), // Filter local products too if needed
    ..._apiProducts.where((p) => p.category == 'groceries'),
  ];

  ProductProvider();

  // --- READ / FETCH ---

  Future<void> fetchProducts({String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _apiProducts = await _productService.fetchProducts(category: category);
      print('ProductProvider: Loaded ${_apiProducts.length} API products');
    } catch (e) {
      _errorMessage = 'Failed to load products: ${e.toString()}';
      print('Error in ProductProvider.fetchProducts: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProductModel?> getProductDetail(String id) async {
    // Parameter id harus String
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    ProductModel? product;
    try {
      // First, try to find in local products
      try {
        product = _localProducts.firstWhere((p) => p.id == id);
      } catch (e) {
        // If not found in local, try to find in API products
        try {
          product = _apiProducts.firstWhere((p) => p.id == id);
        } catch (e) {
          // If still not found, set product to null
          product = null;
        }
      }

      if (product == null) {
        _errorMessage = 'Product with ID $id not found.';
        print('Error in ProductProvider.getProductDetail: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Failed to retrieve product detail: ${e.toString()}';
      print('Error in ProductProvider.getProductDetail: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return product;
  }

  // --- CRUD FOR LOCAL ONLY (since dummy API doesn't save) ---

  /// Tambah produk lokal (langsung ke list, tidak ke API)
  void addLocalProduct(ProductModel product) {
    _localProducts.insert(0, product); // tampil di atas
    print('ProductProvider: Local product added: ${product.title}');
    notifyListeners();
  }

  /// **Ini adalah metode updateProduct yang DetailPage dan EditProductPage butuhkan.**
  /// Sekarang menerima `String id`.
  Future<bool> updateProduct(String id, ProductModel updatedProduct) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Coba perbarui di _localProducts dulu
      final index = _localProducts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _localProducts[index] = updatedProduct;
        print(
          'ProductProvider: Local product updated: ${updatedProduct.title}',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Jika tidak ditemukan di lokal, coba perbarui di _apiProducts (cache memori)
        final apiIndex = _apiProducts.indexWhere((p) => p.id == id);
        if (apiIndex != -1) {
          _apiProducts[apiIndex] = updatedProduct;
          print(
            'ProductProvider: API-fetched product (local cache) updated: ${updatedProduct.title}',
          );
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Product with ID $id not found for update.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to update product: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hapus produk lokal
  /// (Metode ini juga digunakan oleh metode deleteProduct umum)
  void deleteLocalProduct(String id) {
    // Parameter id harus String
    _localProducts.removeWhere((p) => p.id == id);
    print('ProductProvider: Local product deleted: ID $id');
    notifyListeners();
  }

  /// Ini adalah metode deleteProduct yang DetailPage butuhkan.
  /// Sekarang menerima `String productId`.
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Coba hapus dari _localProducts dulu
      final initialLocalLength = _localProducts.length;
      _localProducts.removeWhere((product) => product.id == productId);

      if (_localProducts.length < initialLocalLength) {
        // Produk berhasil dihapus dari daftar lokal
        print('ProductProvider: Product with ID $productId deleted locally.');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Jika tidak ditemukan di lokal, coba hapus dari _apiProducts (cache memori)
        final initialApiLength = _apiProducts.length;
        _apiProducts.removeWhere((product) => product.id == productId);

        if (_apiProducts.length < initialApiLength) {
          print(
            'ProductProvider: Product with ID $productId removed from API list (local cache).',
          );
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Product with ID $productId not found to delete.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to delete product: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NEW: Metode untuk mendapatkan produk yang diunggah oleh pengguna tertentu
  List<ProductModel> getProductsByUploader(String uploaderUsername) {
    // Filter dari kedua list (lokal dan API) yang memiliki uploaderUsername
    // Produk dari API DummyJSON tidak akan memiliki uploaderUsername kecuali Anda menambahkannya secara manual
    // Jadi, ini akan efektif memfilter produk yang Anda tambahkan secara lokal
    return allProducts
        .where((p) => p.uploaderUsername == uploaderUsername)
        .toList();
  }

  // --- Utility ---

  Future<void> refreshProducts() async {
    await fetchProducts(category: 'groceries');
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void debugPrintProducts() {
    print('=== Local Products ===');
    for (final p in _localProducts) {
      print(
        'Local: ${p.title} (ID: ${p.id}, Category: ${p.category}, Uploader: ${p.uploaderUsername ?? 'N/A'})',
      );
    }
    print('=== API Products ===');
    for (final p in _apiProducts) {
      print(
        'API: ${p.title} (ID: ${p.id}, Category: ${p.category}, Uploader: ${p.uploaderUsername ?? 'N/A'})',
      );
    }
  }
}
