import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart'; // Untuk mendapatkan currentUser
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  final UserModel currentUser; // Menerima objek user yang sedang login

  const NotificationPage({super.key, required this.currentUser});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late NotificationService _notificationService;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initServiceAndLoadNotifications();
  }

  Future<void> _initServiceAndLoadNotifications() async {
    // Hive Box sudah terbuka
    if (!Hive.isBoxOpen('notificationBox')) {
      await Hive.openBox<NotificationModel>('notificationBox');
    }
    _notificationService = NotificationService(Hive.box<NotificationModel>('notificationBox'));
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _notificationService.getNotificationsForUser(widget.currentUser.username);
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markNotificationAsRead(notification);
      _loadNotifications(); // Reload notifikasi setelah diupdate
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF4E342E);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi', style: GoogleFonts.poppins()),
        backgroundColor: themeColor,
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi saat ini.',
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: notification.isRead ? 2 : 5,
                  color: notification.isRead ? Colors.white : Colors.blue.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      _getNotificationIcon(notification.type),
                      color: notification.isRead ? Colors.grey : themeColor,
                    ),
                    title: Text(
                      notification.title,
                      style: GoogleFonts.poppins(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.body,
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(notification.timestamp),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    trailing: notification.isRead
                        ? null
                        : const Icon(Icons.circle, color: Colors.blue, size: 10), // Indikator belum dibaca
                    onTap: () {
                      _markAsRead(notification);
                      if (notification.referenceId != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Detail pesanan ${notification.referenceId} akan datang!")),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderPaid:
        return Icons.payment;
      case NotificationType.orderShipped:
        return Icons.local_shipping;
      case NotificationType.newOrder:
        return Icons.inbox;
      case NotificationType.orderCompleted:
        return Icons.check_circle;
      case NotificationType.custom:
      default:
        return Icons.notifications;
    }
  }
}