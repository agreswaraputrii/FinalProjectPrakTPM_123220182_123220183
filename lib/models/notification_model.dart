import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 4) // NOTIFICATION TYPE: TypeId 4
enum NotificationType {
  @HiveField(0)
  orderPaid,
  @HiveField(1)
  orderShipped,
  @HiveField(2)
  newOrder,
  @HiveField(3)
  orderCompleted,
  @HiveField(4)
  custom,
}

@HiveType(typeId: 5) // NOTIFICATION MODEL: TypeId 5
class NotificationModel extends HiveObject {
  @HiveField(0)
  String notificationId;
  @HiveField(1)
  String targetUsername;
  @HiveField(2)
  NotificationType type;
  @HiveField(3)
  String title;
  @HiveField(4)
  String body;
  @HiveField(5)
  String? referenceId;
  @HiveField(6)
  DateTime timestamp;
  @HiveField(7)
  bool isRead;

  NotificationModel({
    String? notificationId,
    required this.targetUsername,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    DateTime? timestamp,
    this.isRead = false,
  }) : notificationId = notificationId ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();
}
