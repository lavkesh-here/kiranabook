import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/hive_db.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/item_service.dart';
import '../../core/services/share_service.dart';
import '../../core/services/app_settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/transaction_model.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});
  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen>
    with SingleTickerProviderStateMixin {
  late TransactionService _txnSvc;
  late ItemService _itemSvc;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _txnSvc = TransactionService();
    _itemSvc = ItemService();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final summary = _txnSvc.getDailySummary();
    final todayTxns = _txnSvc.getTodayTransactions();
    final lowStockItems = _itemSvc.getLowStockItems();
    final reminders = settings.remindersEnabled ? _txnSvc.getDueReminders() : [];
    final weekly = settings.weeklyReportsEnabled ? _txnSvc.getWeeklySummary() : null;
    final store = HiveDB.store.get('store_001');

    int totalOutstanding = 0;
    for (final c in HiveDB.customers.values) {
      totalOutstanding += _txnSvc.getCustomerBalance(c.id);
    }

    return Scaffold(
      body: RefreshIndicator(
        color: KColors.saffron,
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: KColors.saffron,
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
              tabs: const [Tab(text: 'Aaj'), Tab(text: 'Hafte ka')],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [KColors.saffron, Color(0xFFFF8C35)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      const Icon(Icons.store, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(store?.name ?? 'Meri Dukaan',
                            style: const TextStyle(fontFamily: 'Baloo2', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      Text(KDate.formatDate(DateTime.now()),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Baloo2')),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _tabCtrl.index == 0
                ? _buildTodayTab(summary, todayTxns, lowStockItems, reminders, totalOutstanding)
                : _buildWeeklyTab(weekly),
          ),
        ]),
      ),
    );
  }

  Widget _buildTodayTab(dynamic summary, List<TransactionModel> todayTxns,
      dynamic lowStockItems, List reminders, int totalOutstanding) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary cards
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Aaj Ka Hisaab',
              style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w700, color: KColors.inkSoft)),
          const SizedBox(height: 8),
          Row(children: [
            _SummaryCard(label: 'Cash', value: KCurrency.format(summary.cashTotal), icon: Icons.currency_rupee, color: KColors.green),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Udhaar', value: KCurrency.format(summary.udhaarTotal), icon: Icons.edit_note, color: KColors.saffron),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Online', value: KCurrency.format(summary.onlineTotal), icon: Icons.phone_android, color: KColors.blue),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _SummaryCard(label: 'Bills', value: '${summary.billCount}', icon: Icons.receipt, color: KColors.blue),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Kul Baaki', value: KCurrency.format(totalOutstanding), icon: Icons.people, color: KColors.red),
            const SizedBox(width: 8),
            _SummaryCard(label: 'Kul Bikri', value: KCurrency.format(summary.totalSales), icon: Icons.trending_up, color: Colors.purple),
          ]),
        ]),
      ),

      // Low stock alert
      if (lowStockItems.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KColors.yellowPale, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KColors.yellow),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: KColors.yellow, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ ${lowStockItems.length} item ka stock kam: ${lowStockItems.map((i) => i.name).take(3).join(", ")}',
                  style: const TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF856000)),
                ),
              ),
            ]),
          ),
        ),

      // Reminders section
      if (reminders.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('🔔 Aaj ke Reminders',
              style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w700, color: KColors.inkSoft)),
        ),
        const SizedBox(height: 8),
        ...reminders.map((txn) => _ReminderCard(txn: txn)),
      ],

      const SizedBox(height: 12),

      // Today transactions
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('Aaj ke Transactions',
            style: TextStyle(fontFamily: 'Baloo2', fontSize: 13, fontWeight: FontWeight.w700, color: KColors.inkSoft)),
      ),
      const SizedBox(height: 8),

      if (todayTxns.isEmpty)
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Column(children: [
            Icon(Icons.receipt_long, size: 48, color: KColors.inkGhost),
            const SizedBox(height: 12),
            const Text('Aaj koi bill nahi\nPehla bill banao!',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Baloo2', fontSize: 14, color: KColors.inkSoft)),
          ])),
        )
      else
        ...todayTxns.map((txn) => _TransactionTile(txn: txn, onTap: () => _showTxnDetails(context, txn))),

      const SizedBox(height: 80),
    ]);
  }

  Widget _buildWeeklyTab(dynamic weekly) {
    if (weekly == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Weekly reports disabled hai settings mein',
            style: TextStyle(fontFamily: 'Baloo2', color: KColors.inkSoft))),
      );
    }

    final now = DateTime.now();
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Is Hafte ka Hisaab',
            style: TextStyle(fontFamily: 'Baloo2', fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        // Bar chart
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final day = now.subtract(Duration(days: 6 - i));
            final d = weekly.days[i];
            final maxVal = weekly.days.map((d) => d.totalSales).fold(1, (a, b) => a > b ? a : b);
            final height = maxVal > 0 ? (d.totalSales / maxVal * 120).toDouble() : 4.0;
            final isToday = i == 6;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(children: [
                  Text(KCurrency.format(d.totalSales),
                      style: TextStyle(fontFamily: 'Baloo2', fontSize: 8,
                          color: isToday ? KColors.saffron : KColors.inkSoft)),
                  const SizedBox(height: 2),
                  Container(
                    height: height.clamp(4.0, 120.0),
                    decoration: BoxDecoration(
                      color: isToday ? KColors.saffron : KColors.saffron.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(days[day.weekday - 1],
                      style: TextStyle(fontFamily: 'Baloo2', fontSize: 10,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                          color: isToday ? KColors.saffron : KColors.inkSoft)),
                ]),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // Weekly totals
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KColors.saffronPale, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KColors.saffron.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _WeekStat('Kul Bikri', KCurrency.format(weekly.totalSales), KColors.saffron),
            _WeekStat('Cash', KCurrency.format(weekly.totalCash), KColors.green),
            _WeekStat('Udhaar', KCurrency.format(weekly.totalUdhaar), KColors.red),
          ]),
        ),
      ]),
    );
  }

  void _showTxnDetails(BuildContext ctx, TransactionModel txn) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _TxnDetailSheet(txn: txn),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _WeekStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontFamily: 'Baloo2', fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 11, color: KColors.inkSoft)),
  ]);
}

class _ReminderCard extends StatelessWidget {
  final TransactionModel txn;
  const _ReminderCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isOverdue = txn.reminderDate!.isBefore(DateTime.now());
    final store = HiveDB.store.get('store_001');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue ? KColors.redPale : KColors.yellowPale,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOverdue ? KColors.red : KColors.yellow),
        ),
        child: Row(children: [
          Icon(isOverdue ? Icons.alarm_off : Icons.alarm,
              color: isOverdue ? KColors.red : KColors.yellow, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(txn.customerName ?? 'Customer',
                style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 13)),
            Text(
              '${KCurrency.format(txn.totalAmountPaisa)} • ${isOverdue ? "Overdue" : "Aaj due"}: ${KDate.formatDate(txn.reminderDate!)}',
              style: TextStyle(fontFamily: 'Baloo2', fontSize: 11,
                  color: isOverdue ? KColors.red : const Color(0xFF856000)),
            ),
          ])),
          Row(children: [
            // WhatsApp button
            GestureDetector(
              onTap: () {
                final msg = '🙏 Namaste ${txn.customerName ?? ""}!\n'
                    '${store?.name ?? "Dukaan"} se yaad dila rahe hain.\n'
                    'Aapka baaki: ${KCurrency.format(txn.totalAmountPaisa)}\n'
                    'Jab bhi ho sake, payment kar dena. Dhanyavaad! 🙏';
                ShareService.shareViaWhatsApp(msg, phone: _getPhone(txn.customerId));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(8)),
                child: const Text('WA', style: TextStyle(color: Colors.white, fontFamily: 'Baloo2', fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 4),
            // SMS button
            GestureDetector(
              onTap: () {
                final msg = 'Namaste ${txn.customerName ?? ""}! '
                    '${store?.name ?? "Dukaan"} se: Aapka baaki ${KCurrency.format(txn.totalAmountPaisa)} hai. Dhanyavaad!';
                ShareService.shareText(msg);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KColors.blue, borderRadius: BorderRadius.circular(8)),
                child: const Text('SMS', style: TextStyle(color: Colors.white, fontFamily: 'Baloo2', fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String? _getPhone(String? customerId) {
    if (customerId == null) return null;
    return HiveDB.customers.get(customerId)?.phone;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontFamily: 'Baloo2', fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 10, fontWeight: FontWeight.w600, color: KColors.inkSoft)),
      ]),
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  final VoidCallback onTap;
  const _TransactionTile({required this.txn, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isCash = txn.paymentMode == 'CASH';
    final isOnline = txn.paymentMode == 'ONLINE';
    final isPayment = txn.type == 'PAYMENT';
    final isUdhaar = txn.paymentMode == 'UDHAAR';

    Color amountColor = isCash ? KColors.green : isOnline ? KColors.blue : isPayment ? KColors.green : KColors.saffron;
    Color avatarColor = isCash ? KColors.greenPale : isOnline ? KColors.bluePale : isPayment ? KColors.bluePale : KColors.saffronPale;
    IconData icon = isCash ? Icons.currency_rupee : isOnline ? Icons.phone_android : isPayment ? Icons.arrow_downward : Icons.edit_note;

    String title = (isPayment || txn.customerId != null) ? (txn.customerName ?? 'Customer') : 'Cash Sale';
    String subtitle = txn.items.isNotEmpty ? txn.items.map((i) => '${i.name}×${i.qty}').join(', ') : (txn.note ?? '');
    if (subtitle.length > 40) subtitle = '${subtitle.substring(0, 40)}...';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: amountColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 14, fontWeight: FontWeight.w700)),
              if (isUdhaar && txn.reminderDate != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.alarm, size: 12, color: KColors.yellow),
              ],
            ]),
            Text(subtitle, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 12, color: KColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${isPayment ? "+" : ""}${KCurrency.format(txn.totalAmountPaisa)}',
                style: TextStyle(fontFamily: 'Baloo2', fontSize: 15, fontWeight: FontWeight.w800, color: amountColor)),
            Text(KDate.formatTime(txn.timestamp),
                style: const TextStyle(fontFamily: 'Baloo2', fontSize: 11, color: KColors.inkGhost)),
          ]),
        ]),
      ),
    );
  }
}

class _TxnDetailSheet extends StatelessWidget {
  final TransactionModel txn;
  const _TxnDetailSheet({required this.txn});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: KColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text(txn.type == 'PAYMENT' ? 'Payment Mili' : 'Bill Details',
              style: const TextStyle(fontFamily: 'Baloo2', fontSize: 18, fontWeight: FontWeight.w700)),
          Text(KDate.formatDateTime(txn.timestamp),
              style: const TextStyle(fontFamily: 'Baloo2', fontSize: 13, color: KColors.inkSoft)),
          const SizedBox(height: 12),
          if (txn.customerName != null)
            Text('Customer: ${txn.customerName}', style: const TextStyle(fontFamily: 'Baloo2')),
          if (txn.type == 'SALE') ...[
            const SizedBox(height: 8),
            ...txn.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(child: Text('${item.name} × ${item.qty}', style: const TextStyle(fontFamily: 'Baloo2'))),
                Text(KCurrency.format(item.totalPaisa), style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
              ]),
            )),
            const Divider(),
          ],
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Kul Raqam', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 16)),
            Text(KCurrency.format(txn.totalAmountPaisa),
                style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: 20, color: KColors.saffron)),
          ]),
          if (txn.reminderDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.alarm, size: 14, color: KColors.yellow),
                const SizedBox(width: 4),
                Text('Reminder: ${KDate.formatDate(txn.reminderDate!)}',
                    style: const TextStyle(fontFamily: 'Baloo2', fontSize: 12, color: KColors.yellow)),
              ]),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
