import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF090B10);
  static const Color surface = Color(0xFF121722);
  static const Color surfaceLight = Color(0xFF1A2233);
  static const Color primary = Color(0xFF7C5CFF);
  static const Color secondary = Color(0xFF00D4FF);
  static const Color success = Color(0xFF31D0AA);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFFAAB4C3);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}