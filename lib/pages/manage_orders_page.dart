// lib/pages/manage_orders_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart'; // <-- 1. IMPORT PRODUCT PROVIDER

class ManageOrdersPage extends StatelessWidget {
  final String sellerUsername;

  const ManageOrdersPage({super.key, required this.sellerUsername});

  // Helper yang sama dengan halaman riwayat pesanan
  Map<String, dynamic> _getStatusStyle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return {'color': Colors.orange, 'text': 'Menunggu Konfirmasi'};
      case OrderStatus.confirmed:
        return {'color': Colors.blue, 'text': 'Dikonfirmasi'};
      case OrderStatus.processing:
        return {'color': Colors.purple, 'text': 'Diproses'};
      case OrderStatus.shipped:
        return {'color': Colors.cyan, 'text': 'Dikirim'};
      case OrderStatus.delivered:
        return {'color': Colors.green, 'text': 'Selesai'};
      case OrderStatus.cancelled:
        return {'color': Colors.red, 'text': 'Dibatalkan'};
      default:
        return {'color': Colors.grey, 'text': 'Tidak Diketahui'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pesanan Masuk', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFFF6B35), // Warna oranye untuk seller
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final sellerOrders = orderProvider.getOrdersForSeller(sellerUsername);

          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sellerOrders.isEmpty) {
            return Center(
              child: Text(
                'Belum ada pesanan yang masuk.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sellerOrders.length,
            itemBuilder: (context, index) {
              final order = sellerOrders[index];
              final statusStyle = _getStatusStyle(order.status);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.orderId.substring(0, 8)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            statusStyle['text'],
                            style: GoogleFonts.poppins(
                              color: statusStyle['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        'Pembeli: ${order.customerName} (@${order.customerUsername})',
                        style: GoogleFonts.poppins(),
                      ),
                      Text(
                        'Alamat: ${order.customerAddress}',
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Image.network(
                            item.productImageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.image),
                          ),
                          title: Text(item.productName),
                          trailing: Text('x${item.quantity}'),
                        ),
                      ),
                      const Divider(height: 20),

                      // --- Tombol Aksi untuk Penjual ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Ubah Status:', style: GoogleFonts.poppins()),
                          const SizedBox(width: 10),
                          _buildStatusChangeButton(
                            context,
                            orderProvider,
                            order,
                            OrderStatus.confirmed,
                            'Konfirmasi',
                          ),
                          const SizedBox(width: 5),
                          _buildStatusChangeButton(
                            context,
                            orderProvider,
                            order,
                            OrderStatus.shipped,
                            'Kirim',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChangeButton(
    BuildContext context,
    OrderProvider provider,
    OrderModel order,
    OrderStatus newStatus,
    String label,
  ) {
    // Tombol dinonaktifkan jika statusnya sudah sama atau sudah terkirim/selesai
    bool isEnabled =
        order.status != newStatus &&
        order.status != OrderStatus.delivered &&
        order.status != OrderStatus.shipped;

    // Khusus untuk tombol Kirim, baru aktif jika sudah dikonfirmasi/diproses
    if (newStatus == OrderStatus.shipped) {
      isEnabled =
          (order.status == OrderStatus.confirmed ||
          order.status == OrderStatus.processing);
    }

    return ElevatedButton(
      onPressed: isEnabled
          ? () {
              context.read<OrderProvider>().updateOrderStatus(
                order.orderId,
                newStatus,
              );
              if (newStatus == OrderStatus.shipped) {
                context.read<ProductProvider>().reduceStockForOrder(
                  order.items,
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Status pesanan #${order.orderId.substring(0, 8)} diubah menjadi ${newStatus.name}',
                  ),
                ),
              );
            }
          : null, // null akan membuat tombol dinonaktifkan
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
