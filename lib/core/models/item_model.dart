import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 2)
class ItemModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String storeId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  String? nameHindi;

  @HiveField(4)
  late int pricePaisa; // selling price per unit

  @HiveField(5)
  late int stock; // current count

  @HiveField(6)
  late int lowStockAlert; // alert threshold

  @HiveField(7)
  late String unit; // kg, pcs, packet, litre

  @HiveField(8)
  late bool active;

  @HiveField(9)
  late DateTime updatedAt;

  // Computed helpers
  double get priceRupees => pricePaisa / 100;
  bool get isLowStock => stock <= lowStockAlert && stock >= 0;
  bool get isOutOfStock => stock <= 0;

  String get displayName => nameHindi != null && nameHindi!.isNotEmpty
      ? nameHindi!
      : name;
}
