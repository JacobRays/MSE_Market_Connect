import 'package:flutter/material.dart';

class AppTheme {
  // Brighter accent palette
  static const Color primaryColor = Color(0xFFFFB300);   // vivid amber
  static const Color secondaryColor = Color(0xFFFF5252); // red (sell target)
  static const Color gainColor = Color(0xFF00C853);      // bright green
  static const Color lossColor = Color(0xFFFF1744);      // bright red

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
    );
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.black87,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
    );
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Backward‑compatible getters
  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();
}
