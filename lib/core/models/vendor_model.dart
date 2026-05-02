import 'package:hive/hive.dart';

part 'vendor_model.g.dart';

@HiveType(typeId: 5)
class VendorModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String storeId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  String? bankName;

  @HiveField(5)
  String? accountNumber;

  @HiveField(6)
  String? upiId;

  @HiveField(7)
  String? address;

  @HiveField(8)
  late DateTime createdAt;
}
