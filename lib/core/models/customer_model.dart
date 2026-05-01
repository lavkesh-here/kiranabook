import 'package:hive/hive.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 3)
class CustomerModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String storeId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  String? address;

  @HiveField(5)
  late DateTime createdAt;

  // NOTE: No balance field — always computed from transactions
  // balance = SUM(SALE udhaar) - SUM(PAYMENT) for this customer
}
