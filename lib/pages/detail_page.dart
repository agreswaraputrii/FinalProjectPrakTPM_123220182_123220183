import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailPage extends StatefulWidget {
  final ProductModel product;
  final void Function(ProductModel, int) onAddToCart;
  final void Function(ProductModel, bool) onAddToFavorite;

  const DetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onAddToFavorite,
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
    isFavorite = false;
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
    }
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final Color primaryColor = const Color(0xFF4E342E);
    final Color accentColor = const Color(0xFFFF7043);
    final Color priceColor = const Color(0xFF2E7D32);
    final Color discountColor = const Color(0xFFD32F2F);

    double originalPrice = product.price;
    double discount = product.discountPercentage;
    double discountedPrice = product.finalPrice;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          product.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                itemCount: product.images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      product.images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50),
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
            // Kategori dan Rating
            Text(
              "Kategori: ${product.category}",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  "${product.rating}",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(width: 16),
                Text(
                  "Stock: ${product.stock}",
                  style: GoogleFonts.poppins(fontSize: 14),
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
              ),
            ),
            Text(product.description, style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            // Dimensi dan Berat
            Text(
              "Dimensi & Berat",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Dimensi: ${product.dimensions}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              "Berat: ${product.weight} kg",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Tags
            Text(
              "Tags",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              spacing: 8,
              children: product.tags.map((tag) {
                return Chip(
                  label: Text(tag),
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
              ),
            ),
            Text(
              "Garansi: ${product.warrantyInformation}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              "Pengiriman: ${product.shippingInformation}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              "Status: ${product.availabilityStatus}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              "Kebijakan Retur: ${product.returnPolicy}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              "Minimal Pembelian: ${product.minimumOrderQuantity}",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Ulasan
            if (product.reviews.isNotEmpty) ...[
              Text(
                "Ulasan",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ...product.reviews.map((review) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person, color: primaryColor),
                  title: Text(
                    review.reviewerName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.comment),
                      Text("Rating: ${review.rating}/5"),
                      Text("Tanggal: ${review.date}"),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),

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
                    widget.onAddToCart(product, quantity);
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
