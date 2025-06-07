// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 5;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationModel(
      notificationId: fields[0] as String?,
      targetUsername: fields[1] as String,
      type: fields[2] as NotificationType,
      title: fields[3] as String,
      body: fields[4] as String,
      referenceId: fields[5] as String?,
      timestamp: fields[6] as DateTime?,
      isRead: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.notificationId)
      ..writeByte(1)
      ..write(obj.targetUsername)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.referenceId)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 4;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.orderPaid;
      case 1:
        return NotificationType.orderShipped;
      case 2:
        return NotificationType.newOrder;
      case 3:
        return NotificationType.orderCompleted;
      case 4:
        return NotificationType.custom;
      default:
        return NotificationType.orderPaid;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.orderPaid:
        writer.writeByte(0);
        break;
      case NotificationType.orderShipped:
        writer.writeByte(1);
        break;
      case NotificationType.newOrder:
        writer.writeByte(2);
        break;
      case NotificationType.orderCompleted:
        writer.writeByte(3);
        break;
      case NotificationType.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
