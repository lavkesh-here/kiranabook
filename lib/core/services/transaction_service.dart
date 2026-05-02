import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/hive_db.dart';
import '../models/transaction_model.dart';
import '../models/item_model.dart';
import '../models/customer_model.dart';
import '../utils/id_generator.dart';

final transactionServiceProvider = Provider((ref) => TransactionService());

class TransactionService {
  static const String storeId = 'store_001';

  Future<TransactionModel> createSale({
    required List<CartItem> cartItems,
    required String paymentMode, // CASH | UDHAAR | ONLINE
    CustomerModel? customer,
    String? note,
    DateTime? reminderDate,
  }) async {
    final txnItems = cartItems.map((ci) => TransactionItem()
      ..itemId = ci.item.id
      ..name = ci.item.name
      ..qty = ci.qty
      ..pricePaisa = ci.item.pricePaisa).toList();

    final total = txnItems.fold(0, (sum, i) => sum + i.totalPaisa);

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
      ..reminderDate = reminderDate
      ..synced = false;

    await HiveDB.transactions.put(txn.id, txn);

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
      ..reminderDate = null
      ..synced = false;

    await HiveDB.transactions.put(txn.id, txn);
    return txn;
  }

  int getCustomerBalance(String customerId) {
    int totalUdhaar = 0, totalPayments = 0;
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

  DailySummary getDailySummary({DateTime? date}) {
    final day = date ?? DateTime.now();
    final todayStart = DateTime(day.year, day.month, day.day);
    final todayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

    int cashTotal = 0, udhaarTotal = 0, onlineTotal = 0, paymentsTotal = 0, billCount = 0;
    for (final txn in HiveDB.transactions.values) {
      if (txn.timestamp.isBefore(todayStart) || txn.timestamp.isAfter(todayEnd)) continue;
      if (txn.type == 'SALE') {
        billCount++;
        if (txn.paymentMode == 'CASH') cashTotal += txn.totalAmountPaisa;
        else if (txn.paymentMode == 'UDHAAR') udhaarTotal += txn.totalAmountPaisa;
        else if (txn.paymentMode == 'ONLINE') onlineTotal += txn.totalAmountPaisa;
      } else if (txn.type == 'PAYMENT') {
        paymentsTotal += txn.totalAmountPaisa;
      }
    }
    return DailySummary(
      cashTotal: cashTotal, udhaarTotal: udhaarTotal,
      onlineTotal: onlineTotal, paymentsReceived: paymentsTotal, billCount: billCount,
    );
  }

  // Get reminders due today or overdue
  List<TransactionModel> getDueReminders() {
    final today = DateTime.now();
    return HiveDB.transactions.values.where((txn) {
      if (txn.reminderDate == null) return false;
      if (txn.paymentMode != 'UDHAAR') return false;
      final balance = getCustomerBalance(txn.customerId ?? '');
      if (balance <= 0) return false; // already paid
      return !txn.reminderDate!.isAfter(
          DateTime(today.year, today.month, today.day, 23, 59, 59));
    }).toList()
      ..sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!));
  }

  WeeklySummary getWeeklySummary() {
    final now = DateTime.now();
    final List<DailySummary> days = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      days.add(getDailySummary(date: day));
    }
    return WeeklySummary(days: days);
  }

  List<TransactionModel> getCustomerTransactions(String customerId) {
    return HiveDB.transactions.values
        .where((t) => t.customerId == customerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionModel> getTodayTransactions() {
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return HiveDB.transactions.values
        .where((t) => t.timestamp.isAfter(todayStart))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<TransactionModel> getTransactionsByRange(DateTime start, DateTime end) {
    return HiveDB.transactions.values
        .where((t) => t.timestamp.isAfter(start) && t.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
  final int cashTotal, udhaarTotal, onlineTotal, paymentsReceived, billCount;
  DailySummary({
    required this.cashTotal, required this.udhaarTotal,
    required this.onlineTotal, required this.paymentsReceived,
    required this.billCount,
  });
  int get totalSales => cashTotal + udhaarTotal + onlineTotal;
}

class WeeklySummary {
  final List<DailySummary> days;
  WeeklySummary({required this.days});
  int get totalSales => days.fold(0, (s, d) => s + d.totalSales);
  int get totalCash => days.fold(0, (s, d) => s + d.cashTotal);
  int get totalUdhaar => days.fold(0, (s, d) => s + d.udhaarTotal);
}
