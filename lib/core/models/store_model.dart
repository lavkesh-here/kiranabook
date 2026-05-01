import 'package:hive/hive.dart';

part 'store_model.g.dart';

@HiveType(typeId: 4)
class StoreModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String ownerName;

  @HiveField(3)
  late String phone;

  @HiveField(4)
  late String language; // 'hi' | 'en'

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  bool isSetupDone = false;
}
