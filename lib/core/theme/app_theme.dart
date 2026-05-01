import 'package:flutter/material.dart';

class KColors {
  // Primary
  static const saffron = Color(0xFFFF6B00);
  static const saffronLight = Color(0xFFFF8C35);
  static const saffronPale = Color(0xFFFFF3E8);

  // Success
  static const green = Color(0xFF00A651);
  static const greenDark = Color(0xFF007A3D);
  static const greenPale = Color(0xFFE8F7EF);

  // Danger
  static const red = Color(0xFFE53935);
  static const redPale = Color(0xFFFFEBEE);

  // Warning
  static const yellow = Color(0xFFFFB800);
  static const yellowPale = Color(0xFFFFF8E1);

  // Info
  static const blue = Color(0xFF1565C0);
  static const bluePale = Color(0xFFE3F2FD);

  // Neutral
  static const ink = Color(0xFF1A1A2E);
  static const inkMid = Color(0xFF3D3D5C);
  static const inkSoft = Color(0xFF6B6B8A);
  static const inkGhost = Color(0xFFB0B0CC);
  static const surface = Color(0xFFFAFAF8);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8E8F0);
}

class KTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: KColors.saffron,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: KColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: KColors.saffron,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: KColors.card,
          selectedItemColor: KColors.saffron,
          unselectedItemColor: KColors.inkGhost,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          elevation: 12,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KColors.saffron,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800),
          displayMedium: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontFamily: 'Baloo2'),
          bodyMedium: TextStyle(fontFamily: 'Baloo2'),
          labelLarge: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: KColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: KColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: KColors.saffron, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardTheme(
          color: KColors.card,
          elevation: 2,
          shadowColor: KColors.ink.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: KColors.border),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: KColors.border,
          thickness: 1,
          space: 0,
        ),
      );
}
