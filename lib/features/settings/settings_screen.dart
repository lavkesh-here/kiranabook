import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/db/hive_db.dart';
import '../../core/models/store_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StoreModel? _store;
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _store = HiveDB.store.get('store_001');
    if (_store != null) {
      _nameCtrl.text = _store!.name;
      _ownerCtrl.text = _store!.ownerName;
      _phoneCtrl.text = _store!.phone;
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_store == null) return;
    _store!.name = _nameCtrl.text.trim();
    _store!.ownerName = _ownerCtrl.text.trim();
    _store!.phone = _phoneCtrl.text.trim();
    _store!.isSetupDone = true;
    await _store!.save();
    setState(() => _editing = false);
    HapticFeedback.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✓ Settings save ho gayi!',
            style: TextStyle(fontFamily: 'Baloo2'),
          ),
          backgroundColor: KColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final txnCount = HiveDB.transactions.length;
    final itemCount = HiveDB.items.length;
    final customerCount = HiveDB.customers.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings ⚙️'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop info
            _SectionHeader('Dukaan ki Jaankari'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _editing
                        ? TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Dukaan ka Naam',
                            ),
                          )
                        : _InfoRow('Dukaan', _store?.name ?? '-'),
                    const SizedBox(height: 12),
                    _editing
                        ? TextField(
                            controller: _ownerCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Maalik ka Naam',
                            ),
                          )
                        : _InfoRow('Maalik', _store?.ownerName ?? '-'),
                    const SizedBox(height: 12),
                    _editing
                        ? TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixText: '+91 ',
                            ),
                          )
                        : _InfoRow('Phone', _store?.phone ?? '-'),
                  ],
                ),
              ),
            ),

            if (_editing) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save Karo'),
              ),
            ],

            const SizedBox(height: 24),

            // Stats
            _SectionHeader('Aapke Numbers'),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatCard(
                  icon: Icons.receipt_long,
                  value: '$txnCount',
                  label: 'Bills',
                  color: KColors.saffron,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.inventory_2,
                  value: '$itemCount',
                  label: 'Items',
                  color: KColors.green,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.people,
                  value: '$customerCount',
                  label: 'Customers',
                  color: KColors.blue,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sync status
            _SectionHeader('Data ki Hifazat'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: KColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Sab kuch phone mein safe hai\n(Offline storage active)',
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '💡 Aapka data pehle phone mein save hota hai. '
                      'Internet na ho tab bhi kaam karta hai.',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 12,
                        color: KColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // About
            _SectionHeader('App ke Baare Mein'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _ListItem(
                    icon: Icons.info_outline,
                    title: 'Version',
                    subtitle: 'KiranaBook v1.0.0',
                  ),
                  const Divider(height: 1),
                  _ListItem(
                    icon: Icons.lock_outline,
                    title: 'Privacy',
                    subtitle: 'Aapka data sirf aapke phone mein',
                  ),
                  const Divider(height: 1),
                  _ListItem(
                    icon: Icons.wifi_off,
                    title: 'Offline Mode',
                    subtitle: 'Internet ke bina bhi kaam karta hai',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Danger zone
            _SectionHeader('Savdhani'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showClearDataDialog(context),
              icon: const Icon(Icons.delete_outline, color: KColors.red),
              label: const Text(
                'Sab Data Delete Karo',
                style: TextStyle(color: KColors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: KColors.red),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '⚠️ Pakka?',
          style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Sab transactions, customers, aur items delete ho jayenge. '
          'Yeh wapas nahi aayega!',
          style: TextStyle(fontFamily: 'Baloo2'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await HiveDB.clearAll();
              await HiveDB.init(); // re-seed
              if (context.mounted) {
                Navigator.pop(context);
                _load();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KColors.red,
            ),
            child: const Text('Haan, Delete Karo'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Baloo2',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: KColors.inkSoft,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Baloo2',
            color: KColors.inkSoft,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 10,
                color: KColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: KColors.inkSoft, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 12,
        ),
      ),
    );
  }
}
