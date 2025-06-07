import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import semua models Anda
import 'models/user_model.dart';
import 'models/product_model.dart';
import 'models/order_model.dart';
import 'models/notification_model.dart';

import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Inisialisasi Hive Flutter

  // ***** BAGIAN KRUSIAL: DAFTARKAN SEMUA ADAPTER DENGAN TypeId YANG UNIK DAN KONSISTEN *****
  // TypeId 0: UserModel
  // if (!Hive.isAdapterRegistered(0)) { // Cek ini opsional, tapi amannya tetap ada
  Hive.registerAdapter(UserModelAdapter());
  // }

  // TypeId 1: OrderStatus (enum dari order_model.dart)
  // if (!Hive.isAdapterRegistered(1)) {
  Hive.registerAdapter(OrderStatusAdapter());
  // }
  // TypeId 2: OrderProductItem (dari order_model.dart)
  // if (!Hive.isAdapterRegistered(2)) {
  Hive.registerAdapter(OrderProductItemAdapter());
  // }
  // TypeId 3: OrderModel (dari order_model.dart)
  // if (!Hive.isAdapterRegistered(3)) {
  Hive.registerAdapter(OrderModelAdapter());
  // }

  // TypeId 4: NotificationType (enum dari notification_model.dart)
  // if (!Hive.isAdapterRegistered(4)) {
  Hive.registerAdapter(NotificationTypeAdapter());
  // }
  // TypeId 5: NotificationModel (dari notification_model.dart)
  // if (!Hive.isAdapterRegistered(5)) {
  Hive.registerAdapter(NotificationModelAdapter());
  // }

  // TypeId 6: ProductModel (dari product_model.dart)
  // if (!Hive.isAdapterRegistered(6)) {
  Hive.registerAdapter(ProductModelAdapter());
  // }
  // TypeId 7: ProductDimensions (dari product_model.dart)
  // if (!Hive.isAdapterRegistered(7)) {
  Hive.registerAdapter(ProductDimensionsAdapter());
  // }
  // TypeId 8: ProductReview (dari product_model.dart)
  // if (!Hive.isAdapterRegistered(8)) {
  Hive.registerAdapter(ProductReviewAdapter());
  // }
  // ***** AKHIR BAGIAN KRUSIAL *****

  // Buka semua Hive Box yang dibutuhkan di awal aplikasi
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<OrderModel>('orderBox');
  await Hive.openBox<NotificationModel>('notificationBox');
  // Jika Anda menyimpan ProductModel di Hive, buka juga box-nya (opsional):
  // await Hive.openBox<ProductModel>('productBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groceries Store App',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          color: Colors.brown.shade600,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
          labelLarge: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
