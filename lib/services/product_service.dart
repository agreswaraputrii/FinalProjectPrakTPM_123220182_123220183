// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart'; // Sesuaikan path jika berbeda

class ProductService {
  static const String _baseUrl = 'https://dummyjson.com/products';

  // --- READ Operations ---

  /// Mengambil daftar semua produk atau produk berdasarkan kategori jika diberikan.
  /// DummyJSON tidak menyediakan endpoint untuk filtering berdasarkan kategori tertentu
  /// secara langsung di `/products`, melainkan `/products/category/{category_name}`.
  /// Kita akan sesuaikan di sini.
  Future<List<ProductModel>> fetchProducts({String? category}) async {
    final String url;
    if (category != null && category.isNotEmpty) {
      url = '$_baseUrl/category/$category';
    } else {
      url = _baseUrl;
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productList = data['products'];
        return productList.map((json) => ProductModel.fromJsonSafe(json)).toList();
      } else {
        // Tangani error berdasarkan status code
        print('Failed to load products. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load products: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }

  /// Mengambil detail satu produk berdasarkan ID.
  Future<ProductModel> getProductById(int id) async {
    final String url = '$_baseUrl/$id';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProductModel.fromJsonSafe(data);
      } else {
        print('Failed to load product by ID $id. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load product by ID: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching product by ID: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // --- CREATE Operation ---

  /// Menambahkan produk baru.
  /// DummyJSON tidak benar-benar menyimpan data, jadi ini hanya akan mengembalikan
  /// objek produk dengan ID baru (simulasi).
  Future<ProductModel> addProduct(ProductModel product) async {
    final String url = '$_baseUrl/add';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()), // Menggunakan toJson dari model Anda
      );

      if (response.statusCode == 200) { // DummyJSON mengembalikan 200 OK untuk POST
        final Map<String, dynamic> data = json.decode(response.body);
        // DummyJSON akan mengembalikan produk yang ditambahkan dengan ID baru
        return ProductModel.fromJsonSafe(data);
      } else {
        print('Failed to add product. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to add product: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // --- UPDATE Operation ---

  /// Memperbarui produk yang sudah ada.
  /// DummyJSON tidak benar-benar memperbarui data, jadi ini hanya akan mengembalikan
  /// objek produk yang diperbarui (simulasi).
  Future<ProductModel> updateProduct(int id, ProductModel product) async {
    final String url = '$_baseUrl/$id'; // Endpoint UPDATE menggunakan PUT
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()), // Menggunakan toJson dari model Anda
      );

      if (response.statusCode == 200) { // DummyJSON mengembalikan 200 OK untuk PUT
        final Map<String, dynamic> data = json.decode(response.body);
        // DummyJSON akan mengembalikan produk yang diperbarui
        return ProductModel.fromJsonSafe(data);
      } else {
        print('Failed to update product ID $id. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to update product: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // --- DELETE Operation ---

  /// Menghapus produk.
  /// DummyJSON tidak benar-benar menghapus data, jadi ini hanya akan mengembalikan
  /// objek produk yang "dihapus" (simulasi).
  Future<ProductModel> deleteProduct(int id) async {
    final String url = '$_baseUrl/$id';
    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) { // DummyJSON mengembalikan 200 OK untuk DELETE
        final Map<String, dynamic> data = json.decode(response.body);
        // DummyJSON akan mengembalikan produk yang "dihapus"
        return ProductModel.fromJsonSafe(data);
      } else {
        print('Failed to delete product ID $id. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to delete product: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }
}