// lib/pages/my_orders_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class MyOrdersPage extends StatelessWidget {
  final String customerUsername;

  const MyOrdersPage({super.key, required this.customerUsername});

  // Helper untuk mendapatkan warna dan teks status
  Map<String, dynamic> _getStatusStyle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return {'color': Colors.orange.shade700, 'text': 'Menunggu Konfirmasi'};
      case OrderStatus.confirmed:
        return {'color': Colors.blue.shade700, 'text': 'Dikonfirmasi'};
      case OrderStatus.processing:
        return {'color': Colors.purple.shade700, 'text': 'Diproses'};
      case OrderStatus.shipped:
        return {'color': Colors.cyan.shade700, 'text': 'Dikirim'};
      case OrderStatus.delivered:
        return {'color': Colors.green.shade700, 'text': 'Selesai'};
      case OrderStatus.cancelled:
        return {'color': Colors.red.shade700, 'text': 'Dibatalkan'};
      default:
        return {'color': Colors.grey, 'text': 'Tidak Diketahui'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Pesanan Saya', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final myOrders = orderProvider.getOrdersForCustomer(customerUsername);

          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (myOrders.isEmpty) {
            return Center(
              child: Text(
                'Anda belum memiliki riwayat pesanan.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: myOrders.length,
            itemBuilder: (context, index) {
              final order = myOrders[index];
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusStyle['color'].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusStyle['text'],
                              style: GoogleFonts.poppins(
                                color: statusStyle['color'],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        'Penjual: ${order.sellerUsername}',
                        style: GoogleFonts.poppins(),
                      ),
                      Text(
                        'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate)}',
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),

                      // --- PERUBAHAN DI SINI: Tombol Konfirmasi Penerimaan ---
                      // Tampilkan tombol ini hanya jika status pesanan adalah "Dikirim"
                      if (order.status == OrderStatus.shipped) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Pesanan Sudah Diterima',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Panggil provider untuk mengubah status menjadi 'delivered'
                              context.read<OrderProvider>().updateOrderStatus(
                                order.orderId,
                                OrderStatus.delivered,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Terima kasih! Status pesanan telah diperbarui.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
}
