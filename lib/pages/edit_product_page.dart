// lib/pages/edit_product_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For BackdropFilter

import '../models/product_model.dart';
import '../providers/product_provider.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller disesuaikan dengan AddProductPage
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  late TextEditingController _moqController;
  late TextEditingController _tagsController;

  // Pilihan untuk Dropdown Pengiriman
  final List<String> _shippingOptions = [
    'Pengiriman Reguler',
    'Gratis Ongkir (Free Shipping)',
  ];
  late String _selectedShipping;

  // Skema Warna Konsisten
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.product.description ?? '',
    );
    _priceController = TextEditingController(
      text: (widget.product.price ?? 0.0).toString(),
    );
    _discountController = TextEditingController(
      text: (widget.product.discountPercentage ?? 0.0).toString(),
    );
    _stockController = TextEditingController(
      text: (widget.product.stock ?? 0).toString(),
    );
    _imageUrlController = TextEditingController(
      text: widget.product.thumbnail ?? '',
    );
    _moqController = TextEditingController(
      text: (widget.product.minimumOrderQuantity ?? 1).toString(),
    );
    _tagsController = TextEditingController(
      text: (widget.product.tags ?? []).join(', '),
    );

    _selectedShipping =
        _shippingOptions.contains(widget.product.shippingInformation)
        ? widget.product.shippingInformation!
        : _shippingOptions.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _moqController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final productProvider = context.read<ProductProvider>();
    final stock = int.tryParse(_stockController.text) ?? 0;

    final updatedProduct = ProductModel(
      id: widget.product.id,
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      stock: stock,
      thumbnail: _imageUrlController.text,
      images: [_imageUrlController.text],
      discountPercentage: double.tryParse(_discountController.text) ?? 0.0,
      minimumOrderQuantity: int.tryParse(_moqController.text) ?? 1,
      shippingInformation: _selectedShipping,
      tags: _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((t) => t.isNotEmpty)
          .toList(),

      category: widget.product.category,
      rating: widget.product.rating,
      uploaderUsername: widget.product.uploaderUsername,
      availabilityStatus: stock > 0 ? 'In Stock' : 'Out of Stock',
      reviews: widget.product.reviews,
      weight: widget.product.weight,
      dimensions: widget.product.dimensions,
      warrantyInformation: widget.product.warrantyInformation,
      returnPolicy: widget.product.returnPolicy,
    );

    final success = await productProvider.updateProduct(
      widget.product.id,
      updatedProduct,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedProduct);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui produk: ${productProvider.errorMessage ?? "Terjadi kesalahan"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Produk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [backgroundColor, Colors.white],
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildSectionTitle("Informasi Utama"),
                _buildTextField(
                  _titleController,
                  'Nama Produk*',
                  'Contoh: Apel Fuji Premium',
                ),
                _buildTextField(
                  _descriptionController,
                  'Deskripsi*',
                  'Jelaskan keunggulan produk Anda',
                  maxLines: 4,
                ),
                _buildTextField(
                  _tagsController,
                  'Tags (pisahkan koma)',
                  'Contoh: organik, segar, promo',
                ),

                const SizedBox(height: 24),
                _buildSectionTitle("Harga & Stok"),
                _buildTextField(
                  _priceController,
                  'Harga (USD)*',
                  'Contoh: 4.99',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  _discountController,
                  'Diskon (%)*',
                  'Contoh: 10',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  _stockController,
                  'Jumlah Stok*',
                  'Contoh: 150',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  _moqController,
                  'Minimal Pembelian*',
                  'Contoh: 5',
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 24),
                _buildSectionTitle("Gambar & Pengiriman"),
                _buildTextField(
                  _imageUrlController,
                  'URL Gambar Produk*',
                  'URL gambar utama produk',
                  keyboardType: TextInputType.url,
                ),
                _buildDropdownField(
                  value: _selectedShipping,
                  label: 'Info Pengiriman*',
                  items: _shippingOptions,
                  onChanged: (newValue) {
                    if (newValue != null)
                      setState(() => _selectedShipping = newValue);
                  },
                ),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: productProvider.isLoading ? null : _updateProduct,
                  icon: const Icon(Icons.save_as_outlined),
                  label: Text(
                    productProvider.isLoading
                        ? 'Menyimpan...'
                        : 'Perbarui Produk',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (productProvider.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 12.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: Colors.black87,
        ), // Ensure text input is visible
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[800]),
          hintStyle: GoogleFonts.poppins(),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (value) {
          if (label.endsWith('*') && (value == null || value.isEmpty)) {
            return '${label.replaceAll('*', '')} tidak boleh kosong';
          }
          if (keyboardType == TextInputType.number ||
              keyboardType == TextInputType.url) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null &&
                  keyboardType == TextInputType.number) {
                return 'Masukkan angka yang valid';
              }
            }
          }
          return null;
        },
      ),
    );
  }

  // Helper widget untuk dropdown
  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        // FIX: Menambahkan style dengan warna teks yang jelas
        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[800]),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        validator: (value) => value == null ? 'Pilih salah satu opsi' : null,
      ),
    );
  }
}
