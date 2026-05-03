import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/item_service.dart';
import '../../core/models/item_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _itemSvc = ItemService();
  final _searchCtrl = TextEditingController();
  List<ItemModel> _items = [];
  bool _showLowOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _load()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final q = _searchCtrl.text;
    var items = q.isEmpty ? _itemSvc.getAllItems() : _itemSvc.searchItems(q);
    if (_showLowOnly) items = items.where((i) => i.isLowStock).toList();
    _items = items;
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _itemSvc.getLowStockItems().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saman ka Hisaab 📦'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _showLowOnly ? Colors.yellowAccent : Colors.white,
            ),
            tooltip: 'Sirf kam stock',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showLowOnly = !_showLowOnly;
                _load();
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context),
        backgroundColor: KColors.saffron,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Naya Item',
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Low stock banner
          if (lowCount > 0)
            Container(
              color: KColors.yellowPale,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: KColors.yellow, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$lowCount items ka stock kam hai',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF856000),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLowOnly = !_showLowOnly;
                        _load();
                      });
                    },
                    child: Text(
                      _showLowOnly ? 'Sab dikhao' : 'Dekhao',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        color: KColors.saffron,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: '🔍 Item dhundho...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Item count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_items.length} items',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 12,
                    color: KColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 56, color: KColors.inkGhost),
                        const SizedBox(height: 12),
                        const Text(
                          'Koi item nahi',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 16,
                            color: KColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddItemSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Item Add Karo'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _InventoryTile(
                      item: _items[i],
                      onAddStock: () => _showAddStockSheet(context, _items[i]),
                      onEdit: () => _showEditSheet(context, _items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddStockSheet(BuildContext context, ItemModel item) {
    HapticFeedback.mediumImpact();
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
              Text(
                '📦 ${item.nameHindi ?? item.name} — Stock Add Karo',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Abhi hai: ${item.stock} ${item.unit}',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  color: KColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Kitna add karna hai?',
                  suffixText: item.unit,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final qty = int.tryParse(ctrl.text.trim()) ?? 0;
                  if (qty <= 0) return;
                  await _itemSvc.addStock(item, qty);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() => _load());
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ $qty ${item.unit} add ho gaya!',
                          style: const TextStyle(fontFamily: 'Baloo2'),
                        ),
                        backgroundColor: KColors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Karo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, ItemModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(
        text: item.priceRupees.toStringAsFixed(
            item.priceRupees == item.priceRupees.truncate() ? 0 : 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
                'Item Edit Karo',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Naam'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Daam (₹)',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        item.name = nameCtrl.text.trim();
                        item.pricePaisa =
                            KCurrency.parseRupees(priceCtrl.text);
                        await _itemSvc.updateItem(item);
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() => _load());
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () async {
                      await _itemSvc.deleteItem(item);
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() => _load());
                      }
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: KColors.red),
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

  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String unit = 'pcs';
    final units = ['pcs', 'kg', 'litre', 'packet', 'box'];

    final mrpCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          bool isSaving = false;
          return AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 150),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
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
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Naam *',
                        hintText: 'e.g. Maggi',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: mrpCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'MRP (₹)',
                            prefixText: '₹ ',
                            hintText: 'Original price',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (v) => setS(() => unit = v!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Bikri Daam (₹) *',
                        prefixText: '₹ ',
                        hintText: 'Selling price',
                        helperText: 'Yeh daam bill mein dikhega',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Shuru stock',
                        suffixText: 'units',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isSaving ? null : () async {
                        final name = nameCtrl.text.trim();
                        final priceText = priceCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Item naam zaroori hai!', style: TextStyle(fontFamily: 'Baloo2')),
                            backgroundColor: KColors.red,
                          ));
                          return;
                        }
                        if (priceText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Bikri daam zaroori hai!', style: TextStyle(fontFamily: 'Baloo2')),
                            backgroundColor: KColors.red,
                          ));
                          return;
                        }
                        setS(() => isSaving = true);
                        await _itemSvc.createItem(
                          name: name,
                          pricePaisa: KCurrency.parseRupees(priceText),
                          mrpPaisa: mrpCtrl.text.trim().isEmpty ? 0 : KCurrency.parseRupees(mrpCtrl.text),
                          stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                          unit: unit,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          setState(() => _load());
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: Text(isSaving ? 'Save ho raha hai...' : 'Save Karo'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onAddStock;
  final VoidCallback onEdit;

  const _InventoryTile({
    required this.item,
    required this.onAddStock,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Color stockColor;
    if (item.stock <= 0) {
      stockColor = KColors.red;
    } else if (item.isLowStock) {
      stockColor = KColors.yellow;
    } else {
      stockColor = KColors.green;
    }

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: stockColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: stockColor.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            item.name[0].toUpperCase(),
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: stockColor,
            ),
          ),
        ),
      ),
      title: Text(
        item.nameHindi ?? item.name,
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${KCurrency.format(item.pricePaisa)} / ${item.unit}',
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 12,
          color: KColors.inkSoft,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.stock}',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: stockColor,
                ),
              ),
              Text(
                item.unit,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 10,
                  color: KColors.inkGhost,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onAddStock,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: KColors.greenPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add,
                      color: KColors.green, size: 18),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: KColors.saffronPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit,
                      color: KColors.saffron, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
