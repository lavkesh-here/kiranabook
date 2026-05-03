import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ── Language provider ──────────────────────────────────────────────────────
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('hi') {
    final box = Hive.box('app_settings');
    state = box.get('language', defaultValue: 'hi');
  }

  Future<void> setLanguage(String lang) async {
    final box = Hive.box('app_settings');
    await box.put('language', lang);
    state = lang;
  }

  bool get isSetup {
    final box = Hive.box('app_settings');
    return box.get('language_setup_done', defaultValue: false);
  }

  Future<void> markSetupDone() async {
    final box = Hive.box('app_settings');
    await box.put('language_setup_done', true);
  }
}

// ── Strings class ──────────────────────────────────────────────────────────
class S {
  static String _lang = 'hi';

  static void setLang(String lang) => _lang = lang;

  static String get(String key) {
    final map = _lang == 'en' ? _en : _hi;
    return map[key] ?? _hi[key] ?? key;
  }

  // ── Navigation ──
  static String get navHome => get('navHome');
  static String get navBill => get('navBill');
  static String get navUdhaar => get('navUdhaar');
  static String get navSaman => get('navSaman');
  static String get navVendor => get('navVendor');
  static String get navReports => get('navReports');
  static String get navSettings => get('navSettings');

  // ── Common ──
  static String get saveKaro => get('saveKaro');
  static String get cancel => get('cancel');
  static String get search => get('search');
  static String get naam => get('naam');
  static String get phone => get('phone');
  static String get optional => get('optional');
  static String get required => get('required');
  static String get unit => get('unit');

  // ── Billing ──
  static String get nayaBill => get('nayaBill');
  static String get customerChunno => get('customerChunno');
  static String get cashSale => get('cashSale');
  static String get cash => get('cash');
  static String get udhaar => get('udhaar');
  static String get online => get('online');
  static String get kul => get('kul');
  static String get items => get('items');
  static String get nayaItem => get('nayaItem');
  static String get itemDhundho => get('itemDhundho');
  static String get sabHatao => get('sabHatao');
  static String get mrp => get('mrp');
  static String get bikriDaam => get('bikriDaam');
  static String get shuruStock => get('shuruStock');
  static String get stockKhatam => get('stockKhatam');
  static String get stock => get('stock');

  // ── Udhaar ──
  static String get udhaarKhata => get('udhaarKhata');
  static String get baaki => get('baaki');
  static String get sabLog => get('sabLog');
  static String get paisaMila => get('paisaMila');
  static String get nayaCustomer => get('nayaCustomer');
  static String get customerDhundho => get('customerDhundho');
  static String get kisiBaakiNahi => get('kisiBaakiNahi');
  static String get koiCustomerNahi => get('koiCustomerNahi');

  // ── Inventory ──
  static String get samanHisaab => get('samanHisaab');
  static String get itemDhundhoSearch => get('itemDhundhoSearch');
  static String get stockAdd => get('stockAdd');
  static String get abhiHai => get('abhiHai');
  static String get kitnaAdd => get('kitnaAdd');
  static String get addKaro => get('addKaro');

  // ── Vendor ──
  static String get vendorLedger => get('vendorLedger');
  static String get vendorDhundho => get('vendorDhundho');
  static String get nayaVendor => get('nayaVendor');
  static String get orderKiya => get('orderKiya');
  static String get paymentDi => get('paymentDi');
  static String get denaHai => get('denaHai');

  // ── Settings ──
  static String get settings => get('settings');
  static String get dukaanJaankari => get('dukaanJaankari');
  static String get dukaanNaam => get('dukaanNaam');
  static String get maalikNaam => get('maalikNaam');
  static String get language => get('language');
  static String get restartMessage => get('restartMessage');

  // ── Validation errors ──
  static String get naamZaroori => get('naamZaroori');
  static String get daamZaroori => get('daamZaroori');
  static String get amountZaroori => get('amountZaroori');
  static String get validAmountZaroori => get('validAmountZaroori');
  static String get stockValidZaroori => get('stockValidZaroori');

  // ── Onboarding ──
  static String get chooseLang => get('chooseLang');
  static String get chooseLangSub => get('chooseLangSub');
  static String get langHinglish => get('langHinglish');
  static String get langEnglish => get('langEnglish');
  static String get startKaro => get('startKaro');

  // ══════════════════════════════════════════════════════════════
  // HINGLISH strings (default)
  // ══════════════════════════════════════════════════════════════
  static const Map<String, String> _hi = {
    // Navigation
    'navHome': 'Ghar',
    'navBill': 'Bill',
    'navUdhaar': 'Udhaar',
    'navSaman': 'Saman',
    'navVendor': 'Vendor',
    'navReports': 'Reports',
    'navSettings': 'Settings',

    // Common
    'saveKaro': 'Save Karo',
    'cancel': 'Cancel',
    'search': 'Dhundho...',
    'naam': 'Naam',
    'phone': 'Phone',
    'optional': 'optional',
    'required': 'zaroori',
    'unit': 'Unit',

    // Billing
    'nayaBill': 'Naya Bill',
    'customerChunno': 'Customer chunno (optional)',
    'cashSale': 'Cash Sale (koi customer nahi)',
    'cash': 'Cash',
    'udhaar': 'Udhaar',
    'online': 'Online',
    'kul': 'Kul',
    'items': 'items',
    'nayaItem': 'Naya\nItem',
    'itemDhundho': '🔍 Item dhundho... (Hindi ya English)',
    'sabHatao': 'Sab Hatao',
    'mrp': 'MRP (₹)',
    'bikriDaam': 'Bikri Daam (₹) *',
    'shuruStock': 'Shuru stock',
    'stockKhatam': 'Stock khatam',
    'stock': 'Stock',

    // Udhaar
    'udhaarKhata': 'Udhaar Khata 📒',
    'baaki': 'Baaki',
    'sabLog': 'Sab Log',
    'paisaMila': '💰 Paisa Mila',
    'nayaCustomer': 'Naya Customer Add Karo',
    'customerDhundho': '🔍 Customer ka naam...',
    'kisiBaakiNahi': 'Kisi ka udhaar nahi hai 🎉',
    'koiCustomerNahi': 'Koi customer nahi',

    // Inventory
    'samanHisaab': 'Saman ka Hisaab 📦',
    'itemDhundhoSearch': '🔍 Item dhundho...',
    'stockAdd': 'Stock Add Karo',
    'abhiHai': 'Abhi hai',
    'kitnaAdd': 'Kitna add karna hai?',
    'addKaro': 'Add Karo',

    // Vendor
    'vendorLedger': 'Vendor Ledger 🏪',
    'vendorDhundho': '🔍 Vendor dhundho...',
    'nayaVendor': 'Naya Vendor',
    'orderKiya': 'Order Kiya',
    'paymentDi': 'Payment Di',
    'denaHai': 'Dena hai',

    // Settings
    'settings': 'Settings ⚙️',
    'dukaanJaankari': 'Dukaan ki Jaankari',
    'dukaanNaam': 'Dukaan ka Naam',
    'maalikNaam': 'Maalik ka Naam',
    'language': 'Bhasha (Language)',
    'restartMessage': '🔄 App band karke dobara kholo — nayi bhasha lagegi',

    // Validation
    'naamZaroori': 'Naam daalna zaroori hai!',
    'daamZaroori': 'Bikri daam daalna zaroori hai!',
    'amountZaroori': 'Raqam daalna zaroori hai!',
    'validAmountZaroori': 'Sahi raqam daalo!',
    'stockValidZaroori': 'Stock ki matra sahi daalo (1 ya zyada)!',

    // Onboarding
    'chooseLang': 'Apni Bhasha Chuniye',
    'chooseLangSub': 'Choose your language',
    'langHinglish': 'Hinglish\n(Hindi + English)',
    'langEnglish': 'English',
    'startKaro': 'Shuru Karo →',
  };

  // ══════════════════════════════════════════════════════════════
  // ENGLISH strings
  // ══════════════════════════════════════════════════════════════
  static const Map<String, String> _en = {
    // Navigation
    'navHome': 'Home',
    'navBill': 'Bill',
    'navUdhaar': 'Credit',
    'navSaman': 'Stock',
    'navVendor': 'Vendor',
    'navReports': 'Reports',
    'navSettings': 'Settings',

    // Common
    'saveKaro': 'Save',
    'cancel': 'Cancel',
    'search': 'Search...',
    'naam': 'Name',
    'phone': 'Phone',
    'optional': 'optional',
    'required': 'required',
    'unit': 'Unit',

    // Billing
    'nayaBill': 'New Bill',
    'customerChunno': 'Select customer (optional)',
    'cashSale': 'Cash Sale (no customer)',
    'cash': 'Cash',
    'udhaar': 'Credit',
    'online': 'Online',
    'kul': 'Total',
    'items': 'items',
    'nayaItem': 'New\nItem',
    'itemDhundho': '🔍 Search items...',
    'sabHatao': 'Clear All',
    'mrp': 'MRP (₹)',
    'bikriDaam': 'Sale Price (₹) *',
    'shuruStock': 'Opening stock',
    'stockKhatam': 'Out of stock',
    'stock': 'Stock',

    // Udhaar
    'udhaarKhata': 'Credit Book 📒',
    'baaki': 'Due',
    'sabLog': 'All',
    'paisaMila': '💰 Record Payment',
    'nayaCustomer': 'Add New Customer',
    'customerDhundho': '🔍 Search by name...',
    'kisiBaakiNahi': 'No pending dues 🎉',
    'koiCustomerNahi': 'No customers yet',

    // Inventory
    'samanHisaab': 'Stock Management 📦',
    'itemDhundhoSearch': '🔍 Search items...',
    'stockAdd': 'Add Stock',
    'abhiHai': 'Current stock',
    'kitnaAdd': 'How much to add?',
    'addKaro': 'Add Stock',

    // Vendor
    'vendorLedger': 'Vendor Ledger 🏪',
    'vendorDhundho': '🔍 Search vendors...',
    'nayaVendor': 'New Vendor',
    'orderKiya': 'New Order',
    'paymentDi': 'Payment Made',
    'denaHai': 'Amount due',

    // Settings
    'settings': 'Settings ⚙️',
    'dukaanJaankari': 'Shop Information',
    'dukaanNaam': 'Shop Name',
    'maalikNaam': 'Owner Name',
    'language': 'Language',
    'restartMessage': '🔄 Please restart the app to apply new language',

    // Validation
    'naamZaroori': 'Name is required!',
    'daamZaroori': 'Sale price is required!',
    'amountZaroori': 'Amount is required!',
    'validAmountZaroori': 'Please enter a valid amount!',
    'stockValidZaroori': 'Stock quantity must be 1 or more!',

    // Onboarding
    'chooseLang': 'Choose Your Language',
    'chooseLangSub': 'Apni bhasha chuniye',
    'langHinglish': 'Hinglish\n(Hindi + English)',
    'langEnglish': 'English',
    'startKaro': 'Get Started →',
  };
}
