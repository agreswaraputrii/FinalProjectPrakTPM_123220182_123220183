import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritePage extends StatefulWidget {
  final List<ProductModel> favoriteProducts;

  const FavoritePage({super.key, required this.favoriteProducts});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  void removeFromFavorites(ProductModel product) {
    setState(() {
      widget.favoriteProducts.remove(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} dihapus dari favorit'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4E342E);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Favorit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: widget.favoriteProducts.isEmpty
          ? Center(
              child: Text(
                'Belum ada produk favorit',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = widget.favoriteProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.images.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      product.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "\$${product.price.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(color: Colors.green[700]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => removeFromFavorites(product),
                    ),
                    onTap: () {
                      // Bisa tambahkan navigasi ke DetailPage jika mau
                    },
                  ),
                );
              },
            ),
    );
  }
}
