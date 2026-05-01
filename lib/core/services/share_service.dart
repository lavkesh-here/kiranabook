import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class ShareService {
  static String generateBillText(TransactionModel txn, String shopName) {
    final buf = StringBuffer();
    buf.writeln('🧾 *$shopName*');
    buf.writeln('📅 ${KDate.formatDateTime(txn.timestamp)}');
    buf.writeln('─────────────────────');

    for (final item in txn.items) {
      final total = KCurrency.format(item.totalPaisa);
      buf.writeln('${item.name} × ${item.qty} = $total');
    }

    buf.writeln('─────────────────────');

    final mode = txn.paymentMode == 'CASH' ? '💵 Cash' : '📝 Udhaar';
    buf.writeln('*Kul: ${KCurrency.format(txn.totalAmountPaisa)}* ($mode)');
    buf.writeln('─────────────────────');
    buf.writeln('🙏 Dhanyavaad!');

    return buf.toString();
  }

  static Future<void> shareViaWhatsApp(String text, {String? phone}) async {
    if (phone != null && phone.isNotEmpty) {
      // Clean phone number
      final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final encoded = Uri.encodeComponent(text);
      final url = 'https://wa.me/$cleaned?text=$encoded';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fallback: generic share sheet
    await shareText(text);
  }

  static Future<void> shareText(String text) async {
    await Share.share(text, subject: 'Bill');
  }

  static Future<void> openWhatsApp(String phone, String message) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/91$cleaned?text=$encoded';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
