import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _settingsBox = 'app_settings';

class AppSettings {
  final bool vendorManagementEnabled;
  final bool customerManagementEnabled;
  final bool stockManagementEnabled;
  final bool onlinePaymentEnabled;
  final bool remindersEnabled;
  final bool weeklyReportsEnabled;

  const AppSettings({
    this.vendorManagementEnabled = true,
    this.customerManagementEnabled = true,
    this.stockManagementEnabled = true,
    this.onlinePaymentEnabled = true,
    this.remindersEnabled = true,
    this.weeklyReportsEnabled = true,
  });

  AppSettings copyWith({
    bool? vendorManagementEnabled,
    bool? customerManagementEnabled,
    bool? stockManagementEnabled,
    bool? onlinePaymentEnabled,
    bool? remindersEnabled,
    bool? weeklyReportsEnabled,
  }) {
    return AppSettings(
      vendorManagementEnabled:
          vendorManagementEnabled ?? this.vendorManagementEnabled,
      customerManagementEnabled:
          customerManagementEnabled ?? this.customerManagementEnabled,
      stockManagementEnabled:
          stockManagementEnabled ?? this.stockManagementEnabled,
      onlinePaymentEnabled: onlinePaymentEnabled ?? this.onlinePaymentEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      weeklyReportsEnabled: weeklyReportsEnabled ?? this.weeklyReportsEnabled,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  void _load() {
    final box = Hive.box(_settingsBox);
    state = AppSettings(
      vendorManagementEnabled: box.get('vendor', defaultValue: true),
      customerManagementEnabled: box.get('customer', defaultValue: true),
      stockManagementEnabled: box.get('stock', defaultValue: true),
      onlinePaymentEnabled: box.get('online_payment', defaultValue: true),
      remindersEnabled: box.get('reminders', defaultValue: true),
      weeklyReportsEnabled: box.get('weekly_reports', defaultValue: true),
    );
  }

  Future<void> toggle(String key, bool value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
    _load();
  }

  Future<void> setVendor(bool v) => toggle('vendor', v);
  Future<void> setCustomer(bool v) => toggle('customer', v);
  Future<void> setStock(bool v) => toggle('stock', v);
  Future<void> setOnlinePayment(bool v) => toggle('online_payment', v);
  Future<void> setReminders(bool v) => toggle('reminders', v);
  Future<void> setWeeklyReports(bool v) => toggle('weekly_reports', v);
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
