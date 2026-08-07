import 'package:flutter/material.dart';

class AppTheme {
  // Cool professional palette
  static const Color primaryColor = Color(0xFF1565C0);    // deep blue
  static const Color secondaryColor = Color(0xFFFF5252);  // red – unchanged
  static const Color gainColor = Color(0xFF00C853);       // green – unchanged
  static const Color lossColor = Color(0xFFFF1744);       // red – unchanged

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
      scaffoldBackgroundColor: const Color(0xFF0D1B2A),   // deep navy background
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1B2838),                  // dark card surfaces
      ),
    );
  }

  // Backward‑compatible getters (if any existing code still calls these)
  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();
}
