// lib/pages/cart_page.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/checkout_page.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final void Function(CartItem) onRemoveFromCart;
  final void Function(CartItem, int) onQuantityChanged;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onQuantityChanged,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  double priceAfterDiscount(ProductModel product) {
    return product.price * (1 - product.discountPercentage / 100);
  }

  double get totalPrice {
    return widget.cartItems.fold(
      0,
      (sum, item) => sum + priceAfterDiscount(item.product) * item.quantity,
    );
  }

  void clearCartAfterCheckout() {
    // Callback ini akan dipanggil dari checkout_page
    // untuk membersihkan keranjang di state induk (HomePage)
    for (var item in List.from(widget.cartItems)) {
      widget.onRemoveFromCart(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2E7D32);
    final Color accentColor = const Color(0xFFFF7043);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Keranjang',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Text(
                'Keranjang kosong',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = widget.cartItems[index];
                      final discountedPrice = priceAfterDiscount(
                        cartItem.product,
                      );
                      final totalItemPrice =
                          discountedPrice * cartItem.quantity;
                      // Dapatkan MOQ produk, default ke 1 jika tidak valid
                      final int moq = cartItem.product.minimumOrderQuantity > 0
                          ? cartItem.product.minimumOrderQuantity
                          : 1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cartItem.product.thumbnail,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.image_not_supported,
                                size: 40,
                              ),
                            ),
                          ),
                          title: Text(
                            cartItem.product.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "\$${discountedPrice.toStringAsFixed(2)} x ${cartItem.quantity}",
                            style: GoogleFonts.poppins(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  final newQuantity = cartItem.quantity - moq;
                                  if (newQuantity < moq) {
                                    widget.onRemoveFromCart(cartItem);
                                  } else {
                                    widget.onQuantityChanged(
                                      cartItem,
                                      newQuantity,
                                    );
                                  }
                                  setState(() {});
                                },
                              ),
                              Text(
                                '${cartItem.quantity}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  final newQuantity = cartItem.quantity + moq;
                                  if (newQuantity <= cartItem.product.stock) {
                                    widget.onQuantityChanged(
                                      cartItem,
                                      newQuantity,
                                    );
                                    setState(() {});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Stok tidak mencukupi!'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // --- Container Total Harga dan Tombol Checkout ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Harga:',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (widget.cartItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Keranjang kosong, tidak bisa checkout',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutPage(
                                  cartItems: widget.cartItems,
                                  onCheckoutComplete: clearCartAfterCheckout,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Checkout',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
