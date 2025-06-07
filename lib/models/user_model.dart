import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0) // USER MODEL: TypeId 0
class UserModel extends HiveObject {
  @HiveField(0)
  String username;
  @HiveField(1)
  String hashedPassword;
  @HiveField(2)
  String fullName;
  @HiveField(3)
  String email;
  @HiveField(4)
  String phoneNumber;
  @HiveField(5)
  List<String> roles;
  @HiveField(6)
  String? currentSessionId;

  UserModel({
    required this.username,
    required this.hashedPassword,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    this.currentSessionId,
  });
}
