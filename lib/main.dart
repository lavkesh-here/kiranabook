import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/db/hive_db.dart';
import 'core/theme/app_theme.dart';
import 'core/i18n/app_strings.dart';
import 'features/billing/billing_screen.dart';
import 'features/udhaar/udhaar_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/summary/summary_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/vendor/vendor_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/onboarding/language_screen.dart';
import 'core/services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: KColors.saffron,
    statusBarIconBrightness: Brightness.light,
  ));
  await HiveDB.init();
  runApp(const ProviderScope(child: KiranaBookApp()));
}

class KiranaBookApp extends ConsumerWidget {
  const KiranaBookApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    S.setLang(lang);
    return MaterialApp(
      title: 'KiranaBook',
      debugShowCheckedModeBanner: false,
      theme: KTheme.theme,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langNotifier = ref.read(languageProvider.notifier);
    if (!langNotifier.isSetup) {
      return LanguageScreen(onDone: () {
        // Rebuild to show home
        ref.invalidate(languageProvider);
      });
    }
    return const HomeShell();
  }
}

enum AppScreen { home, billing, udhaar, inventory, vendor, reports, settings }

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  AppScreen _current = AppScreen.home;
  DateTime? _lastBackPressed;

  final Map<AppScreen, Widget> _screens = const {
    AppScreen.home: SummaryScreen(),
    AppScreen.billing: BillingScreen(),
    AppScreen.udhaar: UdhaarScreen(),
    AppScreen.inventory: InventoryScreen(),
    AppScreen.vendor: VendorScreen(),
    AppScreen.reports: ReportsScreen(),
    AppScreen.settings: SettingsScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final lang = ref.watch(languageProvider);
    S.setLang(lang);

    final List<_NavItem> navItems = [
      _NavItem(AppScreen.home, Icons.home_outlined, Icons.home, S.navHome),
      _NavItem(AppScreen.billing, Icons.receipt_long_outlined, Icons.receipt_long, S.navBill),
      if (settings.customerManagementEnabled)
        _NavItem(AppScreen.udhaar, Icons.people_outline, Icons.people, S.navUdhaar),
      _NavItem(AppScreen.inventory, Icons.inventory_2_outlined, Icons.inventory_2, S.navSaman),
      if (settings.vendorManagementEnabled)
        _NavItem(AppScreen.vendor, Icons.store_outlined, Icons.store, S.navVendor),
      _NavItem(AppScreen.reports, Icons.bar_chart_outlined, Icons.bar_chart, S.navReports),
      _NavItem(AppScreen.settings, Icons.settings_outlined, Icons.settings, S.navSettings),
    ];

    // Only redirect feature-gated screens, never settings/home/billing/inventory
    final gatedScreens = [AppScreen.vendor, AppScreen.udhaar];
    final visibleScreens = navItems.map((n) => n.screen).toList();
    if (gatedScreens.contains(_current) && !visibleScreens.contains(_current)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _current = AppScreen.home);
      });
    }

    final currentNavIndex = navItems
        .indexWhere((n) => n.screen == _current)
        .clamp(0, navItems.length - 1);

    final allScreenOrder = [
      AppScreen.home, AppScreen.billing, AppScreen.udhaar,
      AppScreen.inventory, AppScreen.vendor, AppScreen.reports, AppScreen.settings,
    ];
    final currentStackIndex = allScreenOrder.indexOf(_current);
    final showFab = _current == AppScreen.home;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (_current != AppScreen.home) {
          setState(() => _current = AppScreen.home);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'en'
                    ? 'Press back again to exit'
                    : 'Bahar jaane ke liye ek baar aur dabaiye',
                style: const TextStyle(fontFamily: 'Baloo2'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentStackIndex,
          children: allScreenOrder
              .map((s) => _screens[s] ?? const SizedBox())
              .toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentNavIndex,
          onTap: (i) {
            HapticFeedback.selectionClick();
            setState(() => _current = navItems[i].screen);
          },
          items: navItems.map((n) => BottomNavigationBarItem(
            icon: Icon(n.icon),
            activeIcon: Icon(n.activeIcon),
            label: n.label,
          )).toList(),
        ),
        floatingActionButton: showFab
            ? FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _current = AppScreen.billing);
                },
                backgroundColor: KColors.saffron,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(S.nayaBill,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )
            : null,
      ),
    );
  }
}

class _NavItem {
  final AppScreen screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.screen, this.icon, this.activeIcon, this.label);
}
