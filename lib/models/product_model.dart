// lib/models/product_model.dart
import 'package:hive/hive.dart';

part 'product_model.g.dart'; // File ini akan dibuat otomatis

@HiveType(typeId: 6) // Pastikan TypeId ini unik di seluruh aplikasi Anda
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final double price;
  @HiveField(5)
  final double discountPercentage;
  @HiveField(6)
  double rating;
  @HiveField(7)
  int stock; // Dibuat tidak final agar bisa diubah
  @HiveField(8)
  final List<String> tags;
  @HiveField(9)
  final double? weight; // Diubah menjadi opsional
  @HiveField(10)
  final ProductDimensions? dimensions; // Diubah menjadi opsional
  @HiveField(11)
  final String? warrantyInformation; // Diubah menjadi opsional
  @HiveField(12)
  final String shippingInformation;
  @HiveField(13)
  final String availabilityStatus;
  @HiveField(14)
  List<ProductReview> reviews;
  @HiveField(15)
  final String? returnPolicy; // Diubah menjadi opsional
  @HiveField(16)
  final int minimumOrderQuantity;
  @HiveField(17)
  final List<String> images;
  @HiveField(18)
  final String thumbnail;

  @HiveField(19) // Anotasi field baru
  final String? uploaderUsername;

  @HiveField(20) // Anotasi field baru
  int quantity;

  // --- TAMBAHKAN FIELD 'unit' INI ---
  @HiveField(21) // Pastikan TypeId ini unik dan belum digunakan
  final String unit;
  // --- END TAMBAHKAN FIELD 'unit' INI ---

  ProductModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.price,
    this.discountPercentage = 0.0,
    this.rating = 0.0,
    required this.stock,
    this.tags = const [],
    this.weight = 0.0,
    required this.dimensions,
    this.warrantyInformation = '',
    this.shippingInformation = '',
    this.availabilityStatus = 'In Stock',
    this.reviews = const [],
    this.returnPolicy = 'No return policy',
    this.minimumOrderQuantity = 1,
    this.images = const [],
    required this.thumbnail,
    this.uploaderUsername,
    this.quantity = 1,
    // --- TAMBAHKAN 'unit' DI KONSTRUKTOR ---
    this.unit =
        'pcs', // Berikan nilai default, atau sesuaikan jika ada dari API
    // --- END TAMBAHKAN 'unit' DI KONSTRUKTOR ---
  });

  double get finalPrice => price * (1 - discountPercentage / 100);

  bool get hasFreeShipping =>
      shippingInformation.toLowerCase().contains('free');

  factory ProductModel.fromJsonSafe(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? 'no-id',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [],
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      dimensions: ProductDimensions.fromJsonSafe(json['dimensions'] ?? {}),
      warrantyInformation: json['warrantyInformation'] ?? '',
      shippingInformation: json['shippingInformation'] ?? '',
      availabilityStatus: json['availabilityStatus'] ?? 'In Stock',
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map((reviewJson) => ProductReview.fromJsonSafe(reviewJson))
              .toList() ??
          [],
      returnPolicy: json['returnPolicy'] ?? 'No return policy',
      minimumOrderQuantity:
          (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((image) => image.toString())
              .toList() ??
          [],
      thumbnail: json['thumbnail'] ?? '',
      uploaderUsername: json['uploaderUsername'],
      // 'quantity' tidak perlu di-deserialize di sini karena ini adalah model produk,
      // bukan item keranjang yang memiliki quantity spesifik.
      // Jika 'quantity' dimaksudkan sebagai default quantity untuk produk itu sendiri,
      // maka perlu penanganan lebih lanjut.
      // Namun, dalam konteks penambahan ke keranjang, quantity diatur di `_showQuantityDialogWithAdd`.

      // --- TAMBAHKAN 'unit' DI fromJsonSafe ---
      unit:
          json['unit'] ?? 'pcs', // Ambil dari JSON, jika null default ke 'pcs'
      // --- END TAMBAHKAN 'unit' DI fromJsonSafe ---
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'tags': tags,
      'weight': weight,
      'dimensions': dimensions?.toJson(),
      'warrantyInformation': warrantyInformation,
      'shippingInformation': shippingInformation,
      'availabilityStatus': availabilityStatus,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'returnPolicy': returnPolicy,
      'minimumOrderQuantity': minimumOrderQuantity,
      'images': images,
      'thumbnail': thumbnail,
      'uploaderUsername': uploaderUsername,
      // 'quantity' tidak perlu di-serialize di sini kecuali memang bagian dari data produk statis
      // --- TAMBAHKAN 'unit' DI toJson ---
      'unit': unit,
      // --- END TAMBAHKAN 'unit' DI toJson ---
    };
  }
}

@HiveType(typeId: 7) // Pastikan TypeId unik
class ProductDimensions extends HiveObject {
  @HiveField(0)
  final double width;
  @HiveField(1)
  final double height;
  @HiveField(2)
  final double depth;

  ProductDimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  factory ProductDimensions.fromJsonSafe(Map<String, dynamic> json) {
    return ProductDimensions(
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'depth': depth,
  };

  @override
  String toString() => '$width x $height x $depth cm';
}

@HiveType(typeId: 8) // Pastikan TypeId unik
class ProductReview extends HiveObject {
  @HiveField(0)
  final int rating;
  @HiveField(1)
  final String comment;
  @HiveField(2)
  final String date;
  @HiveField(3)
  final String reviewerName;
  @HiveField(4)
  final String reviewerEmail;

  ProductReview({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  factory ProductReview.fromJsonSafe(Map<String, dynamic> json) {
    return ProductReview(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] ?? '',
      date: json['date'] ?? '',
      reviewerName: json['reviewerName'] ?? 'Anonymous',
      reviewerEmail: json['reviewerEmail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
    'date': date,
    'reviewerName': reviewerName,
    'reviewerEmail': reviewerEmail,
  };
}
