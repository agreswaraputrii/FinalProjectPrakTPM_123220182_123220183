import 'package:hive/hive.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Box<NotificationModel> _notificationBox;

  NotificationService(this._notificationBox);

  // Fungsi untuk menambahkan notifikasi baru
  Future<void> addNotification({
    required String targetUsername,
    required NotificationType type,
    required String title,
    required String body,
    String? referenceId,
  }) async {
    final newNotification = NotificationModel(
      targetUsername: targetUsername,
      type: type,
      title: title,
      body: body,
      referenceId: referenceId,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await _notificationBox.add(newNotification);
  }

  // Fungsi untuk mendapatkan notifikasi untuk pengguna tertentu
  List<NotificationModel> getNotificationsForUser(String username) {
    return _notificationBox.values
        .where((notification) => notification.targetUsername == username)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Urutkan dari terbaru
  }

  // Fungsi untuk menandai notifikasi sebagai sudah dibaca
  Future<void> markNotificationAsRead(NotificationModel notification) async {
    notification.isRead = true;
    await notification.save();
  }

  // Fungsi untuk menghitung jumlah notifikasi yang belum dibaca
  int getUnreadNotificationCount(String username) {
    return _notificationBox.values
        .where((notification) => notification.targetUsername == username && !notification.isRead)
        .length;
  }
}