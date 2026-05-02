import 'package:hive/hive.dart';

part 'vendor_transaction_model.g.dart';

@HiveType(typeId: 6)
class VendorTransactionModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String vendorId;

  @HiveField(2)
  late String vendorName;

  @HiveField(3)
  late String storeId;

  @HiveField(4)
  late String type; // ORDER | PAYMENT

  @HiveField(5)
  late DateTime timestamp;

  @HiveField(6)
  late int totalAmountPaisa;

  @HiveField(7)
  late List<VendorOrderItem> items;

  @HiveField(8)
  String? note;

  double get totalRupees => totalAmountPaisa / 100;
}

@HiveType(typeId: 7)
class VendorOrderItem extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late int qty;

  @HiveField(2)
  late int pricePaisa;

  @HiveField(3)
  late String unit;

  int get totalPaisa => qty * pricePaisa;
  double get totalRupees => totalPaisa / 100;
}
