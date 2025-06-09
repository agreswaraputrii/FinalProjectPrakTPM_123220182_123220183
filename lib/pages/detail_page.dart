// lib/pages/detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/product_provider.dart';
import '../pages/edit_product_page.dart';
import '../pages/checkout_page.dart';
import '../pages/cart_page.dart';

class DetailPage extends StatefulWidget {
  final ProductModel product;
  final void Function(ProductModel, int) onAddToCart;
  final void Function(ProductModel, bool) onAddToFavorite;
  final UserModel currentUser;
  final bool isSeller;
  final bool isInitialFavorite;

  const DetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onAddToFavorite,
    required this.currentUser,
    required this.isSeller,
    this.isInitialFavorite = false,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late int quantity;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isInitialFavorite;
    quantity = widget.product.minimumOrderQuantity > 0
        ? widget.product.minimumOrderQuantity
        : 1;
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
      ),
    );
  }

  void incrementQuantity() {
    final moq = widget.product.minimumOrderQuantity > 0
        ? widget.product.minimumOrderQuantity
        : 1;
    final newQuantity = quantity + moq;

    if (newQuantity <= widget.product.stock) {
      setState(() {
        quantity = newQuantity;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa menambah, stok tidak mencukupi!'),
        ),
      );
    }
  }

  void decrementQuantity() {
    final moq = widget.product.minimumOrderQuantity > 0
        ? widget.product.minimumOrderQuantity
        : 1;
    final newQuantity = quantity - moq;

    if (newQuantity >= moq) {
      setState(() {
        quantity = newQuantity;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jumlah tidak bisa kurang dari minimum order ($moq)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer agar UI otomatis update saat rating atau ulasan produk berubah
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Ambil versi produk terbaru dari provider untuk memastikan data selalu fresh
        final product = productProvider.allProducts.firstWhere(
          (p) => p.id == widget.product.id,
          orElse: () =>
              widget.product, // Fallback ke produk awal jika belum ditemukan
        );
        final isOwner = product.uploaderUsername == widget.currentUser.username;
        final Color primaryColor = const Color(0xFF4E342E);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            title: Text(product.title, style: GoogleFonts.poppins()),
            actions: [
              // Pemilik tidak bisa memfavoritkan produknya sendiri
              if (!isOwner)
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
                _buildProductImage(product),
                const SizedBox(height: 16),
                _buildProductHeader(product),
                const Divider(height: 24),
                _buildPriceSection(product),
                const SizedBox(height: 16),
                _buildInfoSection(product),
                const Divider(height: 24),
                _buildDescriptionSection(product),
                const Divider(height: 24),
                _buildReviewSection(product),
                const SizedBox(height: 24),
                if (!isOwner)
                  _buildBuyerActions(product)
                else
                  _buildSellerNotice(),
                if (isOwner) _buildSellerEditDeleteActions(product),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildProductImage(ProductModel product) {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: product.images.isNotEmpty ? product.images.length : 1,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: product.images.isNotEmpty
                ? Image.network(
                    product.images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.broken_image, size: 50),
                  )
                : Container(
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
    );
  }

  Widget _buildProductHeader(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4E342E),
          ),
        ),
        const SizedBox(height: 8),
        if (product.uploaderUsername != null &&
            product.uploaderUsername!.isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.store_mall_directory_outlined,
            label: 'Dijual oleh:',
            value: product.uploaderUsername!,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildPriceSection(ProductModel product) {
    final discountedPrice = product.finalPrice;
    final originalPrice = product.price;
    final discountPercentage = product.discountPercentage;
    final Color priceColor = const Color(0xFF2E7D32);

    if (discountPercentage > 0) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '\$${discountedPrice.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: priceColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${originalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    } else {
      return Text(
        '\$${originalPrice.toStringAsFixed(2)}',
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: priceColor,
        ),
      );
    }
  }

  Widget _buildInfoSection(ProductModel product) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.category_outlined,
          label: 'Kategori:',
          value: product.category,
        ),
        _buildInfoRow(
          icon: Icons.star_border_outlined,
          label: 'Rating:',
          value:
              "${product.rating.toStringAsFixed(1)} / 5.0 (${product.reviews.length} ulasan)",
        ),
        _buildInfoRow(
          icon: Icons.inventory_2_outlined,
          label: 'Stok Tersisa:',
          value: "${product.stock} buah",
        ),
        _buildInfoRow(
          icon: Icons.shopping_basket_outlined,
          label: 'Minimal Pembelian:',
          value: '${product.minimumOrderQuantity} buah',
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.tags.isNotEmpty &&
            !(product.tags.length == 1 && product.tags.first.isEmpty))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tags",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: product.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag, style: GoogleFonts.poppins()),
                        backgroundColor: Colors.green[100],
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                    )
                    .toList(),
              ),
              const Divider(height: 24),
            ],
          ),
        Text(
          "Deskripsi Produk",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildReviewSection(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ulasan Pengguna (${product.reviews.length})",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (product.reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Belum ada ulasan untuk produk ini.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: product.reviews.length,
            itemBuilder: (context, index) {
              final review = product.reviews.reversed.toList()[index];
              return Card(
                elevation: 1,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    review.reviewerName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(review.comment, style: GoogleFonts.poppins()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${review.rating}'),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Text('$label ', style: GoogleFonts.poppins(fontSize: 15)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerActions(ProductModel product) {
    final Color accentColor = const Color(0xFFFF7043);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 32),
              onPressed: decrementQuantity,
              color: Colors.orange.shade700,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
              color: Colors.green.shade700,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (quantity > product.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Jumlah melebihi stok')),
                    );
                    return;
                  }
                  widget.onAddToCart(product, quantity);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor, width: 2),
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                label: Text(
                  'Beli Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                      const SnackBar(content: Text('Jumlah melebihi stok')),
                    );
                    return;
                  }
                  final List<CartItem> buyNowItems = [
                    CartItem(product: product, quantity: quantity),
                  ];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        cartItems: buyNowItems,
                        onCheckoutComplete: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSellerNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Center(
        child: Text(
          'Anda adalah pemilik produk ini. Anda bisa mengedit atau menghapus produk di bawah.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.blueGrey[800]),
        ),
      ),
    );
  }

  Widget _buildSellerEditDeleteActions(ProductModel product) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductPage(product: product),
                ),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Produk'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                      'Anda yakin ingin menghapus "${product.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmDelete == true) {
                  final success = await productProvider.deleteProduct(
                    product.id,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Hapus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
