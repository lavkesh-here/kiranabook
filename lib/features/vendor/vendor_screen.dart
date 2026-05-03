import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/vendor_service.dart';
import '../../core/models/vendor_model.dart';
import '../../core/models/vendor_transaction_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_search_bar.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});
  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  final _vendorSvc = VendorService();
  final _searchCtrl = TextEditingController();
  List<VendorModel> _vendors = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _load()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _load() {
    _vendors = _vendorSvc.searchVendors(_searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Ledger 🏪')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVendor(context),
        backgroundColor: KColors.saffron,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Naya Vendor', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: KSearchBar(
            controller: _searchCtrl,
            hint: '🔍 Vendor dhundho...',
          ),
        ),
        Expanded(
          child: _vendors.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.store_outlined, size: 56, color: KColors.inkGhost),
                  const SizedBox(height: 12),
                  const Text('Koi vendor nahi\nAdd karo pehla vendor!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Baloo2', fontSize: 15, color: KColors.inkSoft)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVendor(context),
                    icon: const Icon(Icons.add), label: const Text('Vendor Add Karo'),
                  ),
                ]))
              : RefreshIndicator(
                  color: KColors.saffron,
                  onRefresh: () async => setState(() => _load()),
                  child: ListView.separated(
                    itemCount: _vendors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final v = _vendors[i];
                      final balance = _vendorSvc.getVendorBalance(v.id);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: Text(v.name[0].toUpperCase(),
                              style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 18, color: Colors.purple)),
                        ),
                        title: Text(v.name, style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: v.phone != null ? Text(v.phone!, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 12)) : null,
                        trailing: balance > 0
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(KCurrency.format(balance),
                                    style: const TextStyle(fontFamily: 'Baloo2', fontSize: 15, fontWeight: FontWeight.w800, color: KColors.red)),
                                const Text('Dena hai', style: TextStyle(fontFamily: 'Baloo2', fontSize: 10, color: KColors.inkGhost)),
                              ])
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: KColors.greenPale, borderRadius: BorderRadius.circular(8)),
                                child: const Text('✓ Clear', style: TextStyle(fontFamily: 'Baloo2', fontSize: 12, color: KColors.green, fontWeight: FontWeight.w600)),
                              ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => VendorDetailScreen(vendor: v, onChanged: () => setState(() => _load())),
                          ));
                        },
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  void _showAddVendor(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final upiCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Naya Vendor Add Karo', style: TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Vendor naam *')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 10),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address (optional)')),
            const SizedBox(height: 14),
            const Text('Bank Details (optional)', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 13, color: KColors.inkSoft)),
            const SizedBox(height: 8),
            TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank ka naam')),
            const SizedBox(height: 8),
            TextField(controller: accCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account number')),
            const SizedBox(height: 8),
            TextField(controller: upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await _vendorSvc.createVendor(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  bankName: bankCtrl.text.trim().isEmpty ? null : bankCtrl.text.trim(),
                  accountNumber: accCtrl.text.trim().isEmpty ? null : accCtrl.text.trim(),
                  upiId: upiCtrl.text.trim().isEmpty ? null : upiCtrl.text.trim(),
                  address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                );
                if (context.mounted) { Navigator.pop(context); setState(() => _load()); }
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Karo'),
            ),
          ])),
        ),
      ),
    );
  }
}

// Vendor detail screen
class VendorDetailScreen extends StatefulWidget {
  final VendorModel vendor;
  final VoidCallback? onChanged;
  const VendorDetailScreen({super.key, required this.vendor, this.onChanged});
  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final _svc = VendorService();
  List<VendorTransactionModel> _history = [];
  int _balance = 0;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    setState(() {
      _history = _svc.getVendorHistory(widget.vendor.id);
      _balance = _svc.getVendorBalance(widget.vendor.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    return Scaffold(
      appBar: AppBar(title: Text(v.name)),
      body: Column(children: [
        // Header
        Container(
          color: _balance > 0 ? KColors.redPale : KColors.greenPale,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: _balance > 0 ? KColors.red : KColors.green,
                radius: 24,
                child: Text(v.name[0].toUpperCase(),
                    style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w800)),
                if (v.phone != null) Text(v.phone!, style: const TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(KCurrency.format(_balance),
                    style: TextStyle(fontFamily: 'Baloo2', fontSize: 22, fontWeight: FontWeight.w800,
                        color: _balance > 0 ? KColors.red : KColors.green)),
                Text(_balance > 0 ? 'Dena hai' : 'Clear ✓',
                    style: TextStyle(fontFamily: 'Baloo2', fontSize: 12,
                        color: _balance > 0 ? KColors.red : KColors.green, fontWeight: FontWeight.w600)),
              ]),
            ]),
            // Bank details
            if (v.upiId != null || v.bankName != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (v.upiId != null) _InfoChip('UPI', v.upiId!),
              if (v.bankName != null) _InfoChip('Bank', '${v.bankName} • ${v.accountNumber ?? ""}'),
            ],
          ]),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddOrder(context),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Order Kiya'),
                style: ElevatedButton.styleFrom(backgroundColor: KColors.saffron),
              ),
            ),
            const SizedBox(width: 10),
            if (_balance > 0) Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddPayment(context),
                icon: const Icon(Icons.payment),
                label: const Text('Payment Di'),
                style: ElevatedButton.styleFrom(backgroundColor: KColors.green),
              ),
            ),
          ]),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(alignment: Alignment.centerLeft,
            child: Text('Order & Payment History', style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w700, color: KColors.inkSoft))),
        ),

        Expanded(
          child: _history.isEmpty
              ? const Center(child: Text('Koi history nahi', style: TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft)))
              : ListView.separated(
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final txn = _history[i];
                    final isPayment = txn.type == 'PAYMENT';
                    return ListTile(
                      leading: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: isPayment ? KColors.greenPale : KColors.saffronPale,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Icon(isPayment ? Icons.arrow_upward : Icons.shopping_cart,
                            color: isPayment ? KColors.green : KColors.saffron, size: 16),
                      ),
                      title: Text(
                        isPayment ? 'Payment di' : txn.items.map((i) => '${i.name}×${i.qty}').join(', '),
                        style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(KDate.formatDateTime(txn.timestamp),
                          style: const TextStyle(fontFamily: 'Baloo2', fontSize: 11)),
                      trailing: Text(
                        '${isPayment ? "-" : "+"}${KCurrency.format(txn.totalAmountPaisa)}',
                        style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 14,
                            color: isPayment ? KColors.green : KColors.red),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _showAddOrder(BuildContext context) {
    final List<Map<String, TextEditingController>> orderItems = [
      {'name': TextEditingController(), 'qty': TextEditingController(), 'price': TextEditingController()},
    ];
    String unit = 'kg';
    final units = ['kg', 'pcs', 'litre', 'packet', 'box'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(20)),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Order Record Karo', style: TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...orderItems.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(flex: 3, child: TextField(controller: e.value['name'], decoration: InputDecoration(labelText: 'Item ${e.key + 1}'))),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: TextField(controller: e.value['qty'], keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(5)],
                      decoration: const InputDecoration(labelText: 'Qty'))),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: TextField(controller: e.value['price'],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '₹/unit'))),
                ]),
              )),
              TextButton.icon(
                onPressed: () => setS(() => orderItems.add({
                  'name': TextEditingController(), 'qty': TextEditingController(), 'price': TextEditingController(),
                })),
                icon: const Icon(Icons.add), label: const Text('Aur item add karo'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final items = orderItems.where((m) => m['name']!.text.trim().isNotEmpty).map((m) {
                    final qty = int.tryParse(m['qty']!.text) ?? 0;
                    final price = KCurrency.parseRupees(m['price']!.text);
                    return VendorOrderItem()
                      ..name = m['name']!.text.trim()
                      ..qty = qty ..pricePaisa = price ..unit = unit;
                  }).toList();
                  if (items.isEmpty) return;
                  final total = items.fold(0, (s, i) => s + i.totalPaisa);
                  await _svc.recordOrder(vendor: widget.vendor, items: items, totalAmountPaisa: total);
                  if (ctx.mounted) { Navigator.pop(ctx); _load(); widget.onChanged?.call(); }
                },
                icon: const Icon(Icons.check), label: const Text('Save Karo'),
              ),
            ])),
          ),
        ),
      ),
    );
  }

  void _showAddPayment(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Text('Payment Di', style: TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Dena hai: ${KCurrency.format(_balance)}',
                  style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, color: KColors.red)),
            ]),
            const SizedBox(height: 16),
            TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(labelText: 'Kitna diya?', prefixText: '₹ ',
                    hintText: (_balance / 100).toStringAsFixed(0))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final amount = KCurrency.parseRupees(ctrl.text);
                if (amount <= 0) return;
                await _svc.recordPayment(vendor: widget.vendor, amountPaisa: amount);
                if (context.mounted) { Navigator.pop(context); _load(); widget.onChanged?.call(); }
              },
              icon: const Icon(Icons.check), label: const Text('Confirm Karo'),
              style: ElevatedButton.styleFrom(backgroundColor: KColors.green),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.purple))),
      const SizedBox(width: 8),
      Text(value, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}
