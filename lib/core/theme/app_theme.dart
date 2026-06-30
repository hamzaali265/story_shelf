import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF0F111A);
  static const Color darkSurface = Color(0xFF181C28);
  static const Color darkCard = Color(0xFF202636);
  static const Color primaryAccent = Color(0xFF6C5CE7);
  static const Color secondaryAccent = Color(0xFFA29BFE);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData darkTheme(Color? dynamicAccent) {
    final accent = dynamicAccent ?? primaryAccent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: secondaryAccent,
        surface: darkSurface,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: Brightness.light,
      ),
    );
  }
}
