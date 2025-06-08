// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import semua models Anda
import 'models/user_model.dart';
import 'models/product_model.dart'; // Termasuk ProductDimensions, ProductReview
import 'models/order_model.dart';   // Termasuk OrderStatus, OrderProductItem
import 'models/notification_model.dart'; // Termasuk NotificationType

// Import providers Anda
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';

// Import halaman login Anda
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // --- Daftarkan semua Adapter ---
  // Pastikan setiap TypeId unik dan tidak ada yang sama.
  Hive.registerAdapter(UserModelAdapter());           // TypeId 0
  Hive.registerAdapter(OrderStatusAdapter());         // TypeId 1
  Hive.registerAdapter(OrderProductItemAdapter());    // TypeId 2
  Hive.registerAdapter(OrderModelAdapter());          // TypeId 3
  Hive.registerAdapter(NotificationTypeAdapter());    // TypeId 4
  Hive.registerAdapter(NotificationModelAdapter());   // TypeId 5
  Hive.registerAdapter(ProductModelAdapter());        // TypeId 6 <-- DAFTARKAN INI
  Hive.registerAdapter(ProductDimensionsAdapter());   // TypeId 7 <-- DAFTARKAN INI
  Hive.registerAdapter(ProductReviewAdapter());       // TypeId 8 <-- DAFTARKAN INI

  // --- Buka semua Box yang dibutuhkan ---
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<OrderModel>('orderBox');
  await Hive.openBox<NotificationModel>('notificationBox');
  await Hive.openBox<ProductModel>('productBox'); // <-- PENTING: BUKA BOX UNTUK PRODUK

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groceries Store App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
