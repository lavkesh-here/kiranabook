import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/hive_db.dart';
import '../../core/models/item_model.dart';
import '../../core/models/customer_model.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/item_service.dart';
import '../../core/services/customer_service.dart';
import '../../core/services/share_service.dart';
import '../../core/services/app_settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

// ── Cart state ──
final cartProvider =
    StateNotifierProvider<CartNotifier, Map<String, CartItem>>(
        (ref) => CartNotifier());

class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  CartNotifier() : super({});

  void addItem(ItemModel item) {
    final updated = Map<String, CartItem>.from(state);
    if (updated.containsKey(item.id)) {
      updated[item.id] = CartItem(item: item, qty: updated[item.id]!.qty + 1);
    } else {
      updated[item.id] = CartItem(item: item, qty: 1);
    }
    state = updated;
  }

  void decrementItem(String itemId) {
    final updated = Map<String, CartItem>.from(state);
    if (!updated.containsKey(itemId)) return;
    final qty = updated[itemId]!.qty;
    if (qty <= 1) {
      updated.remove(itemId);
    } else {
      updated[itemId] = CartItem(item: updated[itemId]!.item, qty: qty - 1);
    }
    state = updated;
  }

  void setQty(String itemId, int qty) {
    final updated = Map<String, CartItem>.from(state);
    if (qty <= 0) {
      updated.remove(itemId);
    } else if (updated.containsKey(itemId)) {
      updated[itemId] = CartItem(
          item: updated[itemId]!.item, qty: qty.clamp(1, 99999));
    }
    state = updated;
  }

  void clear() => state = {};
  int get totalPaisa =>
      state.values.fold(0, (sum, ci) => sum + ci.totalPaisa);
  int get totalItems => state.values.fold(0, (sum, ci) => sum + ci.qty);
}

final selectedCustomerProvider = StateProvider<CustomerModel?>((ref) => null);
final reminderDateProvider = StateProvider<DateTime?>((ref) => null);

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});
  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  late ItemService _itemSvc;
  List<ItemModel> _displayItems = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _itemSvc = ItemService();
    _displayItems = _itemSvc.getAllItems();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() => setState(() {
        _displayItems = _itemSvc.searchItems(_searchController.text);
      });

  void _refreshItems() => setState(() {
        _displayItems = _itemSvc.searchItems(_searchController.text);
      });

  Future<void> _saveBill(String paymentMode) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final customer = ref.read(selectedCustomerProvider);
      final reminderDate = ref.read(reminderDateProvider);
      await TransactionService().createSale(
        cartItems: cart.values.toList(),
        paymentMode: paymentMode,
        customer: customer,
        reminderDate:
            paymentMode == 'UDHAAR' ? reminderDate : null,
      );
      ref.read(cartProvider.notifier).clear();
      ref.read(selectedCustomerProvider.notifier).state = null;
      ref.read(reminderDateProvider.notifier).state = null;
      _refreshItems();
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showBillSaved(paymentMode);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showBillSaved(String mode) {
    String modeText = mode == 'CASH'
        ? '💵 Cash mila'
        : mode == 'ONLINE'
            ? '📲 Online payment'
            : '📝 Udhaar darj kiya';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: KColors.card, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: KColors.greenPale,
                borderRadius: BorderRadius.circular(32)),
            child: const Icon(Icons.check_circle,
                color: KColors.green, size: 36),
          ),
          const SizedBox(height: 12),
          const Text('Bill Save Ho Gaya! ✓',
              style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: KColors.green)),
          const SizedBox(height: 4),
          Text(modeText,
              style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 14,
                  color: KColors.inkSoft)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Naya Bill Banao'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final settings = ref.watch(appSettingsProvider);
    final hasItems = cart.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Naya Bill 🧾'),
        actions: [
          if (hasItems)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                ref.read(selectedCustomerProvider.notifier).state = null;
                ref.read(reminderDateProvider.notifier).state = null;
              },
              child: const Text('Clear',
                  style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Customer picker
          if (settings.customerManagementEnabled)
            _CustomerChip(
              selected: selectedCustomer,
              onTap: () => _showCustomerPicker(context),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '🔍 Item dhundho... (Hindi ya English)',
                prefixIcon: Icon(Icons.search, color: KColors.inkSoft),
                hintStyle: TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft),
              ),
            ),
          ),

          // Items grid
          Expanded(
            child: _displayItems.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off,
                        size: 48, color: KColors.inkGhost),
                    const SizedBox(height: 8),
                    const Text('Koi item nahi mila',
                        style: TextStyle(
                            fontFamily: 'Baloo2', color: KColors.inkSoft)),
                    TextButton.icon(
                      onPressed: () => _showAddItemSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Naya item add karo'),
                    ),
                  ]))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _displayItems.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == _displayItems.length) {
                        return _AddItemButton(
                            onTap: () => _showAddItemSheet(context));
                      }
                      final item = _displayItems[i];
                      final qty = cart[item.id]?.qty ?? 0;
                      return _ItemChip(
                        item: item,
                        qty: qty,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          cartNotifier.addItem(item);
                        },
                        onDecrement: () => cartNotifier.decrementItem(item.id),
                        onLongPress: () => _showQtyDialog(context, item, qty),
                      );
                    },
                  ),
          ),

          // Cart footer
          if (hasItems)
            _CartFooter(
              totalPaisa: cartNotifier.totalPaisa,
              cart: cart,
              isSaving: _isSaving,
              showOnline: settings.onlinePaymentEnabled,
              onCash: () => _saveBill('CASH'),
              onUdhaar: () {
                if (selectedCustomer == null &&
                    settings.customerManagementEnabled) {
                  _showCustomerRequiredSnack();
                } else {
                  _showReminderPicker(context, () => _saveBill('UDHAAR'));
                }
              },
              onOnline: () => _saveBill('ONLINE'),
            ),
        ],
      ),
    );
  }

  void _showCustomerRequiredSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('👤 Udhaar ke liye customer chunna zaroori hai',
          style: TextStyle(fontFamily: 'Baloo2')),
      backgroundColor: KColors.saffron,
      action: SnackBarAction(
        label: 'Add',
        textColor: Colors.white,
        onPressed: () => _showCustomerPicker(context),
      ),
    ));
  }

  void _showReminderPicker(BuildContext ctx, VoidCallback onSave) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: KColors.card, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Reminder date set karo? (optional)',
              style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Kis din customer ko payment yaad dilaana hai?',
              style:
                  TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onSave();
                },
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip karo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate:
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    ref.read(reminderDateProvider.notifier).state = date;
                  }
                  onSave();
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Date chunno'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showQtyDialog(BuildContext context, ItemModel item, int currentQty) {
    final controller =
        TextEditingController(text: currentQty > 0 ? '$currentQty' : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.nameHindi ?? item.name,
            style: const TextStyle(
                fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: InputDecoration(
              labelText: 'Kitna (${item.unit})', suffix: Text(item.unit)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).setQty(item.id, 0);
              Navigator.pop(context);
            },
            child: const Text('Hatao',
                style: TextStyle(color: KColors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              ref.read(cartProvider.notifier).setQty(item.id, qty);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCustomerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerPickerSheet(
        onSelected: (customer) {
          ref.read(selectedCustomerProvider.notifier).state = customer;
        },
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(onAdded: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          _refreshItems();
        });
      }),
    );
  }
}

// ── Item chip with +/- ──
class _ItemChip extends StatelessWidget {
  final ItemModel item;
  final int qty;
  final VoidCallback onTap;
  final VoidCallback onDecrement;
  final VoidCallback onLongPress;

  const _ItemChip({
    required this.item,
    required this.qty,
    required this.onTap,
    required this.onDecrement,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = qty > 0;
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isAdded ? KColors.greenPale : KColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAdded ? KColors.green : isLow ? KColors.yellow : KColors.border,
            width: isAdded ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: KColors.ink.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Item name (Hindi + English)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(children: [
                Text(
                  item.nameHindi ?? item.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isAdded ? KColors.greenDark : KColors.ink,
                  ),
                ),
                if (item.nameHindi != null && item.nameHindi != item.name)
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 10,
                      color: KColors.inkSoft,
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 2),
            // MRP crossed out (Option C)
            if (item.hasMrp)
              Text(
                KCurrency.format(item.mrpPaisa),
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 10,
                  color: KColors.inkGhost,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: KColors.inkGhost,
                ),
              ),
            Text(
              KCurrency.format(item.pricePaisa),
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 11,
                color: isAdded ? KColors.green : KColors.saffron,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Stock indicator
            Text(
              isOut ? 'Stock khatam' : 'Stock: ${item.stock}',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 9,
                color: isOut ? KColors.red : isLow ? KColors.yellow : KColors.inkGhost,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            // +/- controls
            if (isAdded)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onDecrement,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                          color: KColors.red.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.remove, size: 14, color: KColors.red),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('$qty',
                        style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            color: KColors.green,
                            fontSize: 14)),
                  ),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                          color: KColors.green.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.add, size: 14, color: KColors.green),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: KColors.saffronPale, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 16, color: KColors.saffron),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddItemButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: KColors.saffronPale,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KColors.saffron, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: KColors.saffron, size: 28),
            SizedBox(height: 4),
            Text('Naya\nItem',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KColors.saffron)),
          ],
        ),
      ),
    );
  }
}

// ── Cart footer with 3 payment options ──
class _CartFooter extends StatelessWidget {
  final int totalPaisa;
  final Map<String, CartItem> cart;
  final bool isSaving;
  final bool showOnline;
  final VoidCallback onCash;
  final VoidCallback onUdhaar;
  final VoidCallback onOnline;

  const _CartFooter({
    required this.totalPaisa,
    required this.cart,
    required this.isSaving,
    required this.showOnline,
    required this.onCash,
    required this.onUdhaar,
    required this.onOnline,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = cart.values.fold(0, (s, ci) => s + ci.qty);
    return Container(
      decoration: BoxDecoration(
        color: KColors.ink,
        boxShadow: [BoxShadow(color: KColors.ink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$itemCount items',
                  style: const TextStyle(fontFamily: 'Baloo2', color: Colors.white60, fontSize: 13)),
              Text('Kul: ${KCurrency.format(totalPaisa)}',
                  style: const TextStyle(fontFamily: 'Baloo2', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onCash,
                  icon: const Text('💵', style: TextStyle(fontSize: 16)),
                  label: const Text('Cash'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KColors.green, minimumSize: const Size(0, 48)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onUdhaar,
                  icon: const Text('📝', style: TextStyle(fontSize: 16)),
                  label: const Text('Udhaar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KColors.saffron, minimumSize: const Size(0, 48)),
                ),
              ),
              if (showOnline) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : onOnline,
                    icon: const Text('📲', style: TextStyle(fontSize: 16)),
                    label: const Text('Online'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: KColors.blue, minimumSize: const Size(0, 48)),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

class _CustomerChip extends StatelessWidget {
  final CustomerModel? selected;
  final VoidCallback onTap;
  const _CustomerChip({this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected != null ? KColors.greenPale : KColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected != null ? KColors.green : KColors.border,
              width: selected != null ? 2 : 1,
            ),
          ),
          child: Row(children: [
            Icon(Icons.person_outline,
                color: selected != null ? KColors.green : KColors.inkSoft, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected != null ? '${selected!.name} ✓' : 'Customer chunno (optional)',
                style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected != null ? KColors.greenDark : KColors.inkSoft),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: selected != null ? KColors.green : KColors.inkGhost),
          ]),
        ),
      ),
    );
  }
}

// ── Customer picker sheet ──
class _CustomerPickerSheet extends ConsumerStatefulWidget {
  final Function(CustomerModel?) onSelected;
  const _CustomerPickerSheet({required this.onSelected});
  @override
  ConsumerState<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<CustomerModel> _customers = [];
  final _custSvc = CustomerService();

  @override
  void initState() {
    super.initState();
    _customers = _custSvc.getAllCustomers();
    _searchCtrl.addListener(() {
      setState(() => _customers = _custSvc.searchCustomers(_searchCtrl.text));
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
            color: KColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: KColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Text('Customer chunno',
                  style: TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddCustomer(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Naya'),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: '🔍 Naam se dhundho...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          ListTile(
            leading: Container(width: 40, height: 40,
                decoration: const BoxDecoration(color: KColors.greenPale, shape: BoxShape.circle),
                child: const Icon(Icons.currency_rupee, color: KColors.green)),
            title: const Text('Cash Sale (koi customer nahi)',
                style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w600)),
            onTap: () { widget.onSelected(null); Navigator.pop(context); },
          ),
          const Divider(height: 1),
          Expanded(
            child: _customers.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_off, size: 40, color: KColors.inkGhost),
                    const SizedBox(height: 8),
                    const Text('Koi customer nahi mila',
                        style: TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft)),
                    TextButton(onPressed: () => _showAddCustomer(context), child: const Text('Add karo')),
                  ]))
                : ListView.separated(
                    controller: scrollCtrl,
                    itemCount: _customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = _customers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: KColors.saffronPale,
                          child: Text(c.name[0].toUpperCase(),
                              style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, color: KColors.saffron)),
                        ),
                        title: Text(c.name, style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
                        subtitle: c.phone != null ? Text(c.phone!, style: const TextStyle(fontFamily: 'Baloo2')) : null,
                        onTap: () { widget.onSelected(c); Navigator.pop(context); },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  void _showAddCustomer(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Naya Customer', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, autofocus: true,
              decoration: const InputDecoration(labelText: 'Naam *')),
          const SizedBox(height: 8),
          TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)', prefixText: '+91 ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final c = await CustomerService().createCustomer(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                widget.onSelected(c);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Karo'),
          ),
        ],
      ),
    );
  }
}

// ── Add item sheet ──
class _AddItemSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddItemSheet({required this.onAdded});
  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _nameHindiCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String _unit = 'pcs';
  final _units = ['pcs', 'kg', 'litre', 'packet', 'box'];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameHindiCtrl.dispose();
    _mrpCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: KColors.card, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Naya Item Add Karo',
                    style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                // English name
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Item naam (English) *',
                      hintText: 'e.g. Maggi'),
                ),
                const SizedBox(height: 10),
                // Hindi name
                TextField(
                  controller: _nameHindiCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Item naam (Hindi) - optional',
                      hintText: 'e.g. मैगी'),
                ),
                const SizedBox(height: 10),
                // MRP + Unit row
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _mrpCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [LengthLimitingTextInputFormatter(7)],
                      decoration: const InputDecoration(
                        labelText: 'MRP (₹)',
                        hintText: 'Original price',
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // Selling price
                TextField(
                  controller: _priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [LengthLimitingTextInputFormatter(7)],
                  decoration: const InputDecoration(
                    labelText: 'Bikri Daam (₹) *',
                    hintText: 'Selling price',
                    prefixText: '₹ ',
                    helperText: 'Yeh daam bill mein dikhega',
                  ),
                ),
                const SizedBox(height: 10),
                // Stock
                TextField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5)
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Shuru stock', suffixText: 'units'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final name = _nameCtrl.text.trim();
                          final priceText = _priceCtrl.text.trim();

                          // Validation with clear feedback
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Item naam zaroori hai!',
                                      style:
                                          TextStyle(fontFamily: 'Baloo2')),
                                  backgroundColor: KColors.red),
                            );
                            return;
                          }
                          if (priceText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Bikri daam daalna zaroori hai!',
                                      style:
                                          TextStyle(fontFamily: 'Baloo2')),
                                  backgroundColor: KColors.red),
                            );
                            return;
                          }

                          setState(() => _isSaving = true);
                          try {
                            final pricePaisa =
                                KCurrency.parseRupees(priceText);
                            final mrpPaisa = _mrpCtrl.text.trim().isEmpty
                                ? 0
                                : KCurrency.parseRupees(_mrpCtrl.text);
                            final stock =
                                int.tryParse(_stockCtrl.text.trim()) ?? 0;

                            await ItemService().createItem(
                              name: name,
                              nameHindi:
                                  _nameHindiCtrl.text.trim().isEmpty
                                      ? null
                                      : _nameHindiCtrl.text.trim(),
                              pricePaisa: pricePaisa,
                              mrpPaisa: mrpPaisa,
                              stock: stock,
                              unit: _unit,
                            );

                            widget.onAdded();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: $e',
                                        style: const TextStyle(
                                            fontFamily: 'Baloo2')),
                                    backgroundColor: KColors.red),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label:
                      Text(_isSaving ? 'Save ho raha hai...' : 'Save Karo'),
                ),
                const SizedBox(height: 8),
              ]),
        ),
      ),
    );
  }
}
