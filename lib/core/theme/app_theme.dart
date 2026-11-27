import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/yuyuyu_assets.dart';
import 'app_typography.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  yuyuyu,
}

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = _buildLightTheme();
  static final ThemeData darkTheme = _buildDarkTheme();
  static final Map<YuYuYuHeroine, ThemeData> _yuyuyuCache = {};

  static ThemeData getTheme([AppThemeMode? mode, YuYuYuHeroine? heroine]) {
    if (mode == AppThemeMode.light) return lightTheme;
    if (mode == AppThemeMode.yuyuyu) return yuyuyuTheme(heroine);
    return darkTheme;
  }

  static ThemeData _buildLightTheme() {
    const scaffoldBg = AppColors.lightBackground; // #EDF1F5
    const surfaceColor = AppColors.lightSurface;  // #FFFFFF
    const cardColor = AppColors.lightCard;        // #FFFFFF
    const borderColor = AppColors.lightBorder;    // #E2E8F0
    const textPrimary = AppColors.lightTextPrimary;     // #263238
    const textSecondary = AppColors.lightTextSecondary; // #516170

    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = GoogleFonts.overpassTextTheme(baseTextTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
      fontFamilyFallback: AppTypography.fallbackFonts,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: const [AppThemePalette.light],
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: AppColors.brandBlue,
      canvasColor: surfaceColor,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.brandBlue,
        onPrimary: Colors.white,
        secondary: AppColors.brandNavy,
        onSecondary: Colors.white,
        error: AppColors.statusDropped,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
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
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: textTheme.labelSmall?.copyWith(color: textSecondary, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: AppColors.brandBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
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
      fontFamilyFallback: AppTypography.fallbackFonts,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const [AppThemePalette.dark],
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
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  /// Dedicated *Yuuki Yuuna wa Yuusha de Aru* (Mankai Twilight) theme.
  static ThemeData yuyuyuTheme([YuYuYuHeroine? heroine]) {
    final activeHeroine = heroine ?? YuYuYuAssets.heroines.first;
    return _yuyuyuCache.putIfAbsent(
      activeHeroine,
      () => _buildYuYuYuTheme(activeHeroine),
    );
  }

  static ThemeData _buildYuYuYuTheme(YuYuYuHeroine activeHeroine) {
    final palette = AppThemePalette.yuyuyu(activeHeroine.accentColor);
    final accent = palette.accent;

    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.overpassTextTheme(baseTextTheme).apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
      fontFamilyFallback: AppTypography.fallbackFonts,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      primaryColor: accent,
      canvasColor: palette.surface,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: accent,
        onPrimary: Colors.white,
        secondary: YuYuYuAssets.shinjuGold,
        onSecondary: Colors.black,
        error: AppColors.statusDropped,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          fontFamily: GoogleFonts.overpass().fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputSurface,
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: textTheme.labelSmall?.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.background,
        selectedItemColor: accent,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}
