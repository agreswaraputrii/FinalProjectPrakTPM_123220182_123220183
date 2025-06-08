// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- 1. IMPORT PACKAGE

// Import semua models Anda
import 'models/user_model.dart';
import 'models/product_model.dart';
import 'models/order_model.dart';
import 'models/notification_model.dart';

// Import services Anda
import 'services/local_notification_service.dart';

// Import providers Anda
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';

// Import halaman login Anda
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- PERBAIKAN: Minta izin notifikasi saat startup ---
  await _requestNotificationPermission();

  // Inisialisasi service notifikasi lokal
  await LocalNotificationService.initialize();

  // Inisialisasi Hive
  await Hive.initFlutter();

  // --- Daftarkan semua Adapter ---
  // (Pastikan semua TypeId unik)
  Hive.registerAdapter(UserModelAdapter()); // TypeId 0
  Hive.registerAdapter(OrderStatusAdapter()); // TypeId 1
  Hive.registerAdapter(OrderProductItemAdapter()); // TypeId 2
  Hive.registerAdapter(OrderModelAdapter()); // TypeId 3
  Hive.registerAdapter(NotificationTypeAdapter()); // TypeId 4
  Hive.registerAdapter(NotificationModelAdapter()); // TypeId 5
  Hive.registerAdapter(ProductModelAdapter()); // TypeId 6
  Hive.registerAdapter(ProductDimensionsAdapter()); // TypeId 7
  Hive.registerAdapter(ProductReviewAdapter()); // TypeId 8

  // --- Buka semua Box yang dibutuhkan ---
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<OrderModel>('orderBox');
  await Hive.openBox<NotificationModel>('notificationBox');
  await Hive.openBox<ProductModel>('productBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// --- FUNGSI BARU UNTUK MEMINTA IZIN ---
Future<void> _requestNotificationPermission() async {
  // Gunakan package permission_handler untuk meminta izin
  final status = await Permission.notification.request();
  if (status.isGranted) {
    // Izin diberikan
    print("Notification permission granted.");
  } else if (status.isDenied) {
    // Izin ditolak
    print("Notification permission denied.");
  } else if (status.isPermanentlyDenied) {
    // Izin ditolak permanen, arahkan pengguna ke pengaturan
    print("Notification permission permanently denied.");
    openAppSettings();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groceries Store App',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Poppins'),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
