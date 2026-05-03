#!/bin/bash
# Fix: Add MRP field to billing screen add item sheet
set -e
echo "Applying billing screen MRP fix..."

python3 << 'PYEOF'
content = open('lib/features/billing/billing_screen.dart').read()

# Print current state for debugging
import re
idx = content.find('class _AddItemSheet')
if idx == -1:
    print("ERROR: _AddItemSheet class not found")
    exit(1)

print(f"Found _AddItemSheet at position {idx}")
print("Current class preview:")
print(content[idx:idx+300])
print("---")

# Find the State class
idx2 = content.find('class _AddItemSheetState')
if idx2 == -1:
    print("ERROR: _AddItemSheetState not found")
    exit(1)

# Find the end of the file (last closing brace)
# Replace entire _AddItemSheetState class
new_class = '''class _AddItemSheetState extends State<_AddItemSheet> {
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
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Item naam (English) *',
                    hintText: 'e.g. Maggi'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameHindiCtrl,
                decoration: const InputDecoration(
                    labelText: 'Item naam (Hindi) - optional',
                    hintText: 'e.g. मैगी'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _mrpCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [LengthLimitingTextInputFormatter(7)],
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
              TextField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [LengthLimitingTextInputFormatter(7)],
                decoration: const InputDecoration(
                  labelText: 'Bikri Daam (₹) *',
                  prefixText: '₹ ',
                  hintText: 'Selling price',
                  helperText: 'Yeh daam bill mein dikhega',
                ),
              ),
              const SizedBox(height: 10),
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
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Item naam zaroori hai!',
                                    style: TextStyle(fontFamily: 'Baloo2')),
                                backgroundColor: KColors.red),
                          );
                          return;
                        }
                        if (priceText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Bikri daam daalna zaroori hai!',
                                    style: TextStyle(fontFamily: 'Baloo2')),
                                backgroundColor: KColors.red),
                          );
                          return;
                        }
                        setState(() => _isSaving = true);
                        try {
                          final pricePaisa =
                              KCurrency.parseRupees(priceText);
                          final mrpPaisa =
                              _mrpCtrl.text.trim().isEmpty
                                  ? 0
                                  : KCurrency.parseRupees(_mrpCtrl.text);
                          final stock =
                              int.tryParse(_stockCtrl.text.trim()) ?? 0;
                          await ItemService().createItem(
                            name: name,
                            nameHindi: _nameHindiCtrl.text.trim().isEmpty
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
                label: Text(_isSaving ? 'Save ho raha hai...' : 'Save Karo'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}'''

# Replace from _AddItemSheetState to end of file
content = content[:idx2] + new_class + '\n'
open('lib/features/billing/billing_screen.dart', 'w').write(content)
print("billing_screen.dart: MRP field + save fix applied")

# Verify
result = open('lib/features/billing/billing_screen.dart').read()
print("MRP field present:", '_mrpCtrl' in result)
print("Bikri Daam present:", 'Bikri Daam' in result)
print("Save fix present:", '_isSaving' in result)
PYEOF

echo "Done!"
