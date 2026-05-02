import '../db/hive_db.dart';
import '../models/vendor_model.dart';
import '../models/vendor_transaction_model.dart';
import '../utils/id_generator.dart';

class VendorService {
  static const String storeId = 'store_001';

  List<VendorModel> getAllVendors() {
    return HiveDB.vendors.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<VendorModel> searchVendors(String query) {
    if (query.isEmpty) return getAllVendors();
    final q = query.toLowerCase();
    return HiveDB.vendors.values
        .where((v) =>
            v.name.toLowerCase().contains(q) ||
            (v.phone?.contains(q) ?? false))
        .toList();
  }

  Future<VendorModel> createVendor({
    required String name,
    String? phone,
    String? bankName,
    String? accountNumber,
    String? upiId,
    String? address,
  }) async {
    final vendor = VendorModel()
      ..id = IdGenerator.shortId()
      ..storeId = storeId
      ..name = name
      ..phone = phone
      ..bankName = bankName
      ..accountNumber = accountNumber
      ..upiId = upiId
      ..address = address
      ..createdAt = DateTime.now();

    await HiveDB.vendors.put(vendor.id, vendor);
    return vendor;
  }

  Future<void> updateVendor(VendorModel vendor) async {
    await vendor.save();
  }

  Future<VendorTransactionModel> recordOrder({
    required VendorModel vendor,
    required List<VendorOrderItem> items,
    required int totalAmountPaisa,
    String? note,
  }) async {
    final txn = VendorTransactionModel()
      ..id = IdGenerator.generate(storeId: storeId)
      ..vendorId = vendor.id
      ..vendorName = vendor.name
      ..storeId = storeId
      ..type = 'ORDER'
      ..timestamp = DateTime.now()
      ..totalAmountPaisa = totalAmountPaisa
      ..items = items
      ..note = note;

    await HiveDB.vendorTransactions.put(txn.id, txn);
    return txn;
  }

  Future<VendorTransactionModel> recordPayment({
    required VendorModel vendor,
    required int amountPaisa,
    String? note,
  }) async {
    final txn = VendorTransactionModel()
      ..id = IdGenerator.generate(storeId: storeId)
      ..vendorId = vendor.id
      ..vendorName = vendor.name
      ..storeId = storeId
      ..type = 'PAYMENT'
      ..timestamp = DateTime.now()
      ..totalAmountPaisa = amountPaisa
      ..items = []
      ..note = note ?? 'Payment kiya';

    await HiveDB.vendorTransactions.put(txn.id, txn);
    return txn;
  }

  int getVendorBalance(String vendorId) {
    int totalOrders = 0;
    int totalPayments = 0;
    for (final txn in HiveDB.vendorTransactions.values) {
      if (txn.vendorId != vendorId) continue;
      if (txn.type == 'ORDER') {
        totalOrders += txn.totalAmountPaisa;
      } else if (txn.type == 'PAYMENT') {
        totalPayments += txn.totalAmountPaisa;
      }
    }
    return totalOrders - totalPayments;
  }

  List<VendorTransactionModel> getVendorHistory(String vendorId) {
    return HiveDB.vendorTransactions.values
        .where((t) => t.vendorId == vendorId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
