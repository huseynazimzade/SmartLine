import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF28A745);
  static const Color primaryDark = Color(0xFF1E7E34);
  static const Color primaryLight = Color(0x1A28A745); // ~10%
  static const Color accent = Color(0xFF10B981);
  static const Color background = Colors.white; // Strictly white background as requested
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardSubtle = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSecondary = Color(0xFF334155);

  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);
  static const Color truckBlue = Color(0xFF2563EB);
  static const Color airGreen = Color(0xFF10B981);
  static const Color fabricPurple = Color(0xFF8B5CF6);
  static const Color depotSlate = Color(0xFF334155);
  static const Color humidityBlue = Color(0xFF3B82F6);
  static const Color borderLight = Color(0x1F9E9E9E);

  static Color hex(String hexCode) {
    String cleanHex = hexCode.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    return Color(int.parse(cleanHex, radix: 16));
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
    );
  }
}
