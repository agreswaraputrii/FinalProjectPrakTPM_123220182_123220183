// lib/pages/detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider

import '../models/product_model.dart';
import '../models/user_model.dart'; // Import UserModel
import '../providers/product_provider.dart'; // Import ProductProvider
import '../pages/edit_product_page.dart'; // Import EditProductPage

class DetailPage extends StatefulWidget {
  final ProductModel product;
  final void Function(ProductModel, int) onAddToCart;
  final void Function(ProductModel, bool) onAddToFavorite;
  final UserModel currentUser; // Menerima user yang sedang login
  final bool isSeller; // Menerima status seller (dari HomePage)
  final bool isInitialFavorite; // Menerima status favorit awal dari HomePage

  const DetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onAddToFavorite,
    required this.currentUser, // Pastikan ini diterima
    required this.isSeller, // Pastikan ini diterima
    this.isInitialFavorite = false, // Nilai default jika tidak disediakan
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int quantity = 1; // default quantity
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isInitialFavorite; // Inisialisasi dari parameter
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    widget.onAddToFavorite(widget.product, isFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'Produk ditambahkan ke favorit'
              : 'Produk dihapus dari favorit',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void incrementQuantity() {
    if (quantity < widget.product.stock) {
      setState(() {
        quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa menambah, stok sudah maksimal!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah tidak bisa kurang dari 1!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final Color primaryColor = const Color(0xFF4E342E);
    final Color accentColor = const Color(0xFFFF7043);
    final Color priceColor = const Color(0xFF2E7D32);
    final Color discountColor = const Color(0xFFD32F2F);
    final Color textColor = Colors.grey[800]!;

    double originalPrice = product.price;
    double discount = product.discountPercentage;
    double discountedPrice = product.finalPrice;

    // Akses ProductProvider untuk operasi CRUD
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    final bool isOwner =
        product.uploaderUsername != null &&
        product.uploaderUsername == widget.currentUser.username;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          product.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel gambar produk
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: product.images.isNotEmpty
                    ? product.images.length
                    : 1, // Handle empty images list
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                          )
                        : Container(
                            // Placeholder if no images
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Nama Produk
            Text(
              product.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (product.uploaderUsername != null &&
                product.uploaderUsername!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    color: Colors.grey[700],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dijual oleh: ',
                    style: GoogleFonts.poppins(fontSize: 15, color: textColor),
                  ),
                  Text(
                    '${product.uploaderUsername}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accentColor, // Warna oranye agar menonjol
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Kategori dan Rating
            Text(
              "Kategori: ${product.category}",
              style: GoogleFonts.poppins(fontSize: 16, color: textColor),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  "${product.rating.toStringAsFixed(1)}", // Format rating
                  style: GoogleFonts.poppins(fontSize: 16, color: textColor),
                ),
                const SizedBox(width: 16),
                Text(
                  "Stock: ${product.stock}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: product.stock <= 10 && product.stock > 0
                        ? Colors.orange
                        : textColor,
                    fontWeight: product.stock <= 10 && product.stock > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bagian harga dengan diskon
            if (discount > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Harga asli dicoret dengan warna abu-abu
                  Text(
                    '\$${originalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Harga diskon lebih besar dan tebal
                  Text(
                    '\$${discountedPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: priceColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Persentase diskon dalam kotak berwarna menarik
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: discountColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${discount.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              // Jika tidak ada diskon, tampilkan harga biasa dengan simbol $
              Text(
                '\$${originalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: priceColor,
                ),
              ),

            const SizedBox(height: 16),
            // Deskripsi
            Text(
              "Deskripsi",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            Text(
              product.description,
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 12),
            // Dimensi dan Berat
            Text(
              "Dimensi & Berat",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            Text(
              "Dimensi: ${product.dimensions.toString()}", // Pastikan toString di ProductDimensions
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            Text(
              "Berat: ${product.weight} kg",
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 12),
            // Tags
            Text(
              "Tags",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: product.tags.map((tag) {
                return Chip(
                  label: Text(tag, style: GoogleFonts.poppins(fontSize: 12)),
                  backgroundColor: Colors.brown[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Informasi Lain
            Text(
              "Informasi Lain",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            Text(
              "Garansi: ${product.warrantyInformation}",
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            Text(
              "Pengiriman: ${product.shippingInformation}",
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            Text(
              "Status: ${product.availabilityStatus}",
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            Text(
              "Kebijakan Retur: ${product.returnPolicy}",
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            Text(
              "Minimal Pembelian: ${product.minimumOrderQuantity}",
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 12),
            // Ulasan
            if (product.reviews.isNotEmpty) ...[
              Text(
                "Ulasan",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              ...product.reviews.map((review) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person, color: primaryColor),
                  title: Text(
                    review.reviewerName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.comment,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Rating: ${review.rating}/5",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        "Tanggal: ${review.date}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 24),

            // --- Tombol Edit/Delete (Hanya untuk Seller) ---
            if (widget.isSeller && isOwner)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 20.0,
                  top: 20.0, // Tambahkan sedikit jarak atas
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProductPage(product: product),
                            ),
                          ).then((updatedProduct) {
                            if (updatedProduct != null &&
                                updatedProduct is ProductModel) {
                              setState(() {
                                // Rebuild UI jika perlu
                              });
                            }
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: Text(
                          'Edit Produk',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Produk?'),
                              content: Text(
                                'Apakah Anda yakin ingin menghapus "${product.title}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete == true) {
                            // CHANGED: Calling deleteProduct with product.id (which is String)
                            final success = await productProvider.deleteProduct(
                              product.id,
                            );

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Produk berhasil dihapus!'),
                                ),
                              );
                              Navigator.pop(
                                context,
                              ); // Kembali ke halaman sebelumnya (HomePage)
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal menghapus produk: ${productProvider.errorMessage ?? "Terjadi kesalahan"}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Hapus Produk',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 32),
                  onPressed: decrementQuantity,
                  color: Colors.orange,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: Text(
                    quantity.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 32),
                  onPressed: incrementQuantity,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    'Tambah ke Keranjang',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (quantity > product.stock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jumlah melebihi stok yang tersedia'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    widget.onAddToCart(product, quantity); // Panggil callback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$quantity x ${product.title} ditambahkan ke keranjang',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
