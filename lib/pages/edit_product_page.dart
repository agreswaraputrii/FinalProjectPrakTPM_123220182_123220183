// lib/pages/edit_product_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product; // Menerima objek produk yang akan diedit

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _thumbnailController;
  // Tambahkan controller lain jika perlu, pastikan juga diisi di initState

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data produk yang ada
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(text: widget.product.description);
    _categoryController = TextEditingController(text: widget.product.category);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _thumbnailController = TextEditingController(text: widget.product.thumbnail);
  }

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

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      // Buat objek ProductModel yang diperbarui
      final updatedProduct = ProductModel(
        id: widget.product.id, // ID harus tetap sama untuk operasi UPDATE
        title: _titleController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        price: double.parse(_priceController.text),
        // Pertahankan nilai lama untuk field yang tidak diedit di form ini
        discountPercentage: widget.product.discountPercentage,
        rating: widget.product.rating,
        stock: int.parse(_stockController.text),
        tags: widget.product.tags,
        weight: widget.product.weight,
        dimensions: widget.product.dimensions,
        warrantyInformation: widget.product.warrantyInformation,
        shippingInformation: widget.product.shippingInformation,
        availabilityStatus: widget.product.availabilityStatus,
        reviews: widget.product.reviews,
        returnPolicy: widget.product.returnPolicy,
        minimumOrderQuantity: widget.product.minimumOrderQuantity,
        // Ini contoh bagaimana Anda bisa mengupdate images.
        // Jika form hanya punya thumbnail, maka images akan hanya berisi thumbnail.
        // Jika ada input untuk multiple images, logikanya akan lebih kompleks.
        images: widget.product.images.isNotEmpty ? List.from(widget.product.images) : [], // Buat salinan list
        thumbnail: _thumbnailController.text,
        quantity: widget.product.quantity, // Quantity dari cart tidak relevan untuk edit produk
      );

      // Pastikan thumbnail juga diperbarui di list images jika images kosong atau hanya satu.
      // Ini bisa disesuaikan dengan kebutuhan Anda.
      if (updatedProduct.images.isEmpty && _thumbnailController.text.isNotEmpty) {
          updatedProduct.images.add(_thumbnailController.text);
      } else if (updatedProduct.images.isNotEmpty) {
          // Jika sudah ada gambar lain, Anda bisa memutuskan apakah thumbnail menggantikan gambar pertama
          // atau hanya memastikan thumbnail ada di daftar.
          // Untuk DummyJSON, biasanya hanya ada 1 thumbnail dan list images terpisah.
          // Jadi mungkin Anda hanya perlu memastikan thumbnail diperbarui.
          // updatedProduct.images[0] = _thumbnailController.text; // Contoh jika thumbnail selalu di index 0
      }


      final success = await productProvider.updateProduct(widget.product.id, updatedProduct);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diperbarui!')),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya (misal DetailPage)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui produk: ${productProvider.errorMessage ?? "Terjadi kesalahan"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Produk',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4E342E),
      ),
      body: productProvider.isLoading
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
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7043), // accentColor
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Perbarui Produk',
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