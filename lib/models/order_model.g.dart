// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderProductItemAdapter extends TypeAdapter<OrderProductItem> {
  @override
  final int typeId = 2;

  @override
  OrderProductItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderProductItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      productImageUrl: fields[2] as String,
      price: fields[3] as double,
      discountPercentage: fields[4] as double,
      quantity: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OrderProductItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.productImageUrl)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.discountPercentage)
      ..writeByte(5)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderProductItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 3;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      orderId: fields[0] as String?,
      customerUsername: fields[1] as String,
      customerName: fields[2] as String,
      customerAddress: fields[3] as String,
      customerPhoneNumber: fields[4] as String,
      items: (fields[5] as List).cast<OrderProductItem>(),
      subtotalAmount: fields[6] as double,
      courierService: fields[7] as String,
      courierCost: fields[8] as double,
      totalAmount: fields[9] as double,
      paymentMethod: fields[10] as String,
      selectedCurrency: fields[11] as String,
      orderDate: fields[12] as DateTime?,
      status: fields[13] as OrderStatus,
      sellerUsername: fields[14] as String,
      hasBeenReviewed: fields[15] == null ? false : fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.orderId)
      ..writeByte(1)
      ..write(obj.customerUsername)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.customerAddress)
      ..writeByte(4)
      ..write(obj.customerPhoneNumber)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.subtotalAmount)
      ..writeByte(7)
      ..write(obj.courierService)
      ..writeByte(8)
      ..write(obj.courierCost)
      ..writeByte(9)
      ..write(obj.totalAmount)
      ..writeByte(10)
      ..write(obj.paymentMethod)
      ..writeByte(11)
      ..write(obj.selectedCurrency)
      ..writeByte(12)
      ..write(obj.orderDate)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.sellerUsername)
      ..writeByte(15)
      ..write(obj.hasBeenReviewed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = 1;

  @override
  OrderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.confirmed;
      case 2:
        return OrderStatus.processing;
      case 3:
        return OrderStatus.shipped;
      case 4:
        return OrderStatus.delivered;
      case 5:
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    switch (obj) {
      case OrderStatus.pending:
        writer.writeByte(0);
        break;
      case OrderStatus.confirmed:
        writer.writeByte(1);
        break;
      case OrderStatus.processing:
        writer.writeByte(2);
        break;
      case OrderStatus.shipped:
        writer.writeByte(3);
        break;
      case OrderStatus.delivered:
        writer.writeByte(4);
        break;
      case OrderStatus.cancelled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
