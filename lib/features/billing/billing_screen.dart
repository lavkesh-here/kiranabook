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
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

// Cart state provider
final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartItem>>(
  (ref) => CartNotifier(),
);

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

  void removeItem(String itemId) {
    final updated = Map<String, CartItem>.from(state);
    if (updated.containsKey(itemId)) {
      final qty = updated[itemId]!.qty;
      if (qty <= 1) {
        updated.remove(itemId);
      } else {
        updated[itemId] = CartItem(item: updated[itemId]!.item, qty: qty - 1);
      }
    }
    state = updated;
  }

  void setQty(String itemId, int qty) {
    final updated = Map<String, CartItem>.from(state);
    if (qty <= 0) {
      updated.remove(itemId);
    } else {
      if (updated.containsKey(itemId)) {
        updated[itemId] = CartItem(item: updated[itemId]!.item, qty: qty);
      }
    }
    state = updated;
  }

  void clear() => state = {};

  int get totalPaisa =>
      state.values.fold(0, (sum, ci) => sum + ci.totalPaisa);

  int get totalItems => state.values.fold(0, (sum, ci) => sum + ci.qty);
}

final selectedCustomerProvider = StateProvider<CustomerModel?>((ref) => null);

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

  void _onSearch() {
    setState(() {
      _displayItems = _itemSvc.searchItems(_searchController.text);
    });
  }

  void _refreshItems() {
    setState(() {
      _displayItems = _itemSvc.searchItems(_searchController.text);
    });
  }

  Future<void> _saveBill(String paymentMode) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    // Prevent double-tap
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final customer = ref.read(selectedCustomerProvider);
      final txnSvc = TransactionService();

      await txnSvc.createSale(
        cartItems: cart.values.toList(),
        paymentMode: paymentMode,
        customer: customer,
      );

      // Clear cart and customer selection
      ref.read(cartProvider.notifier).clear();
      ref.read(selectedCustomerProvider.notifier).state = null;
      _refreshItems();

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showBillSavedDialog(paymentMode);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showBillSavedDialog(String mode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: KColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KColors.greenPale,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.check_circle,
                  color: KColors.green, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bill Save Ho Gaya! ✓',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: KColors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode == 'CASH' ? 'Cash mila ✓' : 'Udhaar darj kiya ✓',
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 14,
                color: KColors.inkSoft,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Naya Bill Banao'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KColors.saffron,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final totalPaisa = cartNotifier.totalPaisa;
    final hasItems = cart.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Naya Bill 🧾'),
        actions: [
          if (hasItems)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(cartProvider.notifier).clear();
                ref.read(selectedCustomerProvider.notifier).state = null;
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Customer picker chip
          _CustomerChip(
            selected: selectedCustomer,
            onTap: () => _showCustomerPicker(context),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '🔍 Item dhundho...',
                prefixIcon: Icon(Icons.search, color: KColors.inkSoft),
                hintStyle: TextStyle(
                  fontFamily: 'Baloo2',
                  color: KColors.inkSoft,
                ),
              ),
            ),
          ),

          // Items grid
          Expanded(
            child: _displayItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            size: 48, color: KColors.inkGhost),
                        const SizedBox(height: 8),
                        const Text(
                          'Koi item nahi mila',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            color: KColors.inkSoft,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddItemSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Naya item add karo'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _displayItems.length + 1, // +1 for add button
                    itemBuilder: (ctx, i) {
                      if (i == _displayItems.length) {
                        return _AddItemButton(
                          onTap: () => _showAddItemSheet(context),
                        );
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
                        onLongPress: () => _showQtyDialog(context, item, qty),
                      );
                    },
                  ),
          ),

          // Cart total + pay buttons
          if (hasItems)
            _CartFooter(
              totalPaisa: totalPaisa,
              cart: cart,
              isSaving: _isSaving,
              onCash: () => _saveBill('CASH'),
              onUdhaar: () {
                if (selectedCustomer == null) {
                  _showCustomerRequiredSnack();
                } else {
                  _saveBill('UDHAAR');
                }
              },
            ),
        ],
      ),
    );
  }

  void _showCustomerRequiredSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '👤 Udhaar ke liye customer chunna zaroori hai',
          style: TextStyle(fontFamily: 'Baloo2'),
        ),
        backgroundColor: KColors.saffron,
        action: SnackBarAction(
          label: 'Customer Add',
          textColor: Colors.white,
          onPressed: () => _showCustomerPicker(context),
        ),
      ),
    );
  }

  void _showQtyDialog(BuildContext context, ItemModel item, int currentQty) {
    final controller = TextEditingController(
      text: currentQty > 0 ? '$currentQty' : '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          item.nameHindi ?? item.name,
          style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Kitna (${item.unit})',
            suffix: Text(item.unit),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('Hatao', style: TextStyle(color: KColors.red)),
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
      builder: (_) => _AddItemSheet(
        onAdded: () {
          _refreshItems();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// Item chip widget
class _ItemChip extends StatelessWidget {
  final ItemModel item;
  final int qty;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ItemChip({
    required this.item,
    required this.qty,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = qty > 0;
    final isLow = item.isLowStock;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isAdded ? KColors.greenPale : KColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAdded
                ? KColors.green
                : isLow
                    ? KColors.yellow
                    : KColors.border,
            width: isAdded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: KColors.ink.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        item.nameHindi ?? item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isAdded ? KColors.greenDark : KColors.ink,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    KCurrency.format(item.pricePaisa),
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 11,
                      color: isAdded ? KColors.green : KColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '/${item.unit}',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 10,
                      color: KColors.inkGhost,
                    ),
                  ),
                ],
              ),
            ),
            if (qty > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: KColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Baloo2',
                      ),
                    ),
                  ),
                ),
              ),
            if (isLow && qty == 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: KColors.yellow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'कम',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Baloo2',
                    ),
                  ),
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
            Text(
              'Naya\nItem',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: KColors.saffron,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final int totalPaisa;
  final Map<String, CartItem> cart;
  final bool isSaving;
  final VoidCallback onCash;
  final VoidCallback onUdhaar;

  const _CartFooter({
    required this.totalPaisa,
    required this.cart,
    required this.isSaving,
    required this.onCash,
    required this.onUdhaar,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = cart.values.fold(0, (s, ci) => s + ci.qty);

    return Container(
      decoration: BoxDecoration(
        color: KColors.ink,
        boxShadow: [
          BoxShadow(
            color: KColors.ink.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$itemCount item',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Kul: ${KCurrency.format(totalPaisa)}',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : onCash,
                      icon: const Text('💵', style: TextStyle(fontSize: 18)),
                      label: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Cash Mila'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KColors.green,
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : onUdhaar,
                      icon: const Text('📝', style: TextStyle(fontSize: 18)),
                      label: const Text('Udhaar Diya'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KColors.saffron,
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              style: selected != null ? BorderStyle.solid : BorderStyle.none,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: selected != null ? KColors.green : KColors.inkSoft,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected != null
                      ? '${selected!.name} ✓'
                      : 'Customer chunno (optional)',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected != null ? KColors.greenDark : KColors.inkSoft,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: selected != null ? KColors.green : KColors.inkGhost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Customer picker bottom sheet
class _CustomerPickerSheet extends ConsumerStatefulWidget {
  final Function(CustomerModel?) onSelected;

  const _CustomerPickerSheet({required this.onSelected});

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
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
      setState(() {
        _customers = _custSvc.searchCustomers(_searchCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: KColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    'Customer chunno',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddCustomer(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Naya'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '🔍 Naam se dhundho...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            // Cash sale option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: KColors.greenPale,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.currency_rupee, color: KColors.green),
              ),
              title: const Text(
                'Cash Sale (koi customer nahi)',
                style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w600),
              ),
              onTap: () {
                widget.onSelected(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: _customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_off,
                              size: 40, color: KColors.inkGhost),
                          const SizedBox(height: 8),
                          const Text(
                            'Koi customer nahi mila',
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              color: KColors.inkSoft,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAddCustomer(context),
                            child: const Text('Add karo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _customers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = _customers[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: KColors.saffronPale,
                            child: Text(
                              c.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w700,
                                color: KColors.saffron,
                              ),
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: c.phone != null
                              ? Text(
                                  c.phone!,
                                  style: const TextStyle(fontFamily: 'Baloo2'),
                                )
                              : null,
                          onTap: () {
                            widget.onSelected(c);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomer(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Naya Customer',
          style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Naam *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixText: '+91 ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final custSvc = CustomerService();
              final c = await custSvc.createCustomer(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty
                    ? null
                    : phoneCtrl.text.trim(),
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

// Add item sheet
class _AddItemSheet extends StatefulWidget {
  final VoidCallback onAdded;

  const _AddItemSheet({required this.onAdded});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String _unit = 'pcs';
  final _units = ['pcs', 'kg', 'litre', 'packet', 'box'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Naya Item Add Karo',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item ka naam *'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Daam (₹) *',
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
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Abhi kitna stock hai',
                suffixText: 'units',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                final priceText = _priceCtrl.text.trim();
                if (name.isEmpty || priceText.isEmpty) return;

                final pricePaisa =
                    KCurrency.parseRupees(priceText);
                final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

                final svc = ItemService();
                await svc.createItem(
                  name: name,
                  pricePaisa: pricePaisa,
                  stock: stock,
                  unit: _unit,
                );
                widget.onAdded();
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Karo'),
            ),
          ],
        ),
      ),
    );
  }
}
