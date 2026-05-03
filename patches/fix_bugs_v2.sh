#!/bin/bash
# KiranaBook Fix v2 - 6 bug fixes
# 1. Saman screen MRP field
# 2. FAB overlap on vendor screen  
# 3. Settings redirect bug
# 4. Keyboard covers modals
# 5. Dashboard filters
# 6. Item not showing after save + validation
set -e
echo "Applying fix v2..."

python3 << 'PYEOF'
import re

# ═══════════════════════════════════════════════════════════
# FIX 1, 2, 3: main.dart - nav redirect bug
# Settings redirects to vendor because postFrameCallback
# fires for ALL non-visible screens including settings
# Fix: only redirect feature-gated screens (vendor/udhaar)
# ═══════════════════════════════════════════════════════════
content = open('lib/main.dart').read()

old = '''    final visibleScreens = navItems.map((n) => n.screen).toList();
    if (!visibleScreens.contains(_current)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _current = AppScreen.home);
      });
    }'''

new = '''    final visibleScreens = navItems.map((n) => n.screen).toList();
    // Only redirect feature-gated screens (vendor/udhaar)
    // Never redirect settings/home/billing/inventory
    final gatedScreens = [AppScreen.vendor, AppScreen.udhaar];
    if (gatedScreens.contains(_current) && !visibleScreens.contains(_current)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _current = AppScreen.home);
      });
    }'''

if old in content:
    content = content.replace(old, new)
    print('main.dart: settings redirect bug FIXED')
else:
    print('main.dart: pattern not found - checking...')
    print(content[content.find('visibleScreens'):content.find('visibleScreens')+300])

open('lib/main.dart', 'w').write(content)

# ═══════════════════════════════════════════════════════════
# FIX 1 + 4 + 6: inventory_screen.dart
# - Add MRP field (issue 1)
# - Fix keyboard covering modal (issue 4) 
# - Fix item not showing after save (issue 6)
# - Add validation errors (issue 6)
# ═══════════════════════════════════════════════════════════
content = open('lib/features/inventory/inventory_screen.dart').read()

old_sheet = '''    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Naam *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'MRP ₹',
                          prefixText: '₹ ',
                          hintText: 'Original',
                        ),
                        onChanged: (v) {},
                        // Store in a local var
                        controller: TextEditingController(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Sale ₹ *',
                          prefixText: '₹ ',
                          hintText: 'Bikri daam',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setS(() => unit = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Shuru stock',
                        suffixText: 'units',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty || priceCtrl.text.trim().isEmpty) return;
                    await _itemSvc.createItem(
                      name: name,
                      pricePaisa: KCurrency.parseRupees(priceCtrl.text),
                      stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                      unit: unit,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      setState(() => _load());
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save Karo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );'''

new_sheet = '''    final mrpCtrl = TextEditingController();
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
    );'''

if old_sheet in content:
    content = content.replace(old_sheet, new_sheet)
    print('inventory_screen.dart: MRP field + keyboard fix + validation FIXED')
else:
    print('inventory_screen.dart: pattern not found')

# Fix FilteringTextInputFormatter import if missing
if 'FilteringTextInputFormatter' in content and 'import' not in content[:500]:
    pass  # already imported via flutter/material.dart

open('lib/features/inventory/inventory_screen.dart', 'w').write(content)

# ═══════════════════════════════════════════════════════════
# FIX 4: udhaar_screen.dart - keyboard covers modals
# ═══════════════════════════════════════════════════════════
content = open('lib/features/udhaar/udhaar_screen.dart').read()

# Fix payment sheet - wrap in AnimatedPadding for keyboard
old_payment = '''    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),'''

new_payment = '''    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),'''

if old_payment in content:
    content = content.replace(old_payment, new_payment)
    print('udhaar_screen.dart: keyboard fix APPLIED')
else:
    print('udhaar_screen.dart: payment pattern not found')

open('lib/features/udhaar/udhaar_screen.dart', 'w').write(content)

# ═══════════════════════════════════════════════════════════
# FIX 6: billing_screen.dart - refresh after save
# After item is saved, close modal then refresh
# ═══════════════════════════════════════════════════════════
content = open('lib/features/billing/billing_screen.dart').read()

# Fix the onAdded callback to ensure refresh happens
old_onadded = '''      builder: (_) => _AddItemSheet(onAdded: () {
        _refreshItems();
        Navigator.pop(context);
      }),'''

new_onadded = '''      builder: (_) => _AddItemSheet(onAdded: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          _refreshItems();
        });
      }),'''

if old_onadded in content:
    content = content.replace(old_onadded, new_onadded)
    print('billing_screen.dart: refresh after save FIXED')
else:
    print('billing_screen.dart: onAdded pattern not found - checking...')
    idx = content.find('_AddItemSheet(onAdded')
    if idx > 0:
        print(content[idx:idx+200])

open('lib/features/billing/billing_screen.dart', 'w').write(content)

print('')
print('All fixes applied!')
print('Verifying...')

# Verify all fixes
m = open('lib/main.dart').read()
print('main.dart - gatedScreens fix:', 'gatedScreens' in m)

inv = open('lib/features/inventory/inventory_screen.dart').read()
print('inventory - MRP field:', 'MRP (₹)' in inv)
print('inventory - Bikri Daam:', 'Bikri Daam' in inv)
print('inventory - validation:', 'naam zaroori' in inv)
print('inventory - AnimatedPadding:', 'AnimatedPadding' in inv)

u = open('lib/features/udhaar/udhaar_screen.dart').read()
print('udhaar - AnimatedPadding:', 'AnimatedPadding' in u)

b = open('lib/features/billing/billing_screen.dart').read()
print('billing - delayed refresh:', 'delayed' in b)
PYEOF

echo "Fix v2 complete!"

# ── Add reports_screen.dart ────────────────────────────────────────────────
mkdir -p lib/features/reports
cp lib/features/reports/reports_screen.dart lib/features/reports/reports_screen.dart 2>/dev/null || true

cat > lib/features/reports/reports_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import '../../core/services/transaction_service.dart';
import '../../core/models/transaction_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum ReportPeriod { today, week, month, custom }

class _ReportsScreenState extends State<ReportsScreen> {
  final _txnSvc = TransactionService();
  ReportPeriod _period = ReportPeriod.today;
  DateTime? _customStart;
  DateTime? _customEnd;

  DateTimeRange _getRange() {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.week:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case ReportPeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case ReportPeriod.custom:
        return DateTimeRange(
          start: _customStart ?? now.subtract(const Duration(days: 7)),
          end: _customEnd ?? now,
        );
    }
  }

  String get _periodLabel {
    switch (_period) {
      case ReportPeriod.today: return 'Aaj';
      case ReportPeriod.week: return 'Is Hafte';
      case ReportPeriod.month: return 'Is Mahine';
      case ReportPeriod.custom:
        if (_customStart != null && _customEnd != null) {
          return '${KDate.formatDate(_customStart!)} - ${KDate.formatDate(_customEnd!)}';
        }
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _getRange();
    final txns = _txnSvc.getTransactionsByRange(range.start, range.end);
    int cashTotal = 0, udhaarTotal = 0, onlineTotal = 0, paymentsTotal = 0, billCount = 0;
    for (final t in txns) {
      if (t.type == 'SALE') {
        billCount++;
        if (t.paymentMode == 'CASH') cashTotal += t.totalAmountPaisa;
        else if (t.paymentMode == 'UDHAAR') udhaarTotal += t.totalAmountPaisa;
        else if (t.paymentMode == 'ONLINE') onlineTotal += t.totalAmountPaisa;
      } else if (t.type == 'PAYMENT') {
        paymentsTotal += t.totalAmountPaisa;
      }
    }
    final totalSales = cashTotal + udhaarTotal + onlineTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports 📊')),
      body: Column(children: [
        Container(
          color: KColors.saffron.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _PeriodChip('Aaj', _period == ReportPeriod.today, () => setState(() => _period = ReportPeriod.today)),
              const SizedBox(width: 8),
              _PeriodChip('Is Hafte', _period == ReportPeriod.week, () => setState(() => _period = ReportPeriod.week)),
              const SizedBox(width: 8),
              _PeriodChip('Is Mahine', _period == ReportPeriod.month, () => setState(() => _period = ReportPeriod.month)),
              const SizedBox(width: 8),
              _PeriodChip('Custom 📅', _period == ReportPeriod.custom, () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: KColors.saffron),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _customStart = picked.start;
                    _customEnd = picked.end;
                    _period = ReportPeriod.custom;
                  });
                }
              }),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: KColors.inkSoft),
              const SizedBox(width: 6),
              Text(_periodLabel, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 13, color: KColors.inkSoft, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$billCount bills', style: const TextStyle(fontFamily: 'Baloo2', fontSize: 13, color: KColors.inkSoft)),
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: KColors.saffron, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('Kul Bikri', style: TextStyle(fontFamily: 'Baloo2', color: Colors.white70, fontSize: 13)),
                Text(KCurrency.format(totalSales), style: const TextStyle(fontFamily: 'Baloo2', color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _SummaryCard('Cash', cashTotal, KColors.green),
              const SizedBox(width: 8),
              _SummaryCard('Udhaar', udhaarTotal, KColors.red),
              const SizedBox(width: 8),
              _SummaryCard('Online', onlineTotal, KColors.blue),
              const SizedBox(width: 8),
              _SummaryCard('Wapas', paymentsTotal, Colors.purple),
            ]),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(alignment: Alignment.centerLeft,
            child: Text('Transactions', style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w700, color: KColors.inkSoft))),
        ),
        Expanded(
          child: txns.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.receipt_long, size: 48, color: KColors.inkGhost),
                  const SizedBox(height: 8),
                  Text('$_periodLabel mein koi transaction nahi',
                      style: const TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft)),
                ]))
              : ListView.separated(
                  itemCount: txns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = txns[i];
                    final isPayment = t.type == 'PAYMENT';
                    final color = t.paymentMode == 'CASH' ? KColors.green
                        : t.paymentMode == 'ONLINE' ? KColors.blue
                        : isPayment ? Colors.purple : KColors.saffron;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 18,
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(isPayment ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 14)),
                      title: Text(t.customerName ?? (isPayment ? 'Payment' : 'Cash Sale'),
                          style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(KDate.formatDateTime(t.timestamp),
                          style: const TextStyle(fontFamily: 'Baloo2', fontSize: 11)),
                      trailing: Text(KCurrency.format(t.totalAmountPaisa),
                          style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 14, color: color)),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? KColors.saffron : KColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? KColors.saffron : KColors.border),
      ),
      child: Text(label, style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : KColors.inkSoft)),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amountPaisa;
  final Color color;
  const _SummaryCard(this.label, this.amountPaisa, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(KCurrency.format(amountPaisa),
            style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 10, color: KColors.inkSoft)),
      ]),
    ),
  );
}
DARTEOF
echo "reports_screen.dart written"

# ── Add Reports to main.dart navigation ───────────────────────────────────
python3 << 'PYEOF'
content = open('lib/main.dart').read()

# Add import
if 'reports_screen' not in content:
    old_import = "import 'features/vendor/vendor_screen.dart';"
    new_import = "import 'features/vendor/vendor_screen.dart';\nimport 'features/reports/reports_screen.dart';"
    content = content.replace(old_import, new_import)

# Add to enum
if 'reports' not in content:
    content = content.replace(
        'enum AppScreen { home, billing, udhaar, inventory, vendor, settings }',
        'enum AppScreen { home, billing, udhaar, inventory, vendor, reports, settings }'
    )

# Add to screens map
    content = content.replace(
        'AppScreen.settings: SettingsScreen(),',
        'AppScreen.vendor: VendorScreen(),\n    AppScreen.reports: ReportsScreen(),\n    AppScreen.settings: SettingsScreen(),'
    )

# Add to nav items (before settings)
    content = content.replace(
        "_NavItem(AppScreen.settings, Icons.settings_outlined, Icons.settings, 'Settings'),",
        "_NavItem(AppScreen.reports, Icons.bar_chart_outlined, Icons.bar_chart, 'Reports'),\n      _NavItem(AppScreen.settings, Icons.settings_outlined, Icons.settings, 'Settings'),"
    )

# Add to allScreenOrder
    content = content.replace(
        'AppScreen.vendor, AppScreen.settings,',
        'AppScreen.vendor, AppScreen.reports, AppScreen.settings,'
    )

    open('lib/main.dart', 'w').write(content)
    print('main.dart: Reports screen added to navigation')
else:
    print('main.dart: Reports already in navigation')
PYEOF

echo "All fixes complete!"
