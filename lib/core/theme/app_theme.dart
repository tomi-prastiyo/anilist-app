import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AppThemeMode {
  dark,
  amoled,
  light,
}

class AppTheme {
  AppTheme._();

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.amoled:
        return _buildTheme(
          brightness: Brightness.dark,
          scaffoldBg: AppColors.amoledBackground,
          surfaceColor: AppColors.amoledSurface,
          cardColor: AppColors.amoledCard,
          borderColor: AppColors.amoledBorder,
          textPrimary: AppColors.darkTextPrimary,
          textSecondary: AppColors.darkTextSecondary,
        );
      case AppThemeMode.light:
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBg: AppColors.lightBackground,
          surfaceColor: AppColors.lightSurface,
          cardColor: AppColors.lightCard,
          borderColor: AppColors.lightBorder,
          textPrimary: AppColors.lightTextPrimary,
          textSecondary: AppColors.lightTextSecondary,
        );
      case AppThemeMode.dark:
        return _buildTheme(
          brightness: Brightness.dark,
          scaffoldBg: AppColors.darkBackground,
          surfaceColor: AppColors.darkSurface,
          cardColor: AppColors.darkCard,
          borderColor: AppColors.darkBorder,
          textPrimary: AppColors.darkTextPrimary,
          textSecondary: AppColors.darkTextSecondary,
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: AppColors.brandBlue,
      canvasColor: surfaceColor,
      colorScheme: ColorScheme(
        brightness: brightness,
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
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadius12,
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius8),
        labelStyle: textTheme.labelSmall?.copyWith(color: textSecondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: AppColors.brandBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
