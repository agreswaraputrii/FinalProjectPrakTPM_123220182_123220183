// lib/pages/submit_review_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';

class SubmitReviewPage extends StatefulWidget {
  final OrderModel order;
  final UserModel currentUser;

  const SubmitReviewPage({
    super.key,
    required this.order,
    required this.currentUser,
  });

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.order.items) {
      _ratings[item.productId] = 0;
      _commentControllers[item.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitAllReviews() {
    final productProvider = context.read<ProductProvider>();
    final orderProvider = context.read<OrderProvider>();

    bool allReviewed = true;

    for (var item in widget.order.items) {
      final rating = _ratings[item.productId]!;
      final comment = _commentControllers[item.productId]!.text;

      if (rating == 0 || comment.isEmpty) {
        allReviewed = false;
        break;
      }

      final newReview = ProductReview(
        rating: rating,
        comment: comment,
        date: DateFormat(
          "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        ).format(DateTime.now().toUtc()),
        reviewerName: widget.currentUser.fullName,
        reviewerEmail: widget.currentUser.email,
      );

      productProvider.addReview(item.productId, newReview);
    }

    if (allReviewed) {
      orderProvider.markOrderAsReviewed(widget.order.orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih atas ulasan Anda!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Make it floating
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi semua rating dan ulasan produk.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // Make it floating
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ulas Pesanan #${widget.order.orderId.substring(0, 8)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, // Make app bar title bolder
          ),
        ),
        backgroundColor: Colors.white, // White app bar for a cleaner look
        elevation: 0.5, // Subtle shadow for app bar
        foregroundColor: Colors.black87, // Darker text for app bar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Bagikan pengalaman Anda dengan produk di pesanan ini.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          ...widget.order.items.map((item) => _buildReviewForm(item)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitAllReviews,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.deepPurple, // A more vibrant button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              elevation: 3, // Subtle shadow for the button
            ),
            child: Text(
              'Kirim Ulasan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm(OrderProductItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Softer card edges
      ),
      elevation: 2, // A bit more elevation for the card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
          children: [
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8), // Rounded image corners
                child: Image.network(
                  item.productImageUrl,
                  width: 60, // Slightly larger image
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                item.productName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 17, // Slightly larger product name
                ),
              ),
              subtitle: Text(
                'Jumlah: ${item.quantity}', // Show quantity
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 20, thickness: 1), // Thicker divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Bagaimana rating Anda untuk produk ini?', // More specific question
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < _ratings[item.productId]!
                        ? Icons
                              .star_rounded // Use rounded stars
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 38, // Larger stars
                  ),
                  onPressed: () =>
                      setState(() => _ratings[item.productId] = index + 1),
                  splashRadius: 28, // Adjust splash radius for stars
                ),
              ),
            ),
            const SizedBox(height: 16), // Increased spacing
            TextField(
              controller: _commentControllers[item.productId],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded text field
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ), // Highlight on focus
                ),
                labelText:
                    'Tulis ulasan Anda di sini...', // More inviting label
                labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                alignLabelWithHint: true, // Align label to top for multiline
              ),
              maxLines: 4, // Allow more lines for comment
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization
                  .sentences, // Capitalize first letter of sentences
            ),
          ],
        ),
      ),
    );
  }
}
