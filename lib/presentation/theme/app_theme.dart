import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _background = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A2E);
  static const Color _primary = Color(0xFFD4AF6A); // pale gold

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: _background,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      surface: _surface,
      onPrimary: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w300,
        letterSpacing: 1.5,
      ),
      titleMedium: TextStyle(
        color: _primary,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white54),
    ),
    cardTheme: const CardThemeData(
      color: _surface,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white12,
      thickness: 0.5,
    ),
  );
}
