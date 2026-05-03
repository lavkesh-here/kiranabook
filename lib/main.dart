import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/db/hive_db.dart';
import 'core/theme/app_theme.dart';
import 'features/billing/billing_screen.dart';
import 'features/udhaar/udhaar_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/summary/summary_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/vendor/vendor_screen.dart';
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

class KiranaBookApp extends StatelessWidget {
  const KiranaBookApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiranaBook',
      debugShowCheckedModeBanner: false,
      theme: KTheme.theme,
      home: const HomeShell(),
    );
  }
}

// Use enum to track screen — not index — fixes Issue 1
enum AppScreen { home, billing, udhaar, inventory, vendor, settings }

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  AppScreen _current = AppScreen.home;
  DateTime? _lastBackPressed;

  // Always full list of screens — IndexedStack shows all, nav picks visible ones
  final Map<AppScreen, Widget> _screens = const {
    AppScreen.home: SummaryScreen(),
    AppScreen.billing: BillingScreen(),
    AppScreen.udhaar: UdhaarScreen(),
    AppScreen.inventory: InventoryScreen(),
    AppScreen.vendor: VendorScreen(),
    AppScreen.settings: SettingsScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    // Build nav items dynamically based on feature flags
    // ALWAYS include home, billing, inventory, settings
    // Conditionally include udhaar and vendor
    final List<_NavItem> navItems = [
      _NavItem(AppScreen.home, Icons.home_outlined, Icons.home, 'Ghar'),
      _NavItem(AppScreen.billing, Icons.receipt_long_outlined,
          Icons.receipt_long, 'Bill'),
      if (settings.customerManagementEnabled)
        _NavItem(
            AppScreen.udhaar, Icons.people_outline, Icons.people, 'Udhaar'),
      _NavItem(AppScreen.inventory, Icons.inventory_2_outlined,
          Icons.inventory_2, 'Saman'),
      if (settings.vendorManagementEnabled)
        _NavItem(AppScreen.vendor, Icons.store_outlined, Icons.store, 'Vendor'),
      _NavItem(AppScreen.settings, Icons.settings_outlined, Icons.settings,
          'Settings'),
    ];

    // If current screen is no longer in nav (feature disabled), go home
    final visibleScreens = navItems.map((n) => n.screen).toList();
    // Only redirect feature-gated screens (vendor/udhaar)
    // Never redirect settings/home/billing/inventory
    final gatedScreens = [AppScreen.vendor, AppScreen.udhaar];
    if (gatedScreens.contains(_current) && !visibleScreens.contains(_current)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _current = AppScreen.home);
      });
    }

    final currentNavIndex =
        navItems.indexWhere((n) => n.screen == _current).clamp(0, navItems.length - 1);

    // Screens to show in IndexedStack in fixed order
    final allScreenOrder = [
      AppScreen.home,
      AppScreen.billing,
      AppScreen.udhaar,
      AppScreen.inventory,
      AppScreen.vendor,
      AppScreen.settings,
    ];
    final currentStackIndex = allScreenOrder.indexOf(_current);

    // Hide FAB on: billing, inventory, vendor, udhaar, settings
    // Show FAB only on: home
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
            const SnackBar(
              content: Text('Bahar jaane ke liye ek baar aur dabaiye',
                  style: TextStyle(fontFamily: 'Baloo2')),
              duration: Duration(seconds: 2),
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
          items: navItems
              .map((n) => BottomNavigationBarItem(
                    icon: Icon(n.icon),
                    activeIcon: Icon(n.activeIcon),
                    label: n.label,
                  ))
              .toList(),
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
                label: const Text('Naya Bill',
                    style: TextStyle(fontWeight: FontWeight.w700)),
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
