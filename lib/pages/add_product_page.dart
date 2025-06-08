// lib/pages/add_product_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/product_model.dart';
import '../models/user_model.dart'; // Import UserModel
import '../providers/product_provider.dart';

class AddProductPage extends StatefulWidget {
  final UserModel? currentUser; // Menerima objek user yang sedang login

  const AddProductPage({super.key, this.currentUser});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  // final _categoryController = TextEditingController(text: 'groceries'); // REMOVED: No longer needed for dropdown
  final _priceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _ratingController = TextEditingController();
  final _stockController = TextEditingController();
  final _tagsController = TextEditingController();
  final _weightController = TextEditingController();
  final _warrantyInformationController = TextEditingController();
  final _shippingInformationController = TextEditingController();
  final _returnPolicyController = TextEditingController();
  final _thumbnailController = TextEditingController();

  int _minimumOrderQuantity = 1;

  // Dropdown options
  final List<String> _availabilityStatusOptions = [
    'In Stock',
    'Out of Stock',
    'Low Stock',
    'Coming Soon',
  ];
  String? _selectedAvailabilityStatus;

  // NEW: Category options - only 'groceries'
  final List<String> _categoryOptions = ['groceries'];
  String?
  _selectedCategory; // Holds the selected category, defaults to 'groceries'

  final List<String> _weightUnitOptions = ['g', 'kg', 'ml', 'L', 'pcs'];
  String? _selectedWeightUnit = 'kg';

  final List<String> _warrantyOptions = [
    'No Warranty',
    '1 Year Local Supplier Warranty',
    '2 Years Manufacturer Warranty',
    '3 Months Shop Warranty',
    'Lifetime Warranty',
  ];
  String? _selectedWarranty = 'No Warranty';

  final List<String> _returnPolicyOptions = [
    'No Returns Accepted',
    '7 Days Return Policy',
    '14 Days Return Policy',
    '30 Days Return Policy',
    'Free Returns',
  ];
  String? _selectedReturnPolicy = 'No Returns Accepted';

  // Define colors at the class level
  final Color primaryColor = const Color(0xFF4E342E);
  final Color accentColor = const Color(0xFFFF7043);
  final Color backgroundColor = const Color(0xFFF1F8E9);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _discountPercentageController.text = '0.0';
    _ratingController.text = '0.0';
    _stockController.text = '0';
    _selectedAvailabilityStatus = 'In Stock';
    _selectedCategory = 'groceries'; // Initialize category to 'groceries'
    _weightController.text = '0.0';
    _warrantyInformationController.text =
        _selectedWarranty!; // Initialize with default selected option
    _shippingInformationController.text = 'Free Shipping';
    _returnPolicyController.text =
        _selectedReturnPolicy!; // Initialize with default selected option
    _minimumOrderQuantity = 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // _categoryController.dispose(); // REMOVED: No longer needed
    _priceController.dispose();
    _discountPercentageController.dispose();
    _ratingController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    _weightController.dispose();
    _warrantyInformationController.dispose();
    _shippingInformationController.dispose();
    _returnPolicyController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (widget.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not logged in to add product.'),
          ),
        );
        return;
      }

      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      const uuid = Uuid();

      final newProduct = ProductModel(
        id: uuid.v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        thumbnail: _thumbnailController.text,
        category: _selectedCategory!, // Use selected category from dropdown
        discountPercentage: double.parse(
          _discountPercentageController.text.isEmpty
              ? '0.0'
              : _discountPercentageController.text,
        ),
        rating: double.parse(
          _ratingController.text.isEmpty ? '0.0' : _ratingController.text,
        ),
        stock: int.parse(
          _stockController.text.isEmpty ? '0' : _stockController.text,
        ),
        tags: _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        weight: double.parse(
          _weightController.text.isEmpty ? '0.0' : _weightController.text,
        ),
        dimensions: ProductDimensions(width: 0, height: 0, depth: 0),
        warrantyInformation: _selectedWarranty!,
        shippingInformation: _shippingInformationController.text,
        availabilityStatus: _selectedAvailabilityStatus!,
        reviews: const [],
        returnPolicy: _selectedReturnPolicy!,
        minimumOrderQuantity: _minimumOrderQuantity,
        images: [_thumbnailController.text],
        quantity: 1,
        uploaderUsername: widget.currentUser!.username,
      );

      productProvider.addLocalProduct(newProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan secara lokal!'),
        ),
      );

      Navigator.pop(context);
    }
  }

  void _updateQuantity(int delta) {
    setState(() {
      _minimumOrderQuantity = (_minimumOrderQuantity + delta).clamp(1, 9999);
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        readOnly: readOnly,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String labelText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              Colors.white,
              backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: productProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Product Details Card
                      _buildCard(
                        title: "Detail Produk",
                        children: [
                          _buildTextField(
                            controller: _titleController,
                            labelText: 'Nama Produk',
                            validator: (value) => value!.isEmpty
                                ? 'Nama produk tidak boleh kosong'
                                : null,
                          ),
                          _buildTextField(
                            controller: _descriptionController,
                            labelText: 'Deskripsi Produk',
                            maxLines: 3,
                            validator: (value) => value!.isEmpty
                                ? 'Deskripsi produk tidak boleh kosong'
                                : null,
                          ),
                          // CATEGORY AS DROPDOWN (ONLY GROCERIES)
                          _buildDropdownField<String>(
                            value: _selectedCategory,
                            labelText: 'Kategori',
                            items: _categoryOptions.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              // Only 'groceries' is an option, so this will always be 'groceries'
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Kategori tidak boleh kosong'
                                : null,
                          ),
                          _buildTextField(
                            controller: _priceController,
                            labelText: 'Harga',
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              ),
                            ],
                            hintText: 'Contoh: 12.99 (USD)',
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Harga tidak boleh kosong';
                              if (double.tryParse(value) == null)
                                return 'Masukkan harga yang valid';
                              if (double.parse(value) <= 0)
                                return 'Harga harus lebih besar dari 0';
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _discountPercentageController,
                            labelText: 'Diskon (%)',
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Diskon tidak boleh kosong';
                              final discount = double.tryParse(value);
                              if (discount == null ||
                                  discount < 0 ||
                                  discount > 100)
                                return 'Masukkan diskon yang valid (0-100)';
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _ratingController,
                            labelText: 'Rating (0.0 - 5.0)',
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Rating tidak boleh kosong';
                              final rating = double.tryParse(value);
                              if (rating == null || rating < 0 || rating > 5)
                                return 'Masukkan rating yang valid (0.0-5.0)';
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _stockController,
                            labelText: 'Stok',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Stok tidak boleh kosong';
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 0)
                                return 'Masukkan stok yang valid';
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: _tagsController,
                            labelText: 'Tags (pisahkan dengan koma)',
                            hintText: 'Contoh: organik, segar, buah',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Additional Information Card
                      _buildCard(
                        title: "Informasi Tambahan",
                        children: [
                          _buildDropdownField<String>(
                            value: _selectedAvailabilityStatus,
                            labelText: 'Status Ketersediaan',
                            items: _availabilityStatusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedAvailabilityStatus = newValue;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Pilih status ketersediaan'
                                : null,
                          ),
                          // Weight input with unit selection
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _weightController,
                                  labelText: 'Berat',
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*$'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Berat tidak boleh kosong';
                                    if (double.tryParse(value) == null ||
                                        double.parse(value) < 0)
                                      return 'Masukkan berat yang valid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 100, // Fixed width for dropdown
                                child: _buildDropdownField<String>(
                                  value: _selectedWeightUnit,
                                  labelText: 'Unit',
                                  items: _weightUnitOptions.map((unit) {
                                    return DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedWeightUnit = newValue;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Pilih unit'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          _buildDropdownField<String>(
                            value: _selectedWarranty,
                            labelText: 'Informasi Garansi',
                            items: _warrantyOptions.map((warranty) {
                              return DropdownMenuItem(
                                value: warranty,
                                child: Text(warranty),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedWarranty = newValue;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Pilih garansi'
                                : null,
                          ),
                          _buildDropdownField<String>(
                            value: _selectedReturnPolicy,
                            labelText: 'Kebijakan Retur',
                            items: _returnPolicyOptions.map((policy) {
                              return DropdownMenuItem(
                                value: policy,
                                child: Text(policy),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedReturnPolicy = newValue;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Pilih kebijakan retur'
                                : null,
                          ),
                          // Min Order Quantity with buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minimal Order Quantity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[50],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove,
                                          color: accentColor,
                                        ),
                                        onPressed: () => _updateQuantity(-1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Text(
                                        '$_minimumOrderQuantity',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add,
                                          color: accentColor,
                                        ),
                                        onPressed: () => _updateQuantity(1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Image Thumbnail Card
                      _buildCard(
                        title: "Gambar Produk",
                        children: [
                          _buildTextField(
                            controller: _thumbnailController,
                            labelText: 'URL Gambar Thumbnail',
                            keyboardType: TextInputType.url,
                            hintText: 'Contoh: https://example.com/image.jpg',
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'URL gambar tidak boleh kosong';
                              final uri = Uri.tryParse(value);
                              if (uri == null || !uri.hasAbsolutePath)
                                return 'URL tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          // Image preview with shadow
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _thumbnailController.text.isNotEmpty
                                ? Image.network(
                                    _thumbnailController.text,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _submitProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            shadowColor: Colors.black.withOpacity(0.2),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: Text(
                            'Tambah Produk',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const Divider(height: 30, thickness: 1.5, color: Colors.grey),
          ...children,
        ],
      ),
    );
  }
}
