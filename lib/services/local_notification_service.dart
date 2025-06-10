import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Gunakan ikon default aplikasi

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: darwinInitializationSettings,
        );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Method untuk menampilkan notifikasi
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload, 
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'your_channel_id', // ID Channel (harus unik)
          'your_channel_name', // Nama Channel (terlihat di pengaturan HP)
          channelDescription: 'your_channel_description', // Deskripsi
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    // Gabungkan detail notifikasi
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Tampilkan notifikasi
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
