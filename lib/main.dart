// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import semua models Anda
import 'models/user_model.dart';
import 'models/product_model.dart';
import 'models/order_model.dart';
import 'models/notification_model.dart';

// Import providers Anda
import 'providers/product_provider.dart';

// Import halaman-halaman untuk testing
// import 'pages/login_page.dart'; // Ini home page asli Anda
import 'pages/add_product_page.dart'; // Untuk testing Add
import 'pages/edit_product_page.dart'; // Untuk testing Edit

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // ***** BAGIAN KRUSIAL: DAFTARKAN SEMUA ADAPTER DENGAN TypeId YANG UNIK DAN KONSISTEN *****
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(OrderStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(OrderProductItemAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(OrderModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(NotificationTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(NotificationModelAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(ProductModelAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(ProductDimensionsAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(ProductReviewAdapter());
  }

  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<OrderModel>('orderBox');
  await Hive.openBox<NotificationModel>('notificationBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductProvider()),
      ],
      // Ganti home dengan halaman testing sementara
      // Saat development CRUD, Anda bisa beralih antara AddProductPage atau EditProductPage
      // Jangan lupa mengembalikan ke LoginPage setelah testing CRUD selesai!
      child: const TestApp(), // Wrapper untuk navigasi testing
    ),
  );
}

// Tambahkan widget ini untuk memudahkan navigasi testing
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groceries Store App Test',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          color: Color(0xFF4E342E), // primaryColor
          foregroundColor: Colors.white,
        ),
      ),
      // Anda bisa langsung menunjuk ke halaman AddProductPage untuk mengujinya
      home: const TestPageNavigator(), // Menggunakan navigator sederhana
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestPageNavigator extends StatelessWidget {
  const TestPageNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Test Navigator')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductPage(),
                  ),
                );
              },
              child: const Text('Go to Add Product Page'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Untuk menguji EditProductPage, Anda perlu sebuah ProductModel.
                // Anda bisa mengambilnya dari DummyJSON API atau membuat mock data.
                // Contoh mock data (ini hanya untuk pengujian, di aplikasi nyata akan dari API/database)
                final mockProduct = ProductModel(
                  id: 1, // ID produk yang ingin Anda edit di DummyJSON
                  title: 'Mock Product Title',
                  description:
                      'This is a mock product description for editing.',
                  category: 'Testing',
                  price: 10.0,
                  discountPercentage: 5.0,
                  rating: 4.5,
                  stock: 50,
                  tags: ['test', 'mock'],
                  weight: 0.5,
                  dimensions: ProductDimensions(
                    width: 10,
                    height: 10,
                    depth: 10,
                  ),
                  warrantyInformation: '1 Year',
                  shippingInformation: 'Free Shipping',
                  availabilityStatus: 'In Stock',
                  reviews: [],
                  returnPolicy: '30 Days',
                  minimumOrderQuantity: 1,
                  images: [
                    'https://cdn.dummyjson.com/product-images/1/thumbnail.jpg',
                  ],
                  thumbnail:
                      'https://cdn.dummyjson.com/product-images/1/thumbnail.jpg',
                  quantity: 1,
                );

                // Alternatif: Coba ambil produk nyata dari provider
                // final productProvider = Provider.of<ProductProvider>(context, listen: false);
                // ProductModel? productToEdit = await productProvider.getProductDetail(1); // Ambil ID produk yang ada di DummyJSON

                // if (productToEdit != null) {
                //   Navigator.push(context, MaterialPageRoute(builder: (context) => EditProductPage(product: productToEdit)));
                // } else {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     const SnackBar(content: Text('Failed to load product for editing. Make sure product ID 1 exists.')),
                //   );
                // }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductPage(product: mockProduct),
                  ),
                );
              },
              child: const Text('Go to Edit Product Page (with Mock Data)'),
            ),
          ],
        ),
      ),
    );
  }
}
