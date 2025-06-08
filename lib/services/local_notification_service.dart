// lib/services/local_notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  // Buat instance dari plugin notifikasi
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Method untuk inisialisasi
  static Future<void> initialize() async {
    // Pengaturan inisialisasi untuk Android
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Gunakan ikon default aplikasi

    // Pengaturan inisialisasi untuk iOS (jika diperlukan)
    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();

    // Gabungkan pengaturan
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: darwinInitializationSettings,
        );

    // Inisialisasi plugin
    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Method untuk menampilkan notifikasi
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload, // Data tambahan jika diperlukan
  }) async {
    // Detail notifikasi untuk Android
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'your_channel_id', // ID Channel (harus unik)
          'your_channel_name', // Nama Channel (terlihat di pengaturan HP)
          channelDescription: 'your_channel_description', // Deskripsi
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    // Detail notifikasi untuk iOS
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
