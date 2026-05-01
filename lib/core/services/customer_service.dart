import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/hive_db.dart';
import '../models/customer_model.dart';
import '../utils/id_generator.dart';
import 'transaction_service.dart';

final customerServiceProvider = Provider((ref) => CustomerService());

class CustomerService {
  static const String storeId = 'store_001';

  List<CustomerModel> getAllCustomers() {
    return HiveDB.customers.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get customers sorted by outstanding balance (highest first)
  List<CustomerWithBalance> getCustomersWithBalance(TransactionService txnService) {
    return HiveDB.customers.values.map((c) {
      final balance = txnService.getCustomerBalance(c.id);
      return CustomerWithBalance(customer: c, balancePaisa: balance);
    }).toList()
      ..sort((a, b) => b.balancePaisa.compareTo(a.balancePaisa));
  }

  List<CustomerModel> searchCustomers(String query) {
    if (query.isEmpty) return getAllCustomers();
    final q = query.toLowerCase();
    return HiveDB.customers.values
        .where((c) => c.name.toLowerCase().contains(q) ||
            (c.phone?.contains(q) ?? false))
        .toList();
  }

  Future<CustomerModel> createCustomer({
    required String name,
    String? phone,
    String? address,
  }) async {
    final customer = CustomerModel()
      ..id = IdGenerator.shortId()
      ..storeId = storeId
      ..name = name
      ..phone = phone
      ..address = address
      ..createdAt = DateTime.now();

    await HiveDB.customers.put(customer.id, customer);
    return customer;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await customer.save();
  }

  CustomerModel? getById(String id) => HiveDB.customers.get(id);
}

class CustomerWithBalance {
  final CustomerModel customer;
  final int balancePaisa;

  CustomerWithBalance({required this.customer, required this.balancePaisa});

  double get balanceRupees => balancePaisa / 100;
  bool get hasBalance => balancePaisa > 0;
}
