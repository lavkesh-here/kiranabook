import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/hive_db.dart';
import '../../core/services/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final store = HiveDB.store.get('store_001');
    if (store != null) {
      _nameCtrl.text = store.name;
      _ownerCtrl.text = store.ownerName;
      _phoneCtrl.text = store.phone;
    }
    setState(() {});
  }

  Future<void> _save() async {
    final store = HiveDB.store.get('store_001');
    if (store == null) return;
    store.name = _nameCtrl.text.trim();
    store.ownerName = _ownerCtrl.text.trim();
    store.phone = _phoneCtrl.text.trim();
    store.isSetupDone = true;
    await store.save();
    setState(() => _editing = false);
    HapticFeedback.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✓ Settings save ho gayi!', style: TextStyle(fontFamily: 'Baloo2')),
        backgroundColor: KColors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final txnCount = HiveDB.transactions.length;
    final itemCount = HiveDB.items.length;
    final customerCount = HiveDB.customers.length;
    final vendorCount = HiveDB.vendors.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings ⚙️'),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editing = true))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Shop info
          _SectionHeader('Dukaan ki Jaankari'),
          const SizedBox(height: 8),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _editing
                  ? TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Dukaan ka Naam'))
                  : _InfoRow('Dukaan', HiveDB.store.get('store_001')?.name ?? '-'),
              const SizedBox(height: 10),
              _editing
                  ? TextField(controller: _ownerCtrl, decoration: const InputDecoration(labelText: 'Maalik ka Naam'))
                  : _InfoRow('Maalik', HiveDB.store.get('store_001')?.ownerName ?? '-'),
              const SizedBox(height: 10),
              _editing
                  ? TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone / WhatsApp'))
                  : _InfoRow('Phone', HiveDB.store.get('store_001')?.phone ?? '-'),
            ]),
          )),

          if (_editing) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Save Karo')),
          ],

          const SizedBox(height: 24),

          // Stats
          _SectionHeader('Aapke Numbers'),
          const SizedBox(height: 8),
          Row(children: [
            _StatCard(icon: Icons.receipt_long, value: '$txnCount', label: 'Bills', color: KColors.saffron),
            const SizedBox(width: 8),
            _StatCard(icon: Icons.inventory_2, value: '$itemCount', label: 'Items', color: KColors.green),
            const SizedBox(width: 8),
            _StatCard(icon: Icons.people, value: '$customerCount', label: 'Customers', color: KColors.blue),
            const SizedBox(width: 8),
            _StatCard(icon: Icons.store, value: '$vendorCount', label: 'Vendors', color: Colors.purple),
          ]),

          const SizedBox(height: 24),

          // Feature flags
          _SectionHeader('Features On/Off karo'),
          const SizedBox(height: 4),
          const Text('Yeh changes turant apply hote hain, app reload ki zarurat nahi',
              style: TextStyle(fontFamily: 'Baloo2', fontSize: 11, color: KColors.inkSoft)),
          const SizedBox(height: 8),
          Card(child: Column(children: [
            _FeatureToggle(
              icon: Icons.people,
              title: 'Customer Management',
              subtitle: 'Udhaar khata aur customer list',
              value: settings.customerManagementEnabled,
              onChanged: (v) => notifier.setCustomer(v),
            ),
            const Divider(height: 1),
            _FeatureToggle(
              icon: Icons.inventory_2,
              title: 'Stock Management',
              subtitle: 'Saman ka hisaab aur low stock alerts',
              value: settings.stockManagementEnabled,
              onChanged: (v) => notifier.setStock(v),
            ),
            const Divider(height: 1),
            _FeatureToggle(
              icon: Icons.store,
              title: 'Vendor Management',
              subtitle: 'Vendor ledger aur order history',
              value: settings.vendorManagementEnabled,
              onChanged: (v) => notifier.setVendor(v),
            ),
            const Divider(height: 1),
            _FeatureToggle(
              icon: Icons.phone_android,
              title: 'Online Payment Option',
              subtitle: 'Bill mein online payment button dikhao',
              value: settings.onlinePaymentEnabled,
              onChanged: (v) => notifier.setOnlinePayment(v),
            ),
            const Divider(height: 1),
            _FeatureToggle(
              icon: Icons.alarm,
              title: 'Udhaar Reminders',
              subtitle: 'Home screen par reminder dikhaao',
              value: settings.remindersEnabled,
              onChanged: (v) => notifier.setReminders(v),
            ),
            const Divider(height: 1),
            _FeatureToggle(
              icon: Icons.bar_chart,
              title: 'Weekly Reports',
              subtitle: 'Hafte ka hisaab aur bar chart',
              value: settings.weeklyReportsEnabled,
              onChanged: (v) => notifier.setWeeklyReports(v),
            ),
          ])),

          const SizedBox(height: 24),

          // Offline status
          _SectionHeader('Data ki Hifazat'),
          const SizedBox(height: 8),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Container(width: 10, height: 10,
                    decoration: const BoxDecoration(color: KColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Sab kuch phone mein safe hai (Offline)',
                    style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 8),
              const Text('💡 Internet na ho tab bhi kaam karta hai.',
                  style: TextStyle(fontFamily: 'Baloo2', fontSize: 12, color: KColors.inkSoft)),
            ]),
          )),

          const SizedBox(height: 24),

          // Danger zone
          _SectionHeader('Savdhani'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showClearDataDialog(context),
            icon: const Icon(Icons.delete_outline, color: KColors.red),
            label: const Text('Sab Data Delete Karo', style: TextStyle(color: KColors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: KColors.red),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KColors.card,
        title: const Text('⚠️ Pakka Delete karna hai?',
            style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, color: KColors.red)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Yeh delete hoga:', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _DeletePoint('Sab bills aur transactions'),
          _DeletePoint('Sab customers aur udhaar'),
          _DeletePoint('Sab vendors aur orders'),
          _DeletePoint('Sab stock history'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: KColors.redPale, borderRadius: BorderRadius.circular(8)),
            child: const Text('❌ Yeh wapas NAHI aayega!\nPhone ka backup nahi hai.',
                style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, color: KColors.red, fontSize: 13)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await HiveDB.clearAll();
              if (context.mounted) { Navigator.pop(context); _load(); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: KColors.red),
            child: const Text('Haan, Delete Karo'),
          ),
        ],
      ),
    );
  }
}

class _DeletePoint extends StatelessWidget {
  final String text;
  const _DeletePoint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      const Icon(Icons.close, color: KColors.red, size: 14),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 13)),
    ]),
  );
}

class _FeatureToggle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final Function(bool) onChanged;
  const _FeatureToggle({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: value ? KColors.saffron : KColors.inkGhost, size: 22),
    title: Text(title, style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 13)),
    subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 11)),
    trailing: Switch(value: value, onChanged: onChanged, activeColor: KColors.saffron),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontFamily: 'Baloo2', fontSize: 12, fontWeight: FontWeight.w700, color: KColors.inkSoft, letterSpacing: 0.5));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label: ', style: const TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft, fontSize: 13)),
    Text(value, style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 14)),
  ]);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 9, color: KColors.inkSoft)),
      ]),
    ),
  );
}
