import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // Pastikan ini ada dan paket uuid sudah di pubspec.yaml

part 'product_model.g.dart';

@HiveType(typeId: 6) // <-- PASTIKAN INI ADALAH 6, agar sesuai dengan main.dart
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id; // Type changed from int to String
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
  final double rating;
  @HiveField(7)
  final int stock;
  @HiveField(8)
  final List<String> tags;
  @HiveField(9)
  final double weight;
  @HiveField(10)
  final ProductDimensions dimensions;
  @HiveField(11)
  final String warrantyInformation;
  @HiveField(12)
  final String shippingInformation;
  @HiveField(13)
  final String availabilityStatus;
  @HiveField(14)
  final List<ProductReview> reviews;
  @HiveField(15)
  final String returnPolicy;
  @HiveField(16)
  final int minimumOrderQuantity;
  @HiveField(17)
  final List<String> images;
  @HiveField(18)
  final String thumbnail;
  @HiveField(19)
  int quantity;
  @HiveField(20) // NEW HIVE FIELD INDEX!
  final String? uploaderUsername; // NEW: To store who uploaded this product

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.tags,
    required this.weight,
    required this.dimensions,
    required this.warrantyInformation,
    required this.shippingInformation,
    required this.availabilityStatus,
    required this.reviews,
    required this.returnPolicy,
    required this.minimumOrderQuantity,
    required this.images,
    required this.thumbnail,
    this.quantity = 1,
    this.uploaderUsername, // NEW: Make it nullable or provide a default if always present
  });

  factory ProductModel.fromJsonSafe(Map<String, dynamic> json) {
    final uuid = Uuid();
    return ProductModel(
      // Ensure id is a String. If the API returns an int, convert it.
      // If null, generate a new UUID for local products.
      id: json['id'] != null ? json['id'].toString() : uuid.v4(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      dimensions: ProductDimensions.fromJsonSafe(json['dimensions'] ?? {}),
      warrantyInformation: json['warrantyInformation'] ?? '',
      shippingInformation: json['shippingInformation'] ?? '',
      availabilityStatus: json['availabilityStatus'] ?? '',
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map((e) => ProductReview.fromJsonSafe(e))
              .toList() ??
          [],
      returnPolicy: json['returnPolicy'] ?? '',
      minimumOrderQuantity: json['minimumOrderQuantity'] as int? ?? 1,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      thumbnail: json['thumbnail'] ?? '',
      quantity: json['quantity'] as int? ?? 1,
      uploaderUsername:
          json['uploaderUsername'] as String?, // NEW: Extract from JSON
    );
  }

  Map<String, dynamic> toJson() => {
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
    'dimensions': dimensions.toJson(),
    'warrantyInformation': warrantyInformation,
    'shippingInformation': shippingInformation,
    'availabilityStatus': availabilityStatus,
    'reviews': reviews.map((e) => e.toJson()).toList(),
    'returnPolicy': returnPolicy,
    'minimumOrderQuantity': minimumOrderQuantity,
    'images': images,
    'thumbnail': thumbnail,
    'quantity': quantity,
    'uploaderUsername': uploaderUsername, // NEW: Add to JSON
  };

  double get finalPrice => price - (price * discountPercentage / 100);
  bool get isInStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 10;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;
}

@HiveType(typeId: 7)
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
  String toString() =>
      '${width.toStringAsFixed(1)} x ${height.toStringAsFixed(1)} x ${depth.toStringAsFixed(1)} cm';
}

@HiveType(typeId: 8)
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
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      date: json['date'] ?? '',
      reviewerName: json['reviewerName'] ?? '',
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
