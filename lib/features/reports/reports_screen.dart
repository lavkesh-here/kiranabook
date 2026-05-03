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
