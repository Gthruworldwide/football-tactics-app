import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgObsidian = Color(0xFF0A0E14);
  static const Color surfaceCard = Color(0xFF121822);
  static const Color surfaceElevated = Color(0xFF1A2230);
  static const Color borderSubtle = Color(0xFF1F2937);
  static const Color accentEmerald = Color(0xFF00E676);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static ThemeData get tacticalDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgObsidian,
      colorScheme: const ColorScheme.dark(
        primary: accentEmerald,
        secondary: accentCyan,
        surface: surfaceCard,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgObsidian,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  static Color getRatingColor(double? rating) {
    if (rating == null) return textSecondary;
    if (rating >= 7.5) return accentEmerald;
    if (rating >= 6.8) return accentCyan;
    if (rating >= 6.0) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }
}