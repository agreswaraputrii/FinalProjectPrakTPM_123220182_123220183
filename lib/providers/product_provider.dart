import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../models/order_model.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  late Box<ProductModel> _productBox;

  List<ProductModel> _apiProducts = [];
  List<ProductModel> _localProducts = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// --- PERBAIKAN UTAMA DI SINI ---
  /// Getter ini bertugas untuk menggabungkan produk dari dua sumber:
  /// 1. Produk dari API (DummyJSON).
  /// 2. Produk lokal yang ditambahkan oleh semua penjual (disimpan di Hive).
  /// Keduanya kemudian disaring untuk hanya menampilkan yang berkategori 'groceries'.
  List<ProductModel> get allProducts {
    // Gabungkan semua produk dari sumber lokal dan API menjadi satu daftar besar.
    final combinedList = [..._localProducts, ..._apiProducts];

    // Saring daftar gabungan untuk hanya mengembalikan produk 'groceries'.
    // Ini memastikan halaman utama Anda hanya menampilkan produk yang relevan.
    return combinedList
        .where((product) => product.category.toLowerCase() == 'groceries')
        .toList();
  }

  ProductProvider() {
    _productBox = Hive.box<ProductModel>('productBox');
    _loadLocalProducts(); // Muat produk dari database lokal (Hive)
    fetchProducts(category: 'groceries'); // Ambil produk dari API
  }

  // Memuat produk yang disimpan secara lokal dari database Hive
  void _loadLocalProducts() {
    _localProducts = _productBox.values.toList();
  }

  // Mengambil data produk dari API
  Future<void> fetchProducts({String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _apiProducts = await _productService.fetchProducts(category: category);
    } catch (e) {
      _errorMessage = 'Gagal memuat produk dari server: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menyimpan produk baru ke database Hive
  Future<void> addLocalProduct(ProductModel product) async {
    await _productBox.put(product.id, product);
    _loadLocalProducts(); // Muat ulang daftar produk lokal dari Hive
    notifyListeners(); // Perbarui UI
  }

  // Memperbarui produk yang ada di Hive
  Future<bool> updateProduct(String id, ProductModel updatedProduct) async {
    if (_productBox.containsKey(id)) {
      await _productBox.put(id, updatedProduct);
      _loadLocalProducts();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Menghapus produk dari Hive
  Future<bool> deleteProduct(String productId) async {
    if (_productBox.containsKey(productId)) {
      await _productBox.delete(productId);
      _loadLocalProducts();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> addReview(String productId, ProductReview newReview) async {
    // Cari produk di database lokal
    final productToUpdate = _productBox.get(productId);

    if (productToUpdate != null) {
      // 1. Tambahkan ulasan baru ke daftar ulasan produk
      productToUpdate.reviews.add(newReview);

      // 2. Hitung ulang rata-rata rating
      if (productToUpdate.reviews.isNotEmpty) {
        double totalRating = productToUpdate.reviews
            .map((r) => r.rating)
            .reduce((a, b) => a + b)
            .toDouble();
        double newAverageRating = totalRating / productToUpdate.reviews.length;
        // Batasi hingga 2 angka desimal untuk kebersihan
        productToUpdate.rating = double.parse(
          newAverageRating.toStringAsFixed(2),
        );
      } else {
        // Jika tidak ada review, rating kembali ke 0
        productToUpdate.rating = 0.0;
      }

      // 3. Simpan produk yang sudah diperbarui kembali ke Hive
      await productToUpdate.save();

      // 4. Muat ulang daftar produk lokal dari Hive dan perbarui UI
      _loadLocalProducts();
      notifyListeners();

      print('Review added and rating updated for ${productToUpdate.title}');
    } else {
      print('Product with ID $productId not found in local storage.');
    }
  }

  // Mengurangi stok produk di Hive setelah ada pesanan
  Future<void> reduceStockForOrder(List<OrderProductItem> items) async {
    for (final item in items) {
      final productToUpdate = _productBox.get(item.productId);
      if (productToUpdate != null) {
        final newStock = productToUpdate.stock - item.quantity;
        productToUpdate.stock = newStock < 0 ? 0 : newStock;
        await productToUpdate.save();
      }
    }
    _loadLocalProducts();
    notifyListeners();
  }

  // Mendapatkan produk yang diunggah oleh pengguna tertentu (untuk halaman profil)
  List<ProductModel> getProductsByUploader(String uploaderUsername) {
    return _localProducts
        .where((p) => p.uploaderUsername == uploaderUsername)
        .toList();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
