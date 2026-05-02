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

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _screens = const [
    SummaryScreen(),
    BillingScreen(),
    UdhaarScreen(),
    InventoryScreen(),
    VendorScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (_currentIndex != 0) {
          // Back goes to home first
          setState(() => _currentIndex = 0);
          return;
        }
        // Double back to exit
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
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = i);
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ghar',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Bill',
            ),
            if (settings.customerManagementEnabled)
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Udhaar',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Saman',
            ),
            if (settings.vendorManagementEnabled)
              const BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined),
                activeIcon: Icon(Icons.store),
                label: 'Vendor',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 1
            ? null
            : _currentIndex == 3
                ? null // Hide on inventory screen
                : FloatingActionButton.extended(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _currentIndex = 1);
                    },
                    backgroundColor: KColors.saffron,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('Naya Bill',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
      ),
    );
  }
}
