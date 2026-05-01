import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/item_model.dart';
import '../models/customer_model.dart';
import '../models/store_model.dart';

class HiveDB {
  static const String txnBox = 'transactions';
  static const String itemBox = 'items';
  static const String customerBox = 'customers';
  static const String storeBox = 'store';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register all adapters
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(TransactionItemAdapter());
    Hive.registerAdapter(ItemModelAdapter());
    Hive.registerAdapter(CustomerModelAdapter());
    Hive.registerAdapter(StoreModelAdapter());

    // Open all boxes
    await Hive.openBox<TransactionModel>(txnBox);
    await Hive.openBox<ItemModel>(itemBox);
    await Hive.openBox<CustomerModel>(customerBox);
    await Hive.openBox<StoreModel>(storeBox);

    // Seed default items if first launch
    await _seedDefaultData();
  }

  static Box<TransactionModel> get transactions =>
      Hive.box<TransactionModel>(txnBox);
  static Box<ItemModel> get items => Hive.box<ItemModel>(itemBox);
  static Box<CustomerModel> get customers =>
      Hive.box<CustomerModel>(customerBox);
  static Box<StoreModel> get store => Hive.box<StoreModel>(storeBox);

  static Future<void> _seedDefaultData() async {
    // Only seed if items box is empty (first launch)
    if (items.isNotEmpty) return;

    const uuid = Uuid();
    const storeId = 'store_001';

    // Default store
    final defaultStore = StoreModel()
      ..id = storeId
      ..name = 'Meri Dukaan'
      ..ownerName = 'Dukandaar'
      ..phone = ''
      ..language = 'hi'
      ..createdAt = DateTime.now()
      ..isSetupDone = false;
    await store.put(storeId, defaultStore);

    // Default items as per INITIAL_APP_STATE
    final defaultItems = [
      _makeItem(uuid.v4(), storeId, 'Aata', 'आटा', 2500, 50, 'kg', 10),
      _makeItem(uuid.v4(), storeId, 'Chawal', 'चावल', 6000, 30, 'kg', 8),
      _makeItem(uuid.v4(), storeId, 'Tel', 'तेल', 18000, 12, 'litre', 3),
      _makeItem(uuid.v4(), storeId, 'Cheeni', 'चीनी', 4500, 20, 'kg', 5),
      _makeItem(uuid.v4(), storeId, 'Maggi', 'मैगी', 1400, 15, 'packet', 5),
      _makeItem(uuid.v4(), storeId, 'Biscuit', 'बिस्किट', 1000, 24, 'pcs', 6),
      _makeItem(uuid.v4(), storeId, 'Daal', 'दाल', 8000, 15, 'kg', 5),
      _makeItem(uuid.v4(), storeId, 'Namak', 'नमक', 2000, 10, 'kg', 3),
      _makeItem(uuid.v4(), storeId, 'Sabun', 'साबुन', 3500, 8, 'pcs', 3),
      _makeItem(uuid.v4(), storeId, 'Chai Patti', 'चाय पत्ती', 5000, 10, 'packet', 3),
      _makeItem(uuid.v4(), storeId, 'Atta (1kg)', 'आटा 1kg', 5000, 20, 'packet', 5),
      _makeItem(uuid.v4(), storeId, 'Bread', 'ब्रेड', 4500, 8, 'pcs', 3),
    ];

    for (final item in defaultItems) {
      await items.put(item.id, item);
    }
  }

  static ItemModel _makeItem(
    String id,
    String storeId,
    String name,
    String nameHindi,
    int pricePaisa,
    int stock,
    String unit,
    int lowAlert,
  ) {
    return ItemModel()
      ..id = id
      ..storeId = storeId
      ..name = name
      ..nameHindi = nameHindi
      ..pricePaisa = pricePaisa
      ..stock = stock
      ..lowStockAlert = lowAlert
      ..unit = unit
      ..active = true
      ..updatedAt = DateTime.now();
  }

  static Future<void> clearAll() async {
    await transactions.clear();
    await items.clear();
    await customers.clear();
    await store.clear();
  }
}
