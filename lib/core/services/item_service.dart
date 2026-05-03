import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/hive_db.dart';
import '../models/item_model.dart';
import '../models/transaction_model.dart';
import '../utils/id_generator.dart';

final itemServiceProvider = Provider((ref) => ItemService());

class ItemService {
  static const String storeId = 'store_001';

  List<ItemModel> getAllItems() {
    return HiveDB.items.values
        .where((i) => i.active)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<ItemModel> searchItems(String query) {
    if (query.isEmpty) return getAllItems();
    final q = query.toLowerCase();
    return HiveDB.items.values
        .where((i) =>
            i.active &&
            (i.name.toLowerCase().contains(q) ||
                (i.nameHindi?.contains(q) ?? false)))
        .toList();
  }

  List<ItemModel> getLowStockItems() {
    return HiveDB.items.values
        .where((i) => i.active && i.isLowStock)
        .toList();
  }

  Future<void> addStock(ItemModel item, int qty) async {
    // Record a STOCK_ADD transaction for audit trail
    final txn = TransactionModel()
      ..id = IdGenerator.generate(storeId: storeId)
      ..type = 'STOCK_ADD'
      ..timestamp = DateTime.now()
      ..storeId = storeId
      ..customerId = null
      ..customerName = null
      ..paymentMode = 'STOCK_ADD'
      ..totalAmountPaisa = 0
      ..items = [
        TransactionItem()
          ..itemId = item.id
          ..name = item.name
          ..qty = qty
          ..pricePaisa = item.pricePaisa,
      ]
      ..note = 'Stock add kiya: $qty ${item.unit}'
      ..synced = false;

    await HiveDB.transactions.put(txn.id, txn);

    // Update stock
    item.stock += qty;
    item.updatedAt = DateTime.now();
    await item.save();
  }

  Future<ItemModel> createItem({
    required String name,
    String? nameHindi,
    required int pricePaisa,
    int mrpPaisa = 0,
    required int stock,
    required String unit,
    int lowStockAlert = 5,
  }) async {
    final item = ItemModel()
      ..id = IdGenerator.shortId()
      ..storeId = storeId
      ..name = name
      ..nameHindi = nameHindi
      ..pricePaisa = pricePaisa
      ..mrpPaisa = mrpPaisa
      ..stock = stock
      ..lowStockAlert = lowStockAlert
      ..unit = unit
      ..active = true
      ..updatedAt = DateTime.now();

    await HiveDB.items.put(item.id, item);
    return item;
  }

  Future<void> updateItem(ItemModel item) async {
    item.updatedAt = DateTime.now();
    await item.save();
  }

  Future<void> deleteItem(ItemModel item) async {
    item.active = false;
    item.updatedAt = DateTime.now();
    await item.save();
  }
}
