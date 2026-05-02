import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String type; // SALE | PAYMENT | STOCK_ADD
  @HiveField(2) late DateTime timestamp;
  @HiveField(3) late String storeId;
  @HiveField(4) String? customerId;
  @HiveField(5) String? customerName;
  @HiveField(6) late String paymentMode; // CASH | UDHAAR | ONLINE | PAYMENT | STOCK_ADD
  @HiveField(7) late int totalAmountPaisa;
  @HiveField(8) late List<TransactionItem> items;
  @HiveField(9) String? note;
  @HiveField(10) late bool synced;
  @HiveField(11) DateTime? reminderDate; // for udhaar reminders

  double get totalRupees => totalAmountPaisa / 100;
}

@HiveType(typeId: 1)
class TransactionItem extends HiveObject {
  @HiveField(0) late String itemId;
  @HiveField(1) late String name;
  @HiveField(2) late int qty;
  @HiveField(3) late int pricePaisa;

  int get totalPaisa => qty * pricePaisa;
  double get priceRupees => pricePaisa / 100;
  double get totalRupees => totalPaisa / 100;
}
