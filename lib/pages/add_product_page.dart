// lib/pages/add_product_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _thumbnailController = TextEditingController();
  // Anda bisa menambahkan controller lain jika ingin menginput lebih banyak field
  // final _brandController = TextEditingController();
  // final _imagesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      // Buat objek ProductModel baru
      // ID akan di-assign oleh DummyJSON (simulasi), jadi kita beri 0 atau nilai placeholder
      final newProduct = ProductModel(
        id: 0, // ID akan di-assign oleh DummyJSON saat POST
        title: _titleController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        price: double.parse(_priceController.text),
        discountPercentage: 0.0, // Default atau bisa ditambahkan form inputnya
        rating: 0.0, // Default atau bisa ditambahkan form inputnya
        stock: int.parse(_stockController.text),
        tags: [], // Default atau bisa ditambahkan form inputnya (misal, dengan Chip input)
        weight: 0.0, // Default
        dimensions: ProductDimensions(width: 0, height: 0, depth: 0), // Default
        warrantyInformation: '1 Year', // Default
        shippingInformation: 'Free Shipping', // Default
        availabilityStatus: 'In Stock', // Default
        reviews: [], // Default
        returnPolicy: '30 Days Return', // Default
        minimumOrderQuantity: 1, // Default
        images: [_thumbnailController.text], // Untuk saat ini, kita anggap hanya 1 gambar dari thumbnail
        thumbnail: _thumbnailController.text,
        quantity: 1, // Ini untuk keperluan cart, tidak relevan untuk data produk di API
      );

      final success = await productProvider.addProduct(newProduct);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan!')),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan produk: ${productProvider.errorMessage ?? "Terjadi kesalahan"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer atau listen: true digunakan jika Anda ingin UI secara reaktif berubah
    // berdasarkan state loading atau error dari provider.
    final productProvider = Provider.of<ProductProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Produk Baru',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4E342E),
      ),
      body: productProvider.isLoading // Menampilkan loading indicator
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Nama Produk'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama produk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi Produk'),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi produk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kategori tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || double.tryParse(value) == null) {
                          return 'Masukkan harga yang valid';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Masukkan stok yang valid';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _thumbnailController,
                      decoration: const InputDecoration(labelText: 'URL Gambar Thumbnail'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'URL gambar thumbnail tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7043), // accentColor
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Tambah Produk',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (productProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          productProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}