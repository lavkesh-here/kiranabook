import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/customer_service.dart';
import '../../core/services/share_service.dart';
import '../../core/models/customer_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/db/hive_db.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_search_bar.dart';

class UdhaarScreen extends StatefulWidget {
  const UdhaarScreen({super.key});
  @override
  State<UdhaarScreen> createState() => _UdhaarScreenState();
}

class _UdhaarScreenState extends State<UdhaarScreen> with SingleTickerProviderStateMixin {
  final _txnSvc = TransactionService();
  final _custSvc = CustomerService();
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;
  List<CustomerWithBalance> _all = [];
  List<CustomerWithBalance> _filtered = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  void _load() {
    _all = _custSvc.getCustomersWithBalance(_txnSvc);
    _filtered = List.from(_all);
    setState(() {});
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? List.from(_all)
          : _all.where((c) => c.customer.name.toLowerCase().contains(q) || (c.customer.phone?.contains(q) ?? false)).toList();
    });
  }

  List<CustomerWithBalance> get _displayed {
    return _tabCtrl.index == 0
        ? _filtered.where((c) => c.hasBalance).toList()
        : _filtered;
  }

  @override
  Widget build(BuildContext context) {
    final withBalance = _all.where((c) => c.hasBalance).length;
    final totalOutstanding = _all.fold(0, (sum, c) => sum + (c.hasBalance ? c.balancePaisa : 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Udhaar Khata 📒'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
          tabs: [Tab(text: 'Baaki ($withBalance)'), Tab(text: 'Sab Log (${_all.length})')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomer(context),
        backgroundColor: KColors.saffron,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(children: [
        if (totalOutstanding > 0)
          Container(
            color: KColors.redPale,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet, color: KColors.red, size: 18),
              const SizedBox(width: 8),
              Text('Kul baaki: ${KCurrency.format(totalOutstanding)}',
                  style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 14, color: KColors.red)),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: KSearchBar(
            controller: _searchCtrl,
            hint: '🔍 Customer ka naam...',
          ),
        ),
        Expanded(
          child: _displayed.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_outline, size: 56, color: KColors.inkGhost),
                  const SizedBox(height: 12),
                  Text(_tabCtrl.index == 0 ? 'Kisi ka udhaar nahi hai 🎉' : 'Koi customer nahi',
                      style: const TextStyle(fontFamily: 'Baloo2', fontSize: 16, color: KColors.inkSoft)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: () => _showAddCustomer(context),
                      icon: const Icon(Icons.person_add), label: const Text('Customer Add Karo')),
                ]))
              : RefreshIndicator(
                  color: KColors.saffron,
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    itemCount: _displayed.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final cwb = _displayed[i];
                      return ListTile(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CustomerDetailScreen(customer: cwb.customer, onChanged: _load),
                          ));
                        },
                        leading: CircleAvatar(
                          backgroundColor: KColors.saffronPale,
                          radius: 22,
                          child: Text(cwb.customer.name[0].toUpperCase(),
                              style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 18, color: KColors.saffron)),
                        ),
                        title: Text(cwb.customer.name, style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: cwb.customer.phone != null
                            ? Text(cwb.customer.phone!, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 12))
                            : null,
                        trailing: cwb.hasBalance
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(KCurrency.formatRupees(cwb.balanceRupees),
                                    style: const TextStyle(fontFamily: 'Baloo2', fontSize: 16, fontWeight: FontWeight.w800, color: KColors.red)),
                                const Text('Baaki', style: TextStyle(fontFamily: 'Baloo2', fontSize: 10, color: KColors.inkGhost)),
                              ])
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: KColors.greenPale, borderRadius: BorderRadius.circular(8)),
                                child: const Text('✓ Clear', style: TextStyle(fontFamily: 'Baloo2', fontSize: 12, color: KColors.green, fontWeight: FontWeight.w600)),
                              ),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  void _showAddCustomer(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Naya Customer Add Karo',
                style: TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, autofocus: true, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Naam *', hintText: 'Ramesh Bhai')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number (optional)', prefixText: '+91 ')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Naam daalna zaroori hai!', style: TextStyle(fontFamily: 'Baloo2')),
                    backgroundColor: KColors.red));
                  return;
                }
                await _custSvc.createCustomer(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );
                if (context.mounted) { Navigator.pop(context); _load(); }
              },
              icon: const Icon(Icons.check), label: const Text('Save Karo'),
            ),
            const SizedBox(height: 8),
          ])),
        ),
      ),
    );
  }
}

// Customer detail screen
class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;
  final VoidCallback? onChanged;
  const CustomerDetailScreen({super.key, required this.customer, this.onChanged});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _txnSvc = TransactionService();
  List<TransactionModel> _txns = [];
  int _balance = 0;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    setState(() {
      _txns = _txnSvc.getCustomerTransactions(widget.customer.id);
      _balance = _txnSvc.getCustomerBalance(widget.customer.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          if (c.phone != null)
            IconButton(icon: const Icon(Icons.share), onPressed: _shareStatement),
        ],
      ),
      body: Column(children: [
        // Balance header
        Container(
          color: _balance > 0 ? KColors.redPale : KColors.greenPale,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: _balance > 0 ? KColors.red : KColors.green,
              radius: 26,
              child: Text(c.name[0].toUpperCase(),
                  style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w800)),
              if (c.phone != null) Text(c.phone!, style: const TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(KCurrency.format(_balance),
                  style: TextStyle(fontFamily: 'Baloo2', fontSize: 22, fontWeight: FontWeight.w800,
                      color: _balance > 0 ? KColors.red : KColors.green)),
              Text(_balance > 0 ? 'Baaki hai' : 'Sab clear ✓',
                  style: TextStyle(fontFamily: 'Baloo2', fontSize: 12,
                      color: _balance > 0 ? KColors.red : KColors.green, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),

        if (_balance > 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentSheet(context),
              icon: const Text('💰', style: TextStyle(fontSize: 18)),
              label: const Text('Paisa Mila (Payment Lo)'),
              style: ElevatedButton.styleFrom(backgroundColor: KColors.green),
            ),
          ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(alignment: Alignment.centerLeft,
            child: Text('Purana Hisaab', style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w700, color: KColors.inkSoft))),
        ),

        Expanded(
          child: _txns.isEmpty
              ? const Center(child: Text('Koi transaction nahi', style: TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft)))
              : RefreshIndicator(
                  color: KColors.saffron,
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    itemCount: _txns.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final txn = _txns[i];
                      final isPayment = txn.type == 'PAYMENT';
                      return ListTile(
                        leading: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: isPayment ? KColors.greenPale : KColors.saffronPale,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Icon(isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isPayment ? KColors.green : KColors.saffron, size: 16),
                        ),
                        title: Text(
                          isPayment ? 'Payment' : txn.items.map((i) => '${i.name}×${i.qty}').join(', '),
                          style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(KDate.formatDateTime(txn.timestamp),
                              style: const TextStyle(fontFamily: 'Baloo2', fontSize: 11)),
                          if (txn.reminderDate != null)
                            Text('🔔 Reminder: ${KDate.formatDate(txn.reminderDate!)}',
                                style: const TextStyle(fontFamily: 'Baloo2', fontSize: 10, color: KColors.yellow)),
                        ]),
                        trailing: Text(
                          '${isPayment ? "-" : "+"}${KCurrency.format(txn.totalAmountPaisa)}',
                          style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 15,
                              color: isPayment ? KColors.green : KColors.red),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('💰 Payment Lo', style: TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Baaki: ${KCurrency.format(_balance)}',
                  style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, color: KColors.red)),
            ]),
            const SizedBox(height: 4),
            Text(widget.customer.name, style: const TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Kitna paisa mila?',
                prefixText: '₹ ',
                hintText: (_balance / 100).toStringAsFixed(0),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final amount = KCurrency.parseRupees(ctrl.text);
                if (amount <= 0) return;
                // Close sheet first, then process
                Navigator.pop(sheetCtx);
                await _txnSvc.createPayment(
                  customer: widget.customer,
                  amountPaisa: amount,
                );
                _load();
                widget.onChanged?.call();
                HapticFeedback.heavyImpact();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✓ ${KCurrency.format(amount)} paisa mila!',
                        style: const TextStyle(fontFamily: 'Baloo2')),
                    backgroundColor: KColors.green,
                  ));
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Karo'),
              style: ElevatedButton.styleFrom(backgroundColor: KColors.green),
            ),
          ]),
        ),
      ),
    );
  }

  void _shareStatement() {
    final buf = StringBuffer();
    final store = HiveDB.store.get('store_001');
    buf.writeln('📒 *${store?.name ?? "Dukaan"} - Udhaar Statement*');
    buf.writeln('👤 ${widget.customer.name}');
    buf.writeln('📅 ${KDate.formatDate(DateTime.now())}');
    buf.writeln('─────────────────────');
    for (final t in _txns.take(10)) {
      final icon = t.type == 'PAYMENT' ? '✅' : '📝';
      final sign = t.type == 'PAYMENT' ? '-' : '+';
      buf.writeln('$icon ${KDate.formatDate(t.timestamp)}: $sign${KCurrency.format(t.totalAmountPaisa)}');
    }
    buf.writeln('─────────────────────');
    buf.writeln('*Baaki: ${KCurrency.format(_balance)}*');
    ShareService.shareViaWhatsApp(buf.toString(), phone: widget.customer.phone);
  }
}
