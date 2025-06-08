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
  late TextEditingController _discountPercentageController;
  late TextEditingController _ratingController;
  late TextEditingController _stockController;
  late TextEditingController _tagsController;
  late TextEditingController _weightController;
  late TextEditingController _warrantyInformationController;
  late TextEditingController _shippingInformationController;
  late TextEditingController _returnPolicyController;
  late TextEditingController _minimumOrderQuantityController;
  late TextEditingController _thumbnailController;

  // Dropdown for availabilityStatus
  final List<String> _availabilityStatusOptions = [
    'In Stock',
    'Out of Stock',
    'Low Stock',
    'Coming Soon',
  ];
  String? _selectedAvailabilityStatus;

  @override
  void initState() {
    super.initState();
    // Inisialisasi semua controller dengan data produk yang ada
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _categoryController = TextEditingController(text: widget.product.category);
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _discountPercentageController = TextEditingController(
      text: widget.product.discountPercentage.toString(),
    );
    _ratingController = TextEditingController(
      text: widget.product.rating.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _tagsController = TextEditingController(
      text: widget.product.tags.join(', '),
    ); // Join list to string
    _weightController = TextEditingController(
      text: widget.product.weight.toString(),
    );
    _warrantyInformationController = TextEditingController(
      text: widget.product.warrantyInformation,
    );
    _shippingInformationController = TextEditingController(
      text: widget.product.shippingInformation,
    );
    _selectedAvailabilityStatus =
        widget.product.availabilityStatus; // Set initial dropdown value
    _returnPolicyController = TextEditingController(
      text: widget.product.returnPolicy,
    );
    _minimumOrderQuantityController = TextEditingController(
      text: widget.product.minimumOrderQuantity.toString(),
    );
    _thumbnailController = TextEditingController(
      text: widget.product.thumbnail,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _discountPercentageController.dispose();
    _ratingController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    _weightController.dispose();
    _warrantyInformationController.dispose();
    _shippingInformationController.dispose();
    _returnPolicyController.dispose();
    _minimumOrderQuantityController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // Buat objek ProductModel yang diperbarui
      final updatedProduct = ProductModel(
        id: widget.product.id, // ID harus tetap sama untuk operasi UPDATE
        title: _titleController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        price: double.parse(_priceController.text),
        discountPercentage: double.parse(_discountPercentageController.text),
        rating: double.parse(_ratingController.text),
        stock: int.parse(_stockController.text),
        tags: _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        weight: double.parse(_weightController.text),
        // Assume dimensions are not editable on this page, retain original
        dimensions: widget.product.dimensions,
        warrantyInformation: _warrantyInformationController.text,
        shippingInformation: _shippingInformationController.text,
        availabilityStatus: _selectedAvailabilityStatus!,
        // Assume reviews are not editable on this page, retain original
        reviews: widget.product.reviews,
        returnPolicy: _returnPolicyController.text,
        minimumOrderQuantity: int.parse(_minimumOrderQuantityController.text),
        // For images, if you only have a thumbnail input, make sure images list is consistent
        images: _thumbnailController.text.isNotEmpty
            ? [_thumbnailController.text]
            : [],
        thumbnail: _thumbnailController.text,
        quantity: widget
            .product
            .quantity, // Quantity from cart is irrelevant for product edit
      );

      // Call updateProduct on the provider.
      // This method now expects a String ID.
      final success = await productProvider.updateProduct(
        widget.product.id,
        updatedProduct,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diperbarui!')),
        );
        // Pop the page and potentially return the updated product
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
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama produk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Produk',
                      ),
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
                        if (value == null ||
                            value.isEmpty ||
                            double.tryParse(value) == null) {
                          return 'Masukkan harga yang valid';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _discountPercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Diskon (%)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            double.tryParse(value) == null ||
                            double.parse(value) < 0 ||
                            double.parse(value) > 100) {
                          return 'Masukkan diskon yang valid (0-100)';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _ratingController,
                      decoration: const InputDecoration(
                        labelText: 'Rating (0.0 - 5.0)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            double.tryParse(value) == null ||
                            double.parse(value) < 0 ||
                            double.parse(value) > 5) {
                          return 'Masukkan rating yang valid (0.0-5.0)';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null) {
                          return 'Masukkan stok yang valid';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (pisahkan dengan koma)',
                      ),
                    ),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Berat (kg)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            double.tryParse(value) == null ||
                            double.parse(value) < 0) {
                          return 'Masukkan berat yang valid';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _warrantyInformationController,
                      decoration: const InputDecoration(
                        labelText: 'Informasi Garansi',
                      ),
                    ),
                    TextFormField(
                      controller: _shippingInformationController,
                      decoration: const InputDecoration(
                        labelText: 'Informasi Pengiriman',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedAvailabilityStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status Ketersediaan',
                        border: OutlineInputBorder(),
                      ),
                      items: _availabilityStatusOptions
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedAvailabilityStatus = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih status ketersediaan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _returnPolicyController,
                      decoration: const InputDecoration(
                        labelText: 'Kebijakan Retur',
                      ),
                    ),
                    TextFormField(
                      controller: _minimumOrderQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Minimal Order Quantity',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.parse(value) < 1) {
                          return 'Masukkan minimal order quantity yang valid';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _thumbnailController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar Thumbnail',
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Perbarui Produk',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
