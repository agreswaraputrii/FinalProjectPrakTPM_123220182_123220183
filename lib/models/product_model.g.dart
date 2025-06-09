// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 6;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      price: fields[4] as double,
      discountPercentage: fields[5] as double,
      rating: fields[6] as double,
      stock: fields[7] as int,
      tags: (fields[8] as List).cast<String>(),
      weight: fields[9] as double?,
      dimensions: fields[10] as ProductDimensions?,
      warrantyInformation: fields[11] as String?,
      shippingInformation: fields[12] as String,
      availabilityStatus: fields[13] as String,
      reviews: (fields[14] as List).cast<ProductReview>(),
      returnPolicy: fields[15] as String?,
      minimumOrderQuantity: fields[16] as int,
      images: (fields[17] as List).cast<String>(),
      thumbnail: fields[18] as String,
      uploaderUsername: fields[19] as String?,
      quantity: fields[20] as int,
      unit: fields[21] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.discountPercentage)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.stock)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.weight)
      ..writeByte(10)
      ..write(obj.dimensions)
      ..writeByte(11)
      ..write(obj.warrantyInformation)
      ..writeByte(12)
      ..write(obj.shippingInformation)
      ..writeByte(13)
      ..write(obj.availabilityStatus)
      ..writeByte(14)
      ..write(obj.reviews)
      ..writeByte(15)
      ..write(obj.returnPolicy)
      ..writeByte(16)
      ..write(obj.minimumOrderQuantity)
      ..writeByte(17)
      ..write(obj.images)
      ..writeByte(18)
      ..write(obj.thumbnail)
      ..writeByte(19)
      ..write(obj.uploaderUsername)
      ..writeByte(20)
      ..write(obj.quantity)
      ..writeByte(21)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductDimensionsAdapter extends TypeAdapter<ProductDimensions> {
  @override
  final int typeId = 7;

  @override
  ProductDimensions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductDimensions(
      width: fields[0] as double,
      height: fields[1] as double,
      depth: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ProductDimensions obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.width)
      ..writeByte(1)
      ..write(obj.height)
      ..writeByte(2)
      ..write(obj.depth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDimensionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductReviewAdapter extends TypeAdapter<ProductReview> {
  @override
  final int typeId = 8;

  @override
  ProductReview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductReview(
      rating: fields[0] as int,
      comment: fields[1] as String,
      date: fields[2] as String,
      reviewerName: fields[3] as String,
      reviewerEmail: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProductReview obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.rating)
      ..writeByte(1)
      ..write(obj.comment)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.reviewerName)
      ..writeByte(4)
      ..write(obj.reviewerEmail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
