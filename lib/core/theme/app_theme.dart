import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum AppThemeMode {
  dark,
  amoled,
  light,
}

class AppTheme {
  AppTheme._();

  static ThemeData getTheme([AppThemeMode? mode]) => darkTheme;

  static ThemeData get darkTheme {
    const scaffoldBg = AppColors.darkBackground; // #0B1622
    const surfaceColor = AppColors.darkSurface;  // #151F2E
    const cardColor = AppColors.darkSurface;     // #151F2E
    final borderColor = Colors.white.withValues(alpha: 0.06);
    const textPrimary = AppColors.darkTextPrimary;     // #EDF1F5
    const textSecondary = AppColors.darkTextSecondary; // #9FADBD

    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.overpassTextTheme(baseTextTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: AppColors.brandBlue,
      canvasColor: surfaceColor,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.brandBlue,
        onPrimary: Colors.white,
        secondary: AppColors.brandDarkBlue,
        onSecondary: Colors.white,
        error: AppColors.statusDropped,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          fontFamily: GoogleFonts.overpass().fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceInput,
        hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        labelStyle: textTheme.labelSmall?.copyWith(color: textSecondary, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: scaffoldBg,
        selectedItemColor: AppColors.brandBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
