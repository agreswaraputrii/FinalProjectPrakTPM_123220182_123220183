// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import semua models Anda
import 'models/user_model.dart';
import 'models/product_model.dart'; // Termasuk ProductDimensions, ProductReview
import 'models/order_model.dart'; // Termasuk OrderStatus, OrderProductItem
import 'models/notification_model.dart'; // Termasuk NotificationType

// Import providers Anda
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart'; // NEW: Import CartProvider

// Import halaman login Anda (ini akan menjadi halaman awal aplikasi)
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // ***** BAGIAN KRUSIAL: DAFTARKAN SEMUA ADAPTER DENGAN TypeId YANG UNIK DAN KONSISTEN *****
  // Pastikan typeId tidak bertabrakan!
  // Anda sudah menggunakannya dengan baik di model Anda (0,1,2,3,4,5,6,7,8)
  // Tidak perlu if (!Hive.isAdapterRegistered(X)) karena Hive akan menangani ini jika dijalankan clean.
  Hive.registerAdapter(UserModelAdapter()); // TypeId 0
  Hive.registerAdapter(OrderStatusAdapter()); // TypeId 1
  Hive.registerAdapter(OrderProductItemAdapter()); // TypeId 2
  Hive.registerAdapter(OrderModelAdapter()); // TypeId 3
  Hive.registerAdapter(NotificationTypeAdapter()); // TypeId 4
  Hive.registerAdapter(NotificationModelAdapter()); // TypeId 5
  Hive.registerAdapter(ProductModelAdapter()); // TypeId 6
  Hive.registerAdapter(ProductDimensionsAdapter()); // TypeId 7
  Hive.registerAdapter(ProductReviewAdapter()); // TypeId 8


  // Pastikan Hive Box sudah terbuka untuk semua model yang digunakan
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<OrderModel>('orderBox');
  await Hive.openBox<NotificationModel>('notificationBox');
  // Jika Anda menyimpan ProductModel di Hive, buka juga box-nya (opsional):
  // Ini penting jika Anda memanipulasi _localProducts dan ingin mereka persisten
  await Hive.openBox<ProductModel>('productBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()), // NEW: Daftarkan CartProvider
      ],
      child: const MyApp(),
    ),
  );
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
        appBarTheme: const AppBarTheme(
          color: Color(0xFF4E342E), // primaryColor
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