import 'dart:math';

class IdGenerator {
  static final _random = Random();

  /// Generate offline-safe unique ID
  /// Format: storeId_timestamp_random4
  static String generate({String storeId = 'store_001'}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(9000) + 1000;
    return '${storeId}_${ts}_$rand';
  }

  static String shortId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(900) + 100;
    return '${ts}_$rand';
  }
}
