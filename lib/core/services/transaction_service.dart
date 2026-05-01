import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/hive_db.dart';
import '../models/transaction_model.dart';
import '../models/item_model.dart';
import '../models/customer_model.dart';
import '../utils/id_generator.dart';

final transactionServiceProvider = Provider((ref) => TransactionService());

class TransactionService {
  static const String storeId = 'store_001';

  /// Create a SALE transaction (cash or udhaar)
  /// This is the core action — must be atomic
  Future<TransactionModel> createSale({
    required List<CartItem> cartItems,
    required String paymentMode, // CASH | UDHAAR
    CustomerModel? customer,
    String? note,
  }) async {
    // 1. Build transaction items (snapshot prices at time of sale)
    final txnItems = cartItems.map((ci) {
      return TransactionItem()
        ..itemId = ci.item.id
        ..name = ci.item.name
        ..qty = ci.qty
        ..pricePaisa = ci.item.pricePaisa;
    }).toList();

    final total = txnItems.fold(0, (sum, i) => sum + i.totalPaisa);

    // 2. Build transaction
    final txn = TransactionModel()
      ..id = IdGenerator.generate(storeId: storeId)
      ..type = 'SALE'
      ..timestamp = DateTime.now()
      ..storeId = storeId
      ..customerId = customer?.id
      ..customerName = customer?.name
      ..paymentMode = paymentMode
      ..totalAmountPaisa = total
      ..items = txnItems
      ..note = note
      ..synced = false;

    // 3. Save transaction FIRST (atomic)
    await HiveDB.transactions.put(txn.id, txn);

    // 4. Deduct stock for each item
    for (final ci in cartItems) {
      final item = HiveDB.items.get(ci.item.id);
      if (item != null) {
        item.stock = (item.stock - ci.qty).clamp(-9999, 99999);
        item.updatedAt = DateTime.now();
        await item.save();
      }
    }

    return txn;
  }

  /// Record a payment from customer (udhaar wapsi)
  Future<TransactionModel> createPayment({
    required CustomerModel customer,
    required int amountPaisa,
    String? note,
  }) async {
    final txn = TransactionModel()
      ..id = IdGenerator.generate(storeId: storeId)
      ..type = 'PAYMENT'
      ..timestamp = DateTime.now()
      ..storeId = storeId
      ..customerId = customer.id
      ..customerName = customer.name
      ..paymentMode = 'PAYMENT'
      ..totalAmountPaisa = amountPaisa
      ..items = []
      ..note = note ?? 'Paisa wapas diya'
      ..synced = false;

    await HiveDB.transactions.put(txn.id, txn);
    return txn;
  }

  /// Compute customer balance from transactions (never stored)
  int getCustomerBalance(String customerId) {
    int totalUdhaar = 0;
    int totalPayments = 0;

    for (final txn in HiveDB.transactions.values) {
      if (txn.customerId != customerId) continue;
      if (txn.type == 'SALE' && txn.paymentMode == 'UDHAAR') {
        totalUdhaar += txn.totalAmountPaisa;
      } else if (txn.type == 'PAYMENT') {
        totalPayments += txn.totalAmountPaisa;
      }
    }

    return totalUdhaar - totalPayments;
  }

  /// Today's summary
  DailySummary getDailySummary() {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    int cashTotal = 0;
    int udhaarTotal = 0;
    int paymentsTotal = 0;
    int billCount = 0;

    for (final txn in HiveDB.transactions.values) {
      if (txn.timestamp.isBefore(todayStart)) continue;
      if (txn.type == 'SALE') {
        billCount++;
        if (txn.paymentMode == 'CASH') {
          cashTotal += txn.totalAmountPaisa;
        } else if (txn.paymentMode == 'UDHAAR') {
          udhaarTotal += txn.totalAmountPaisa;
        }
      } else if (txn.type == 'PAYMENT') {
        paymentsTotal += txn.totalAmountPaisa;
      }
    }

    return DailySummary(
      cashTotal: cashTotal,
      udhaarTotal: udhaarTotal,
      paymentsReceived: paymentsTotal,
      billCount: billCount,
    );
  }

  /// All transactions for a customer (newest first)
  List<TransactionModel> getCustomerTransactions(String customerId) {
    return HiveDB.transactions.values
        .where((t) => t.customerId == customerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Today's transactions (newest first)
  List<TransactionModel> getTodayTransactions() {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return HiveDB.transactions.values
        .where((t) => t.timestamp.isAfter(todayStart))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// All transactions newest first
  List<TransactionModel> getAllTransactions({int limit = 50}) {
    final all = HiveDB.transactions.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }
}

class CartItem {
  final ItemModel item;
  int qty;

  CartItem({required this.item, this.qty = 1});

  int get totalPaisa => item.pricePaisa * qty;
  double get totalRupees => totalPaisa / 100;
}

class DailySummary {
  final int cashTotal;
  final int udhaarTotal;
  final int paymentsReceived;
  final int billCount;

  DailySummary({
    required this.cashTotal,
    required this.udhaarTotal,
    required this.paymentsReceived,
    required this.billCount,
  });

  int get totalSales => cashTotal + udhaarTotal;
}
