import 'package:flutter/material.dart';
import 'package:furniture_store_app/models/product_model.dart';
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
    setState(() {
      widget.cartItems.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checkout berhasil! Keranjang telah dikosongkan.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4E342E);
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cartItem.product.images.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            cartItem.product.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cartItem.product.discountPercentage > 0
                                    ? "\$${cartItem.product.price.toStringAsFixed(2)}"
                                    : '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  decoration:
                                      cartItem.product.discountPercentage > 0
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              Text(
                                "\$${discountedPrice.toStringAsFixed(2)} x ${cartItem.quantity} = \$${totalItemPrice.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                                  if (cartItem.quantity > 1) {
                                    widget.onQuantityChanged(
                                      cartItem,
                                      cartItem.quantity - 1,
                                    );
                                  } else {
                                    widget.onRemoveFromCart(cartItem);
                                  }
                                  setState(() {});
                                },
                              ),
                              Text(
                                '${cartItem.quantity}',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  widget.onQuantityChanged(
                                    cartItem,
                                    cartItem.quantity + 1,
                                  );
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  widget.onRemoveFromCart(cartItem);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${cartItem.product.title} dihapus dari keranjang',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Harga:',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        '\$${totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      minimumSize: const Size.fromHeight(48),
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
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                            cartItems: widget.cartItems,
                            onCheckoutComplete:
                                clearCartAfterCheckout, // ✅ Ganti di sini
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Checkout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
