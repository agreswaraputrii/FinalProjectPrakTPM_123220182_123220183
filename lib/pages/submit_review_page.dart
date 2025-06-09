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
    _commentControllers.values.forEach((controller) => controller.dispose());
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
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi semua rating dan ulasan produk.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ulas Pesanan #${widget.order.orderId.substring(0, 8)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...widget.order.items.map((item) => _buildReviewForm(item)).toList(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitAllReviews,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Kirim Semua Ulasan'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm(OrderProductItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Image.network(item.productImageUrl, width: 50),
              title: Text(
                item.productName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            Text('Bagaimana rating Anda?', style: GoogleFonts.poppins()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < _ratings[item.productId]!
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () =>
                      setState(() => _ratings[item.productId] = index + 1),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentControllers[item.productId],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tulis pengalaman Anda...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
