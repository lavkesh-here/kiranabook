import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/hive_db.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/item_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/transaction_model.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  late TransactionService _txnSvc;
  late ItemService _itemSvc;

  @override
  void initState() {
    super.initState();
    _txnSvc = TransactionService();
    _itemSvc = ItemService();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final summary = _txnSvc.getDailySummary();
    final todayTxns = _txnSvc.getTodayTransactions();
    final lowStockItems = _itemSvc.getLowStockItems();
    final store = HiveDB.store.get('store_001');

    // Compute total outstanding udhaar
    int totalOutstanding = 0;
    for (final c in HiveDB.customers.values) {
      totalOutstanding += _txnSvc.getCustomerBalance(c.id);
    }

    return Scaffold(
      body: RefreshIndicator(
        color: KColors.saffron,
        onRefresh: () async => _refresh(),
        child: CustomScrollView(
          slivers: [
            // App bar with shop name
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: KColors.saffron,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [KColors.saffron, Color(0xFFFF8C35)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  store?.name ?? 'Meri Dukaan',
                                  style: const TextStyle(
                                    fontFamily: 'Baloo2',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Saved',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontFamily: 'Baloo2',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            KDate.formatDate(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Baloo2',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's summary cards
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aaj Ka Hisaab',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: KColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SummaryCard(
                              label: 'Cash Mila',
                              value: KCurrency.format(summary.cashTotal),
                              icon: Icons.currency_rupee,
                              color: KColors.green,
                            ),
                            const SizedBox(width: 8),
                            _SummaryCard(
                              label: 'Udhaar Diya',
                              value: KCurrency.format(summary.udhaarTotal),
                              icon: Icons.edit_note,
                              color: KColors.saffron,
                            ),
                            const SizedBox(width: 8),
                            _SummaryCard(
                              label: 'Kul Baaki',
                              value: KCurrency.format(totalOutstanding),
                              icon: Icons.people,
                              color: KColors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SummaryCard(
                              label: 'Aaj Bills',
                              value: '${summary.billCount}',
                              icon: Icons.receipt,
                              color: KColors.blue,
                            ),
                            const SizedBox(width: 8),
                            _SummaryCard(
                              label: 'Kul Bikri',
                              value: KCurrency.format(summary.totalSales),
                              icon: Icons.trending_up,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Container()),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Low stock alert
                  if (lowStockItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KColors.yellowPale,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KColors.yellow),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: KColors.yellow, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠️ ${lowStockItems.length} item ka stock kam hai: '
                                '${lowStockItems.map((i) => i.name).take(3).join(", ")}',
                                style: const TextStyle(
                                  fontFamily: 'Baloo2',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF856000),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Today's transactions
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Aaj ke Transactions',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: KColors.inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (todayTxns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 48, color: KColors.inkGhost),
                            const SizedBox(height: 12),
                            const Text(
                              'Aaj koi bill nahi bana\nPehla bill banao!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Baloo2',
                                fontSize: 14,
                                color: KColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...todayTxns.map(
                      (txn) => _TransactionTile(
                        txn: txn,
                        onTap: () => _showTxnDetails(context, txn),
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTxnDetails(BuildContext context, TransactionModel txn) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TxnDetailSheet(txn: txn),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: KColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  final VoidCallback onTap;

  const _TransactionTile({required this.txn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCash = txn.paymentMode == 'CASH';
    final isPayment = txn.type == 'PAYMENT';
    final isStockAdd = txn.type == 'STOCK_ADD';

    Color avatarColor;
    Color amountColor;
    IconData avatarIcon;
    String amountPrefix;

    if (isPayment) {
      avatarColor = KColors.bluePale;
      amountColor = KColors.green;
      avatarIcon = Icons.arrow_downward;
      amountPrefix = '+';
    } else if (isStockAdd) {
      avatarColor = KColors.greenPale;
      amountColor = KColors.inkSoft;
      avatarIcon = Icons.inventory;
      amountPrefix = '';
    } else if (isCash) {
      avatarColor = KColors.greenPale;
      amountColor = KColors.green;
      avatarIcon = Icons.currency_rupee;
      amountPrefix = '';
    } else {
      avatarColor = KColors.saffronPale;
      amountColor = KColors.saffron;
      avatarIcon = Icons.edit_note;
      amountPrefix = '';
    }

    String title;
    if (isPayment || txn.customerId != null) {
      title = txn.customerName ?? 'Customer';
    } else {
      title = 'Cash Sale';
    }

    String subtitle;
    if (isStockAdd) {
      subtitle = txn.note ?? 'Stock add kiya';
    } else if (txn.items.isNotEmpty) {
      subtitle = txn.items.map((i) => '${i.name}×${i.qty}').join(', ');
      if (subtitle.length > 40) subtitle = '${subtitle.substring(0, 40)}...';
    } else {
      subtitle = txn.note ?? '';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(avatarIcon, color: amountColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 12,
                      color: KColors.inkSoft,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isStockAdd
                      ? 'Stock'
                      : '$amountPrefix${KCurrency.format(txn.totalAmountPaisa)}',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
                Text(
                  KDate.formatTime(txn.timestamp),
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 11,
                    color: KColors.inkGhost,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: KColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.type == 'PAYMENT'
                      ? 'Payment Mili'
                      : txn.type == 'STOCK_ADD'
                          ? 'Stock Add'
                          : 'Bill Details',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  KDate.formatDateTime(txn.timestamp),
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 13,
                    color: KColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 16),
                if (txn.customerName != null)
                  _DetailRow('Customer', txn.customerName!),
                if (txn.type == 'SALE') ...[
                  const SizedBox(height: 8),
                  ...txn.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} × ${item.qty}',
                              style: const TextStyle(fontFamily: 'Baloo2'),
                            ),
                          ),
                          Text(
                            KCurrency.format(item.totalPaisa),
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kul Raqam',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      KCurrency.format(txn.totalAmountPaisa),
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: KColors.saffron,
                      ),
                    ),
                  ],
                ),
                if (txn.paymentMode == 'UDHAAR')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: KColors.saffronPale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '📝 Udhaar diya gaya',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: KColors.saffron,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
