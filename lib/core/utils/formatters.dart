import 'package:intl/intl.dart';

class KCurrency {
  static String format(int paisa) {
    final rupees = paisa / 100;
    if (rupees == rupees.truncate()) {
      return '₹${rupees.toInt()}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

  static String formatRupees(double rupees) {
    if (rupees == rupees.truncate()) {
      return '₹${rupees.toInt()}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

  static int rupeesToPaisa(double rupees) => (rupees * 100).round();
  static int parseRupees(String text) {
    final cleaned = text.replaceAll('₹', '').trim();
    final val = double.tryParse(cleaned) ?? 0;
    return rupeesToPaisa(val);
  }
}

class KDate {
  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM, h:mm a').format(dt);
  }

  static String relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Abhi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
    if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
    if (diff.inDays == 1) return 'Kal';
    if (diff.inDays < 7) return '${diff.inDays} din pehle';
    return formatDate(dt);
  }

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static DateTime get todayStart =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static DateTime get todayEnd =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
}
