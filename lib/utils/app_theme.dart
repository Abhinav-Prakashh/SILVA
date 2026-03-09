// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary     = Color(0xFFE8A44A);
  static const Color primaryDark = Color(0xFFD4872A);
  static const Color primaryLight= Color(0xFFF5C678);
  static const Color background  = Color(0xFFFDF6EE);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFFFF3E0);
  static const Color textPrimary = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF8B6F5E);
  static const Color textLight   = Color(0xFFBBA090);
  static const Color danger      = Color(0xFFE53935);
  static const Color warning     = Color(0xFFFF8F00);
  static const Color success     = Color(0xFF43A047);
  static const Color info        = Color(0xFF1E88E5);
  static const Color fenceColor  = Color(0xFF5C6BC0);
  static const Color fenceFill   = Color(0x225C6BC0);
  static const Color fenceBreach = Color(0xFFE53935);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.cardBg,
      primary: AppColors.primary,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleLarge:   GoogleFonts.dmSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium:  GoogleFonts.dmSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge:    GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15),
      bodyMedium:   GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.playfairDisplay(
        color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const IconThemeData(color: AppColors.primary);
        return const IconThemeData(color: AppColors.textLight);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.textLight.withOpacity(0.15)),
      ),
    ),
  );
}
